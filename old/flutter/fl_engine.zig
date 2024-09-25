const std = @import("std");
const c = @import("../c_imports.zig").c;

const WindowConfig = @import("../daemon/window_config.zig").WindowConfig;
const WindowAnchors = @import("../daemon/window_config.zig").WindowAnchors;
const tasks = @import("fl_task_runners.zig");
const FLRenderer = @import("fl_renderer.zig").FLRenderer;
const loader = @import("../daemon/flutter_aot_loader.zig");
const YaraEngine = @import("../daemon/engine.zig").YaraEngine;
const create_renderer_config = @import("fl_render_config.zig").create_renderer_config;
const create_flutter_compositor = @import("experimental_fl_compositor.zig").create_flutter_compositor;

pub const FLEngine = struct {
    gpa: std.heap.GeneralPurposeAllocator(.{}) = undefined,
    renderer: *FLRenderer = undefined,
    daemon: *YaraEngine = undefined,
    engine_args: c.flutterprojectargs = undefined,
    engine: c.FlutterEngine = undefined,

    pub fn init(self: *FLEngine, global_path: *const []u8, name: *const []const u8, _: *YaraEngine) !void {
        self.gpa = std.heap.GeneralPurposeAllocator(.{}){};
        self.alloc = self.gpa.allocator();

        //C NEEDS this two to be null terminated strings
        //if they are not it'll never shut up about it
        const assets_path = try std.fmt.allocPrintZ(self.alloc, "{s}/{s}/{s}", .{
            global_path.*,
            name.*,
            "flutter_assets",
        });

        const icu_path = try std.fmt.allocPrintZ(self.alloc, "{s}/{s}/{s}", .{
            global_path.*,
            name.*,
            "icudtl.dat",
        });

        std.debug.print("ICU: {s}\n", .{icu_path});
        std.debug.print("Assets: {s}\n", .{assets_path});

        //
    }

    pub fn run(_: *FLEngine) !void {
        // const result = c.FlutterEngineRunInitialized(self.engine);
        //
        // if (result != c.kSuccess) {
        //     std.debug.print("Failed to run the flutter engine \n", .{});
        //     return error.FlutterEngineRunFailed;
        // }

        // const event = c.FlutterWindowMetricsEvent{
        //     .struct_size = @sizeOf(c.FlutterWindowMetricsEvent),
        //     .width = self.window.state.width,
        //     .height = self.window.state.height,
        //     .pixel_ratio = 1,
        //     .left = 0,
        //     .top = 0,
        //     .physical_view_inset_top = 0,
        //     .physical_view_inset_right = 0,
        //     .physical_view_inset_bottom = 0,
        //     .physical_view_inset_left = 0,
        //     .display_id = 0,
        //     .view_id = 0,
        // };
        //
        // _ = c.FlutterEngineSendWindowMetricsEvent(self.engine, &event);

        // while (true) {
        //     self.platform_runner.run_next_task();
        //     self.renderer_runner.run_next_task();
        // }
    }
};
