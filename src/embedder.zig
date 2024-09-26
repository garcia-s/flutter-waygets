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

pub const FLEmbedder = struct {
    alloc: std.mem.Allocator = undefined,
    wl: *WLManager = undefined,
    egl: *WLEgl = undefined,
    engine: c.FlutterEngine = undefined,

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
        // _ = try std.Thread.spawn(.{}, wl_loop, .{self.wl.display});
        //Init egl stuff
        try self.egl.init(self.wl.display);

        self.egl.windows = try self.alloc.alloc(FLWindow, 5);
        self.egl.windows[0] = FLWindow{};
        try self.egl.windows[0].init(
            self.wl.compositor,
            self.wl.layer_shell,
            self.egl.display,
            self.egl.config,
            implicit_view,
        );

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

        // try self.runner.init(
        //     self.alloc,
        //     std.Thread.getCurrentId(),
        //     &self.engine,
        // );
        //
        // try self.renderer.init(
        //     self.alloc,
        //     std.Thread.getCurrentId(),
        //     &self.engine,
        // );
        //
        // var runners = c.FlutterCustomTaskRunners{
        //     .struct_size = @sizeOf(c.FlutterCustomTaskRunners),
        //     .render_task_runner = @ptrCast(&task.create_fl_runner(&self.renderer)),
        //     .platform_task_runner = @ptrCast(&task.create_fl_runner(&self.runner)),
        // };
        //
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

        self.egl.windows[1] = FLWindow{};
        try self.egl.windows[1].init(
            self.wl.compositor,
            self.wl.layer_shell,
            self.egl.display,
            self.egl.config,
            &FLView{
                .auto_initialize = false,
                .width = 1920,
                .height = 80,
                .exclusive_zone = 300,
                .layer = 2,
                .keyboard_interactivity = 0,
                .margin = .{ 0, 0, 0, 0 },
                .anchors = .{
                    .top = true,
                    .left = false,
                    .bottom = false,
                    .right = false,
                },
            },
        );

        var vue = c.FlutterWindowMetricsEvent{
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
            .view_id = 1,
        };

        var info =
            c.FlutterAddViewInfo{
            .struct_size = @sizeOf(c.FlutterAddViewInfo),
            .view_id = 1,

            .user_data = null,
            .add_view_callback = &add_view_callback,
            .view_metrics = @ptrCast(&vue),
        };
        _ = c.FlutterEngineAddView(self.engine, @ptrCast(&info));

        while (true) {
            std.time.sleep(5e8);
            self.renderer.run_next_task();
            self.runner.run_next_task();
        }
    }

    fn wl_loop(wl: *c.wl_display) void {
        while (true) {
            _ = c.wl_display_dispatch(wl);
        }
    }
};

fn add_view_callback(_: [*c]const c.FlutterAddViewResult) callconv(.C) void {}

fn platform_message_callback(message: [*c]const c.FlutterPlatformMessage, _: ?*anyopaque) callconv(.C) void {
    std.debug.print("Hello {?}", .{message.*});
}
fn channel_update_callback() callconv(.C) void {}
