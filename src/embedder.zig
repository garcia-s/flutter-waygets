const std = @import("std");
const c = @import("c_imports.zig").c;
const WLEgl = @import("wl_egl.zig").WLEgl;
const FLView = @import("fl_view.zig").FLView;
const FLWindow = @import("fl_window.zig").FLWindow;
const PointerManager = @import("pointer_manager.zig").PointerManager;
const KeyboardManager = @import("keyboard_manager.zig").KeyboardManager;
const PointerViewInfo = @import("pointer_manager.zig").PointerViewInfo;
const InputManager = @import("input.zig").InputManager;

const get_aot_data = @import("fl_aot.zig").get_aot_data;
const create_renderer_config = @import("fl_render_config.zig").create_renderer_config;
const create_flutter_compositor = @import("fl_compositor.zig").create_flutter_compositor;
const platform_message_callback = @import("./channels/message_callback.zig").platform_message_callback;
const wl_keyboard_listener = @import("./listeners/keyboard.zig").wl_keyboard_listener;
const wl_pointer_listener = @import("./listeners/pointer.zig").wl_pointer_listener;
const task = @import("fl_task_runners.zig");

///Main embedder interface
pub const FLEmbedder = struct {
    gpa: std.heap.GeneralPurposeAllocator(.{}) =
        std.heap.GeneralPurposeAllocator(.{}){},

    ///A struct to manage everything related to egl-wayland
    egl: WLEgl = WLEgl{},

    ///Flutter engine instance
    engine: c.FlutterEngine = undefined,

    ///Manager for the pointer events
    pointer: PointerManager = PointerManager{},

    ///Manager for keyboard events
    keyboard: KeyboardManager = KeyboardManager{},

    ///View id to wayland surface pointer map,
    ///Flutter's custom task runner instance
    runner: task.FLTaskRunner = task.FLTaskRunner{},

    ///Map used to find the correct view_id from a surface pointer
    ///Used while mapping the pointer coordinates to the correct surface
    view_surface_map: std.AutoHashMap(*c.struct_wl_surface, i64) = undefined,

    ///Map used to control the FLWindow instances
    ///To resize, move, close and create windows
    windows: std.AutoHashMap(i64, FLWindow) = undefined,

    ///The ammount of current windows alive in the current flutter
    window_count: i64 = 0,

    ///libinput FD
    input: InputManager = InputManager{},

    pub fn init(self: *FLEmbedder, path: *[:0]u8) !void {
        const alloc = self.gpa.allocator();
        //Init all the wayland and EGL stuff
        try self.egl.init();
        //Create a dispatch wl_loop
        // libinput = libinput_udev_create_context(&interface, NULL, udev);
        //    libinput_udev_assign_seat(libinput, "seat0");
        //
        //    // Add libinput's file descriptor to the Wayland event loop
        //    int libinput_fd = libinput_get_fd(libinput);
        //    wl_event_loop_add_fd(loop, libinput_fd, WL_EVENT_READABLE, libinput_fd_callback, libinput);
        try self.input.init();
        _ = try std.Thread.spawn(.{}, wl_loop, .{self.egl.wl_display});
        //Mouse doesn't need to be initialized but keyboard
        //does need to create a xkb context, whatever that means
        // try self.keyboard.init();
        //
        // const pointer = c.wl_seat_get_pointer(self.egl.seat) orelse {
        //     std.debug.print("Failed to retrieve a pointer", .{});
        //     return error.ErrorRetrievingPointer;
        // };
        //
        // _ = c.wl_pointer_add_listener(
        //     pointer,
        //     &wl_pointer_listener,
        //     self,
        // );
        //
        // const keyboard = c.wl_seat_get_keyboard(self.egl.seat) orelse {
        //     std.debug.print("Failed to retrieve a pointer", .{});
        //     return error.ErrorRetrievingPointer;
        // };
        //
        // _ = c.wl_keyboard_add_listener(
        //     keyboard,
        //     &wl_keyboard_listener,
        //     self,
        // );

        //init window context
        self.windows = std.AutoHashMap(i64, FLWindow).init(alloc);
        self.view_surface_map = std.AutoHashMap(*c.struct_wl_surface, i64).init(alloc);

        const assets_path = try std.fmt.allocPrintZ(alloc, "{s}/{s}", .{
            path.*,
            "flutter_assets",
        });

        const icu_path = try std.fmt.allocPrintZ(alloc, "{s}/{s}", .{
            path.*,
            "icudtl.dat",
        });

        var argv = [_][*:0]const u8{
            "--verbose-logging".ptr,
            "--trace-key-events".ptr,
        };

        var args = c.FlutterProjectArgs{
            .struct_size = @sizeOf(c.FlutterProjectArgs),
            .assets_path = @ptrCast(assets_path.ptr),
            .log_message_callback = log_message_callback,
            .icu_data_path = @ptrCast(icu_path.ptr),
            .platform_message_callback = platform_message_callback,
            .channel_update_callback = channel_update_callback,
            .compute_platform_resolved_locale_callback = compute_platform_resolved_locale_callback,
            .command_line_argc = argv.len,
            .command_line_argv = @ptrCast(&argv),
        };

        if (c.FlutterEngineRunsAOTCompiledDartCode()) {
            const aot_path = try std.fmt.allocPrint(alloc, "{s}/{s}", .{
                path.*,
                "lib/libapp.so",
            });

            try get_aot_data(aot_path, &args);
        }

        var config = c.FlutterRendererConfig{
            .type = c.kOpenGL,
            .unnamed_0 = .{ .open_gl = create_renderer_config() },
        };

        try self.runner.init(
            alloc,
            std.Thread.getCurrentId(),
            &self.engine,
        );
        //
        var runner = task.create_fl_runner(&self.runner);
        //
        var runners = c.FlutterCustomTaskRunners{
            .struct_size = @sizeOf(c.FlutterCustomTaskRunners),
            .render_task_runner = @ptrCast(&runner),
            .platform_task_runner = @ptrCast(&runner),
        };
        //
        args.custom_task_runners = @ptrCast(&runners);
        args.compositor = @ptrCast(&create_flutter_compositor(self));

        const res = c.FlutterEngineInitialize(
            1,
            &config,
            &args,
            self,
            &self.engine,
        );

        //I need the context and surfaces before the thing
        if (res != c.kSuccess) {
            return error.FailedToRunFlutterEngine;
        }
    }

    pub fn run(self: *FLEmbedder) !void {
        _ = c.FlutterEngineRunInitialized(self.engine);

        _ = c.FlutterEngineSendKeyEvent(
            self.engine,
            &c.FlutterKeyEvent{
                .struct_size = @sizeOf(c.FlutterKeyEvent),
            },
            null,
            null,
        );

        while (true) {
            self.runner.run_next_task();
        }
    }

    fn wl_loop(wl: *c.wl_display) void {
        while (true) {
            _ = c.wl_display_dispatch(wl);
        }
    }

    pub fn add_view(self: *FLEmbedder, view: FLView) !void {
        //TODO: Might need to move this to a windows manager struct
        var window = FLWindow{};

        try window.init(&self.egl, &view);

        try self.windows.put(self.window_count, window);

        try self.view_surface_map.put(
            window.wl_surface,
            self.window_count,
        );

        var event = c.FlutterWindowMetricsEvent{
            .struct_size = @sizeOf(c.FlutterWindowMetricsEvent),
            .width = view.width,
            .height = view.height,
            .pixel_ratio = 1,
            .left = 0,
            .top = 0,
            .physical_view_inset_top = 0,
            .physical_view_inset_right = 0,
            .physical_view_inset_bottom = 0,
            .physical_view_inset_left = 0,
            .display_id = 0,
            .view_id = self.window_count,
        };

        if (self.window_count != 0)
            _ = c.FlutterEngineAddView(
                self.engine,
                &c.FlutterAddViewInfo{
                    .struct_size = @sizeOf(c.FlutterAddViewInfo),
                    .view_id = self.window_count,
                    .user_data = null,
                    .view_metrics = &event,
                    .add_view_callback = add_view_callback,
                },
            );
        const res = c.FlutterEngineSendWindowMetricsEvent(self.engine, &event);
        self.window_count += 1;

        if (res != c.kSuccess) {
            std.debug.print("Sending window metrics failed\n", .{});
        }
    }

    pub fn remove_view(_: *FLEmbedder, _: i64) !void {}
};

fn channel_update_callback(
    _: [*c]const c.FlutterChannelUpdate,
    _: ?*anyopaque,
) callconv(.C) void {
    //
}

pub fn add_view_callback(_: [*c]const c.FlutterAddViewResult) callconv(.C) void {}

pub fn compute_platform_resolved_locale_callback(
    locales: [*c][*c]const c.FlutterLocale,
    _: usize,
) callconv(.C) [*c]const c.FlutterLocale {
    std.debug.print("Running the locales thingy\n", .{});
    return locales[0];
}
pub fn log_message_callback(tag: [*c]const u8, message: [*c]const u8, _: ?*anyopaque) callconv(.C) void {
    std.debug.print("{s}: {s}", .{ tag, message });
}
