const std = @import("std");
const c = @import("c_imports.zig").c;
const WLManager = @import("wl_manager.zig").WLManager;
const WLEgl = @import("wl_egl.zig").WLEgl;
const get_aot_data = @import("fl_aot.zig").get_aot_data;
const create_renderer_config = @import("fl_render_config.zig").create_renderer_config;
const task = @import("fl_task_runners.zig");
const create_flutter_compositor = @import("fl_compositor.zig").create_flutter_compositor;
const FLView = @import("fl_view.zig").FLView;
const FLWindow = @import("fl_window.zig").FLWindow;
const InputState = @import("input_state.zig").InputState;
const wl_pointer_listener = @import("wl_pointer_listener.zig").wl_pointer_listener;

pub const FLEmbedder = struct {
    alloc: std.mem.Allocator = undefined,
    wl: *WLManager = undefined,
    egl: *WLEgl = undefined,
    engine: c.FlutterEngine = undefined,

    input: InputState = InputState{},
    renderer: task.FLTaskRunner = task.FLTaskRunner{},
    runner: task.FLTaskRunner = task.FLTaskRunner{},

    pub fn init(
        self: *FLEmbedder,
        path: *[:0]u8,
        implicit_view: *const FLView,
    ) !void {
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        self.alloc = gpa.allocator();

        self.wl = try self.alloc.create(WLManager);

        self.egl = try self.alloc.create(WLEgl);

        //Init wayland stuff
        try self.wl.init();

        const pointer = c.wl_seat_get_pointer(self.wl.seat) orelse {
            std.debug.print("Failed to retrieve a pointer", .{});
            return error.ErrorRetrievingPointer;
        };

        _ = c.wl_pointer_add_listener(
            pointer,
            &wl_pointer_listener,
            &self.input,
        );

        _ = try std.Thread.spawn(.{}, wl_loop, .{self.wl.display});
        //Init egl stuff
        try self.egl.init(self.wl.display);
        try self.input.init();

        self.egl.windows = try self.alloc.alloc(FLWindow, 5);
        self.egl.windows[0] = FLWindow{};
        try self.egl.windows[0].init(
            self.wl.compositor,
            self.wl.layer_shell,
            self.egl.display,
            self.egl.config,
            implicit_view,
        );

        try self.input.map.put(self.egl.windows[0].wl_surface, &self.engine);

        const assets_path = try std.fmt.allocPrintZ(self.alloc, "{s}/{s}", .{
            path.*,
            "flutter_assets",
        });

        const icu_path = try std.fmt.allocPrintZ(self.alloc, "{s}/{s}", .{
            path.*,
            "icudtl.dat",
        });

        var args = c.FlutterProjectArgs{
            .struct_size = @sizeOf(c.FlutterProjectArgs),
            .assets_path = @ptrCast(assets_path.ptr),
            .icu_data_path = @ptrCast(icu_path.ptr),
            .platform_message_callback = platform_message_callback,
            // .channel_update_callback = channel_update_callback,
        };

        if (c.FlutterEngineRunsAOTCompiledDartCode()) {
            const aot_path = try std.fmt.allocPrint(self.alloc, "{s}/{s}", .{
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
            self.alloc,
            std.Thread.getCurrentId(),
            &self.engine,
        );

        try self.renderer.init(
            self.alloc,
            std.Thread.getCurrentId(),
            &self.engine,
        );
        // var runner = task.create_fl_runner(&self.runner);
        //
        // var runners = c.FlutterCustomTaskRunners{
        //     .struct_size = @sizeOf(c.FlutterCustomTaskRunners),
        //     .render_task_runner = @ptrCast(&runner),
        //     .platform_task_runner = @ptrCast(&runner),
        // };

        // args.custom_task_runners = @ptrCast(&runners);
        args.compositor = @ptrCast(&create_flutter_compositor(self.egl));

        const res = c.FlutterEngineInitialize(
            1,
            &config,
            &args,
            self.egl,
            &self.engine,
        );

        //I need the context and surfaces before the thing
        if (res != c.kSuccess) {
            return error.FailedToRunFlutterEngine;
        }
    }

    pub fn run(
        self: *FLEmbedder,
    ) !void {
        _ = c.FlutterEngineRunInitialized(self.engine);
        var event = c.FlutterWindowMetricsEvent{
            .struct_size = @sizeOf(c.FlutterWindowMetricsEvent),
            .width = 1920,
            .height = 80,
            .pixel_ratio = 1,
            .left = 0,
            .top = 0,
            .physical_view_inset_top = 0,
            .physical_view_inset_right = 0,
            .physical_view_inset_bottom = 0,
            .physical_view_inset_left = 0,
            .display_id = 0,
            .view_id = 0,
        };

        _ = c.FlutterEngineSendWindowMetricsEvent(self.engine, &event);

        while (true) {
            self.runner.run_next_task();
        }
    }

    fn wl_loop(wl: *c.wl_display) void {
        while (true) {
            _ = c.wl_display_dispatch(wl);
        }
    }
};

fn channel_update_callback() callconv(.C) void {}
