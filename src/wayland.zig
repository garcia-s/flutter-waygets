const std = @import("std");
const c = @import("c_imports.zig").c;

pub const WaylandManager = struct {
    registry: ?*c.wl_registry = null,
    layer_shell: ?*c.zwlr_layer_shell_v1 = null,
    surface: ?*c.wl_surface = null,
    display: ?*c.wl_display = null,
    compositor: ?*c.wl_compositor = null,
    layer_surface: ?*c.zwlr_layer_surface_v1 = null,

    pub fn init(self: *WaylandManager) !void {
        self.display = c.wl_display_connect("wayland-1");

        if (self.display == null) return error.WaylandConnectionFailed;
        self.registry = c.wl_display_get_registry(self.display);
        if (self.registry == null) return error.RegistryFailed;

        const registry_listener = c.wl_registry_listener{
            .global = global_registry_handler,
            .global_remove = global_registry_remover,
        };

        _ = c.wl_registry_add_listener(self.registry, &registry_listener, self);

        // Round-trip to get the global objects
        _ = c.wl_display_roundtrip(self.display);

        if (self.compositor == null or self.layer_shell == null) {
            return error.MissingGlobalObjects;
        }

        self.surface = c.wl_compositor_create_surface(self.compositor.?);

        if (self.surface == null) return error.SurfaceCreationFailed;
        self.layer_surface = c.zwlr_layer_shell_v1_get_layer_surface(
            self.layer_shell.?,
            self.surface.?,
            null, // Output
            c.ZWLR_LAYER_SHELL_V1_LAYER_TOP,
            "flutter",
        );

        if (self.layer_surface == null) return error.LayerSurfaceFailed;

        c.zwlr_layer_surface_v1_set_exclusive_zone(self.layer_surface, 100);
        c.zwlr_layer_surface_v1_set_size(self.layer_surface.?, 1280, 720);
        c.zwlr_layer_surface_v1_set_anchor(
            self.layer_surface.?,
            c.ZWLR_LAYER_SURFACE_V1_ANCHOR_TOP | c.ZWLR_LAYER_SURFACE_V1_ANCHOR_LEFT,
        );
        c.wl_surface_commit(self.surface.?);
    }

    fn global_registry_handler(
        data: ?*anyopaque,
        registry: ?*c.struct_wl_registry,
        name: u32,
        iface: [*c]const u8,
        version: u32,
    ) callconv(.C) void {
        const manager: *WaylandManager = @ptrCast(@alignCast(data));

        if (std.mem.eql(u8, std.mem.span(iface), "wl_compositor")) {
            manager.compositor = @ptrCast(
                c.wl_registry_bind(
                    registry,
                    name,
                    &c.wl_compositor_interface,
                    version,
                ),
            );
        } else if (std.mem.eql(u8, std.mem.span(iface), "zwlr_layer_shell_v1")) {
            manager.layer_shell = @ptrCast(
                c.wl_registry_bind(
                    registry,
                    name,
                    &c.zwlr_layer_shell_v1_interface,
                    version,
                ),
            );
        }
    }

    fn global_registry_remover(_: ?*anyopaque, _: ?*c.wl_registry, _: u32) callconv(.C) void {}
};
