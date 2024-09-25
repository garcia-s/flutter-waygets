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
    alloc: std.mem.Allocator = undefined,
    renderer: *FLRenderer = undefined,
    daemon: *YaraEngine = undefined,
    engine_args: c.FlutterProjectArgs = undefined,
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

        // const fd = try std.fs.cwd().openFile(global_path, .{ .mode = .read_only });
        //
        // const buff = try fd.readToEndAlloc(self.alloc, 2048);
        // defer self.alloc.free(buff);
        //
        // self.engine_args = c.FlutterProjectArgs{
        //     .struct_size = @sizeOf(c.FlutterProjectArgs),
        //     .assets_path = @ptrCast(assets_path.ptr),
        //     .icu_data_path = @ptrCast(icu_path.ptr),
        //     .platform_message_callback = platform_message_callback,
        //     .channel_update_callback = channel_update_callback,
        // };
        //
        // const aot_path = try std.fmt.allocPrint(self.alloc, "{s}{s}", .{
        //     global_path,
        //     "/lib/libapp.so",
        // });
        //
        // if (c.FlutterEngineRunsAOTCompiledDartCode()) {
        //     try loader.get_aot_data(
        //         aot_path,
        //         &self.engine_args.vm_snapshot_data,
        //         &self.engine_args.vm_snapshot_instructions,
        //         &self.engine_args.isolate_snapshot_data,
        //         &self.engine_args.isolate_snapshot_instructions,
        //     );
        // }
        //
        // var config = c.FlutterRendererConfig{
        //     .type = c.kOpenGL,
        //     .unnamed_0 = .{ .open_gl = create_renderer_config() },
        // };
        //
        // self.daemon = daemon;
        // // self.engine_args.custom_task_runners = @ptrCast(&create_task_runners());
        // self.engine_args.compositor = @ptrCast(&create_flutter_compositor(self.window));
        //
        // const res = c.FlutterEngineInitialize(
        //     1,
        //     &config,
        //     &self.engine_args,
        //     self.renderer,
        //     &self.engine,
        // );
        //
        // if (res != c.kSuccess) {
        //     std.debug.print("Failed to initialize the engine", .{});
        //     return error.FailedToRunFlutterEngine;
        // }
        //
        // try self.daemon.input_state.map.put(
        //     self.window.wl_surface,
        //     self.engine,
        // );
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

fn platform_message_callback() callconv(.C) void {}
fn channel_update_callback() callconv(.C) void {}
