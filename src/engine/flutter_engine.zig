const std = @import("std");

pub const YaraFlutterEngine = struct {
    pub fn init() !void {
        var timing = std.time.milliTimestamp();
        var window = EGLWindow{};
        try window.init(
            self.wl_display,
            self.wl_compositor,
            self.wl_layer_shell,
            self.egl.display,
            self.egl.config,
            WindowState{
                .exclusive_zone = 60,
                .width = 1920,
                .height = 500,
                .closed = false,
            },
        );

        std.debug.print("INITIAL TOOK: {d} ms \n", .{std.time.milliTimestamp() - timing});
        const alloc = std.heap.page_allocator;
        const assets_path = try std.fmt.allocPrint(
            alloc,
            "{s}{s}",
            .{ args[1], "/build/release/flutter_assets" },
        );

        const aot_alloc = std.heap.page_allocator;
        const aot_path = try std.fmt.allocPrint(aot_alloc, "{s}{s}", .{ assets_path, "/../lib/libapp.so" });

        // const argsv = [_][*:0]const u8{
        //     "--trace-skia",
        //     "--debug", "--verbose",
        // };
        var engine_args = c.FlutterProjectArgs{
            .struct_size = @sizeOf(c.FlutterProjectArgs),
            .assets_path = @ptrCast(assets_path.ptr),
            .icu_data_path = @ptrCast(args[2]),

            // .aot_data = aot_out,
            // .command_line_argv = @ptrCast(&argsv),
            // .command_line_argc = @intCast(argsv.len),
        };

        if (c.FlutterEngineRunsAOTCompiledDartCode()) {
            try aot.get_aot_data(
                aot_path,
                &engine_args.vm_snapshot_data,
                &engine_args.vm_snapshot_instructions,
                &engine_args.isolate_snapshot_data,
                &engine_args.isolate_snapshot_instructions,
            );
        }

        const config: c.FlutterRendererConfig = c.FlutterRendererConfig{
            .unnamed_0 = .{ .open_gl = OpenGLRendererConfig },
            .type = c.kOpenGL,
        };

        const eng = c.FlutterEngineInitialize(
            1,
            &config,
            &engine_args,
            &window,
            &self.engines[0],
        );

        if (eng != c.kSuccess)
            return error.FailedToRunFlutterEngine;

        _ = c.FlutterEngineRunInitialized(self.engines[0]);

        _ = c.FlutterEnginePostRenderThreadTask(
            self.engines[0],
            render_callback,
            null,
        );
        try self.input_state.map.put(window.wl_surface, self.engines[0]);
        const event = c.FlutterWindowMetricsEvent{
            .struct_size = @sizeOf(c.FlutterWindowMetricsEvent),
            .width = window.state.width,
            .height = window.state.height,
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

        _ = c.FlutterEngineShutdown(self.engines[0]);

        timing = std.time.milliTimestamp();
        _ = c.FlutterEngineInitialize(
            1,
            &config,
            &engine_args,
            &window,
            &self.engines[0],
        );

        _ = c.FlutterEngineRunInitialized(self.engines[0]);
        std.debug.print("SECOND TOOK: {d} ms \n", .{std.time.milliTimestamp() - timing});
        _ = c.FlutterEngineSendWindowMetricsEvent(self.engines[0], &event);
        while (true) {
            _ = c.wl_display_dispatch(self.wl_display);

            std.debug.print("Metrics Sent", .{});
        }
    }
};
