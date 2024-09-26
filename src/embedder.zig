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
        //Init egl stuff
        try self.egl.init(self.wl.display);

        self.egl.windows = std.ArrayList(*FLWindow).init(self.alloc);

        var window = try self.alloc.create(FLWindow);
        try window.init(
            self.wl.compositor,
            self.wl.layer_shell,
            implicit_view,
        );

        try self.egl.windows.append(window);
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

        var runners = c.FlutterCustomTaskRunners{
            .struct_size = @sizeOf(c.FlutterCustomTaskRunners),
            .render_task_runner = @ptrCast(&task.create_fl_runner(&self.renderer)),
            .platform_task_runner = @ptrCast(&task.create_fl_runner(&self.runner)),
        };

        args.custom_task_runners = @ptrCast(&runners);
        args.compositor = @ptrCast(&create_flutter_compositor());

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

        while (true) {
            std.time.sleep(5e8);
            self.renderer.run_next_task();
            self.runner.run_next_task();
        }
    }
};

fn platform_message_callback(message: [*c]const c.FlutterPlatformMessage, _: ?*anyopaque) callconv(.C) void {
    std.debug.print("Hello {?}", .{message.*});
}
fn channel_update_callback() callconv(.C) void {}
