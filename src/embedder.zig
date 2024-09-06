const std = @import("std");
const wayland = @import("wayland.zig");
const open_gl = @import("opengl_config.zig");
const c = @import("c_imports.zig").c;

pub const FlutterEmbedder = struct {
    wl: wayland.WaylandManager = .{},
    open_gl: open_gl.OpenGLManager = .{},

    pub fn run(self: *FlutterEmbedder, project_path: []u8, icudtl_path: []u8) !void {

        //TODO: SHOULD CHECK IF PROJECT PATH AND ICUDTL IS VALID OTHERWISE
        //NONE OF THIS MAKES ANY SENSE
        try self.wl.init();
        try self.open_gl.init(self.wl.display, self.wl.surface);

        const config: c.FlutterRendererConfig = c.FlutterRendererConfig{
            .type = c.kOpenGL,
            .unnamed_0 = .{
                .open_gl = self.open_gl.get_flutter_renderer_config(),
            },
        };

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

        var engine: c.FlutterEngine = undefined;

        _ = c.FlutterEngineRun(
            1,
            &config,
            &args,
            self,
            &engine,
        );

        std.debug.print("Starting the wayland loop", .{});
        while (true) {
            if (c.wl_display_dispatch(self.wl.display) == -1) {
                std.debug.print("Unable to dispatch to wayland", .{});
            }
        }
    }
};
