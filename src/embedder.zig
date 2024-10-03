const std = @import("std");
const c = @import("c_imports.zig").c;
const WLEgl = @import("wl_egl.zig").WLEgl;
const FLView = @import("fl_view.zig").FLView;
const FLWindow = @import("fl_window.zig").FLWindow;
const WLManager = @import("wl_manager.zig").WLManager;
const PointerManager = @import("pointer_manager.zig").PointerManager;
const PointerViewInfo = @import("pointer_manager.zig").PointerViewInfo;

const get_aot_data = @import("fl_aot.zig").get_aot_data;
const create_renderer_config = @import("fl_render_config.zig").create_renderer_config;
const create_flutter_compositor = @import("fl_compositor.zig").create_flutter_compositor;
const platform_message_callback = @import("fl_platform_message_manager.zig").platform_message_callback;
const wl_pointer_listener = @import("wl_pointer_listener.zig").wl_pointer_listener;
const task = @import("fl_task_runners.zig");

pub const FLEmbedder = struct {
    wl: WLManager = WLManager{},
    egl: WLEgl = WLEgl{},
    gpa: std.heap.GeneralPurposeAllocator(.{}) = std.heap.GeneralPurposeAllocator(.{}){},
    engine: c.FlutterEngine = undefined,

    pointer: PointerManager = PointerManager{},
    runner: task.FLTaskRunner = task.FLTaskRunner{},

    pub fn init(self: *FLEmbedder, path: *[:0]u8) !void {
        //
        //Init wayland stuff
        const alloc = self.gpa.allocator();
        try self.wl.init();

        const pointer = c.wl_seat_get_pointer(self.wl.seat) orelse {
            std.debug.print("Failed to retrieve a pointer", .{});
            return error.ErrorRetrievingPointer;
        };
        _ = c.wl_pointer_add_listener(
            pointer,
            &wl_pointer_listener,
            &self.pointer,
        );

        //Init egl stuff
        try self.egl.init(self.wl.display);
        try self.pointer.init(alloc, &self.engine);

        //init window context
        self.egl.windows = std.AutoHashMap(i64, FLWindow).init(alloc);
        _ = try std.Thread.spawn(.{}, wl_loop, .{self.wl.display});

        const assets_path = try std.fmt.allocPrintZ(alloc, "{s}/{s}", .{
            path.*,
            "flutter_assets",
        });

        const icu_path = try std.fmt.allocPrintZ(alloc, "{s}/{s}", .{
            path.*,
            "icudtl.dat",
        });

        var args = c.FlutterProjectArgs{
            .struct_size = @sizeOf(c.FlutterProjectArgs),
            .assets_path = @ptrCast(assets_path.ptr),
            .icu_data_path = @ptrCast(icu_path.ptr),
            .platform_message_callback = platform_message_callback,
            .channel_update_callback = channel_update_callback,
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
        args.compositor = @ptrCast(&create_flutter_compositor(&self.egl));

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
        var window = FLWindow{};

        try window.init(
            self.wl.compositor,
            self.wl.layer_shell,
            self.egl.display,
            self.egl.config,
            &view,
        );

        try self.egl.windows.put(
            self.egl.window_count,
            window,
        );

        try self.pointer.map.put(window.wl_surface, self.egl.window_count);

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
            .view_id = self.egl.window_count,
        };

        if (self.egl.window_count != 0)
            _ = c.FlutterEngineAddView(
                self.engine,
                &c.FlutterAddViewInfo{
                    .struct_size = @sizeOf(c.FlutterAddViewInfo),
                    .view_id = self.egl.window_count,
                    .user_data = null,
                    .view_metrics = &event,
                    .add_view_callback = add_view_callback,
                },
            );
        const res = c.FlutterEngineSendWindowMetricsEvent(self.engine, &event);
        self.egl.window_count += 1;

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
