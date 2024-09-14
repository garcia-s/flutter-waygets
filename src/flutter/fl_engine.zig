const std = @import("std");
const c = @import("../c_imports.zig").c;

const FLWindow = @import("fl_window.zig").FLWindow;
const WindowConfig = @import("../daemon/window_config.zig").WindowConfig;

const dummystruct = struct {
    name: []u8,
};

pub const FLEngine = struct {
    path: [][]u8 = undefined,
    window: FLWindow = FLWindow{},
    engine_args: c.FlutterProjectArgs = c.FlutterProjectArgs{
        .struct_size = @sizeOf(c.FlutterProjectArgs),
    },

    pub fn init(_: FLEngine, root_path: []u8, _: *[]u8) !void {
        const alloc = std.heap.page_allocator;
        const conf_path = try std.fmt.allocPrint(alloc, "{s}/{s}", .{
            root_path,
            "config.json",
        });

        const fd = try std.fs.cwd().openFile(conf_path, .{ .mode = .read_only });

        const buff = try fd.readToEndAlloc(alloc, 2048);
        defer alloc.free(buff);

        _ = try std.json.parseFromSlice(dummystruct, alloc, buff, .{});
        std.debug.print("RUNNING {s}\n ", .{conf_path});
        // const aot_path = try std.fmt.allocPrint(alloc, "{s}{s}", .{ root_path, "/../lib/libapp.so" });

        // const argsv = [_][*:0]const u8{
        //     "--trace-skia",
        //     "--debug", "--verbose",
        // };

        //     var timing = std.time.milliTimestamp();
        //     var window = FLWindow{};
        //     try window.init(
        //         self.wl_display,
        //         self.wl_compositor,
        //         self.wl_layer_shell,
        //         self.egl.display,
        //         self.egl.config,
        //         WindowConfig{
        //             .exclusive_zone = 60,
        //             .width = 1920,
        //             .height = 500,
        //             .closed = false,
        //         },
        //     );
        //
        //     std.debug.print("INITIAL TOOK: {d} ms \n", .{std.time.milliTimestamp() - timing});
        //     const alloc = std.heap.page_allocator;
        //
        //     const aot_alloc = std.heap.GeneralPurposeAllocator(.{}){};
        //     const aot_path = try std.fmt.allocPrint(aot_alloc, "{s}{s}", .{ self.path, "/../lib/libapp.so" });
        //
        //     // const argsv = [_][*:0]const u8{
        //     //     "--trace-skia",
        //     //     "--debug", "--verbose",
        //     // };
        //     var engine_args =
        //
        //     if (c.FlutterEngineRunsAOTCompiledDartCode()) {
        //         try aot.get_aot_data(
        //             aot_path,
        //             &engine_args.vm_snapshot_data,
        //             &engine_args.vm_snapshot_instructions,
        //             &engine_args.isolate_snapshot_data,
        //             &engine_args.isolate_snapshot_instructions,
        //         );
        //     }
        //
        //     const config: c.FlutterRendererConfig = c.FlutterRendererConfig{
        //         .unnamed_0 = .{ .open_gl = OpenGLRendererConfig },
        //         .type = c.kOpenGL,
        //     };
        //
        //     const eng = c.FlutterEngineInitialize(
        //         1,
        //         &config,
        //         &engine_args,
        //         &window,
        //         &self.engines[0],
        //     );
        //
        //     if (eng != c.kSuccess)
        //         return error.FailedToRunFlutterEngine;
        //
        //     _ = c.FlutterEngineRunInitialized(self.engines[0]);
        //
        //     _ = c.FlutterEnginePostRenderThreadTask(
        //         self.engines[0],
        //         render_callback,
        //         null,
        //     );
        //     try self.input_state.map.put(window.wl_surface, self.engines[0]);
        //     const event = c.FlutterWindowMetricsEvent{
        //         .struct_size = @sizeOf(c.FlutterWindowMetricsEvent),
        //         .width = window.state.width,
        //         .height = window.state.height,
        //         .pixel_ratio = 1,
        //         .left = 0,
        //         .top = 0,
        //         .physical_view_inset_top = 0,
        //         .physical_view_inset_right = 0,
        //         .physical_view_inset_bottom = 0,
        //         .physical_view_inset_left = 0,
        //         .display_id = 0,
        //         .view_id = 0,
        //     };
        //
        //     _ = c.FlutterEngineShutdown(self.engines[0]);
        //
        //     timing = std.time.milliTimestamp();
        //     _ = c.FlutterEngineInitialize(
        //         1,
        //         &config,
        //         &engine_args,
        //         &window,
        //         &self.engines[0],
        //     );
        //
        //     _ = c.FlutterEngineRunInitialized(self.engines[0]);
        //     std.debug.print("SECOND TOOK: {d} ms \n", .{std.time.milliTimestamp() - timing});
        //     _ = c.FlutterEngineSendWindowMetricsEvent(self.engines[0], &event);
        //     while (true) {
        //         _ = c.wl_display_dispatch(self.wl_display);
        //
        //         std.debug.print("Metrics Sent", .{});
        //     }
        while (true) {}
    }
};
