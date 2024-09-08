const std = @import("std");
const wayland = @import("wayland.zig");
const open_gl = @import("opengl_config.zig");
const c = @import("c_imports.zig").c;

pub const FlutterEmbedder = struct {
    wl: wayland.WaylandManager = .{},
    open_gl: open_gl.OpenGLManager = .{},
    engine: c.FlutterEngine = null,

    pub fn run(self: *FlutterEmbedder, args: [][]u8) !void {
        //First we initialize the engine
        const alloc = std.heap.page_allocator;

        const assets_path = try std.fmt.allocPrint(
            alloc,
            "{s}{s}",
            .{ args[1], "/build/flutter_assets" },
        );

        // const argsv = [_][*:0]const u8{
        //     "--trace-skia",
        //     "--debug",
        //     "--verbose",
        //     "--enable-impeller",
        // };
        // const argsv = try alloc.alloc([]u8, args.len);

        const engine_args = c.FlutterProjectArgs{
            .struct_size = @sizeOf(c.FlutterProjectArgs),
            .assets_path = @ptrCast(assets_path.ptr),
            .icu_data_path = @ptrCast(args[2]),
            // .command_line_argv = @ptrCast(&argsv),
            // .command_line_argc = @intCast(argsv.len),
        };

        const config: c.FlutterRendererConfig = c.FlutterRendererConfig{
            .type = c.kOpenGL,
            .unnamed_0 = .{
                .open_gl = open_gl.OpenGLRendererConfig,
            },
        };

        //Then we bind to wayland
        try self.wl.init();
        //Then we bind to opengl
        try self.open_gl.init(
            self.wl.display,
            self.wl.surface,
            self.wl.dummy_surface,
        );

        const result = c.FlutterEngineRun(
            1,
            &config,
            &engine_args,
            self,
            &self.engine,
        );

        if (result != c.kSuccess) {
            std.debug.print(
                "Failed to initialize the flutter engine: {X}",
                .{result},
            );
            return error.FlutterEngineRunFailed;
        }
        const event = c.FlutterWindowMetricsEvent{
            .struct_size = @sizeOf(c.FlutterWindowMetricsEvent),
            .width = 1240,
            .height = 720,
            .pixel_ratio = 10,
            .left = 0,
            .top = 0,
            .physical_view_inset_top = 0,
            .physical_view_inset_right = 0,
            .physical_view_inset_bottom = 0,
            .physical_view_inset_left = 0,
            .display_id = 0,
            .view_id = 0,
        };

        while (true) {
            _ = c.FlutterEngineSendWindowMetricsEvent(self.engine, &event);
            _ = c.wl_display_dispatch(self.wl.display);
        }
    }
};
