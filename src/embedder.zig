const std = @import("std");
const wayland = @import("wayland.zig");
const open_gl = @import("opengl_config.zig");
const c = @import("c_imports.zig").c;

pub const FlutterEmbedder = struct {
    wl: wayland.WaylandManager = .{},
    open_gl: open_gl.OpenGLManager = .{},
    engine: c.FlutterEngine = undefined,

    pub fn init(self: *FlutterEmbedder, project_path: []u8, icudtl_path: []u8) !void {
        const alloc = std.heap.page_allocator;
        const assets_path = try std.fmt.allocPrint(
            alloc,
            "{s}{s}",
            .{ project_path, "/build/flutter_assets" },
        );

        const args = c.FlutterProjectArgs{
            .struct_size = @sizeOf(c.FlutterProjectArgs),
            .assets_path = @ptrCast(assets_path.ptr),
            .icu_data_path = @ptrCast(icudtl_path),
        };

        const config: c.FlutterRendererConfig = c.FlutterRendererConfig{
            .type = c.kOpenGL,
            .unnamed_0 = .{
                .open_gl = self.open_gl.get_flutter_renderer_config(),
            },
        };
        const engine_result = c.FlutterEngineInitialize(
            1,
            &config,
            &args,
            self,
            &self.engine,
        );

        if (engine_result != c.kSuccess) {
            std.debug.print(
                "Failed to initialize the flutter engine: {X}",
                .{engine_result},
            );
            return error.FlutterEngineInitializingFailed;
        }
    }

    pub fn run(self: *FlutterEmbedder, project_path: []u8, icudtl_path: []u8) !void {
        //First we initialize the engine
        try self.init(project_path, icudtl_path);
        //Then we bind to wayland
        try self.wl.init();
        //Then we bind to opengl
        try self.open_gl.init(
            self.wl.display,
            self.wl.surface,
        );

        // std.debug.print("Starting the wayland loop", .{});

        // while (true) {
        //     const result = engine
        //
        //     if (result != c.kSuccess) {
        //         std.debug.print("Failed to run engine task", .{});
        //         break;
        //     }
        //
        //     if (c.wl_display_dispatch(self.wl.display) < -1) {
        //         std.debug.print("Unable to dispatch to wayland", .{});
        //         break;
        //     }
        // }
    }
};
