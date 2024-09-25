const std = @import("std");
const c = @import("c_imports.zig").c;
const WLManager = @import("wl_manager.zig").WLManager;
const WLEgl = @import("wl_egl.zig").WLEgl;
const get_aot_data = @import("fl_aot.zig").get_aot_data;
const create_renderer_config = @import("fl_render_config.zig").create_renderer_config;
const create_task_runners = @import("fl_task_runners.zig").create_task_runners;
const create_flutter_compositor = @import("fl_compositor.zig").create_flutter_compositor;

pub const FLEmbedder = struct {
    alloc: std.mem.Allocator = undefined,
    wl: *WLManager = undefined,
    egl: *WLEgl = undefined,
    engine: c.FlutterEngine = undefined,

    pub fn run(self: *FLEmbedder, path: *[:0]u8) !void {
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        self.alloc = gpa.allocator();

        self.wl = try self.alloc.create(WLManager);
        self.egl = try self.alloc.create(WLEgl);

        //Init wayland stuff
        try self.wl.init();
        //Init egl stuff
        try self.egl.init(self.wl.display);

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
            // .unnamed_0 = .{ .open_gl = create_renderer_config() },
        };

        //
        create_task_runners(&args.custom_task_runners);
        args.compositor = @ptrCast(&create_flutter_compositor());
        //I need the context and surfaces before the thing
        const res = c.FlutterEngineInitialize(
            1,
            &config,
            &args,
            self.egl,
            &self.engine,
        );

        if (res != c.kSuccess) {
            return error.FailedToRunFlutterEngine;
        }

        _ = c.FlutterEngineRunInitialized(self.engine);
    }
};

fn platform_message_callback(message: [*c]const c.FlutterPlatformMessage, _: ?*anyopaque) callconv(.C) void {
    std.debug.print("Hello {?}", .{message.*});
}
fn channel_update_callback() callconv(.C) void {}
