const std = @import("std");
const c = @import("c_imports.zig").c;
const FlutterEmbedder = @import("embedder.zig").FlutterEmbedder;

pub const WaylandManager = struct {
    registry: ?*c.wl_registry = null,
    layer_shell: ?*c.zwlr_layer_shell_v1 = null,
    surface: ?*c.wl_surface = null,
    display: ?*c.wl_display = null,
    compositor: ?*c.wl_compositor = null,
    layer_surface: ?*c.zwlr_layer_surface_v1 = null,

    pub fn init(self: *WaylandManager) !void {
        self.display = c.wl_display_connect(null);

        if (self.display == null) {
            std.debug.print("Failed to get a wayland display\n", .{});
            return error.WaylandConnectionFailed;
        }

        self.registry = c.wl_display_get_registry(self.display);
        if (self.registry == null) {
            std.debug.print("Failed to get the wayland registry\n", .{});
            return error.RegistryFailed;
        }

        const registry_listener = c.wl_registry_listener{
            .global = global_registry_handler,
            .global_remove = global_registry_remover,
        };

        _ = c.wl_registry_add_listener(self.registry, &registry_listener, self);

        // Round-trip to get the global objects
        _ = c.wl_display_roundtrip(self.display);

        if (self.compositor == null or self.layer_shell == null) {
            std.debug.print("Failed to initialize the wayland layer shell and/or compositor\n", .{});
            return error.MissingGlobalObjects;
        }

        self.surface = c.wl_compositor_create_surface(self.compositor.?);

        if (self.surface == null) {
            std.debug.print("Failed to get a wayland surface\n", .{});
            return error.SurfaceCreationFailed;
        }

        self.layer_surface = c.zwlr_layer_shell_v1_get_layer_surface(
            self.layer_shell.?,
            self.surface.?,
            null, // Output
            c.ZWLR_LAYER_SHELL_V1_LAYER_TOP,
            "flutter",
        );

        if (self.layer_surface == null) {
            std.debug.print("Failed to initialize a layer surface\n", .{});
            return error.LayerSurfaceFailed;
        }

        const layer_listener = c.struct_zwlr_layer_surface_v1_listener{
            .configure = configure,
            .closed = closed,
        };

        _ = c.zwlr_layer_surface_v1_add_listener(self.layer_surface, &layer_listener, self);

        c.zwlr_layer_surface_v1_set_size(self.layer_surface, 300, 300);
        c.zwlr_layer_surface_v1_set_anchor(
            self.layer_surface,
            c.ZWLR_LAYER_SURFACE_V1_ANCHOR_TOP | c.ZWLR_LAYER_SURFACE_V1_ANCHOR_LEFT,
        );
        c.wl_surface_commit(self.surface);

        if (c.wl_display_dispatch(self.display) < 0) {
            std.debug.print("Failed to dispatch the initial layer surface commit\n", .{});
            return error.LayerSurfaceFailed;
        }
    }
};

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

fn configure(
    _: ?*anyopaque,
    surface: ?*c.struct_zwlr_layer_surface_v1,
    serial: u32,
    _: u32,
    _: u32,
) callconv(.C) void {
    std.debug.print("Config Ack for surface created \n", .{});
    c.zwlr_layer_surface_v1_ack_configure(
        surface,
        serial,
    );
}
fn closed(_: ?*anyopaque, _: ?*c.struct_zwlr_layer_surface_v1) callconv(.C) void {}
