//Embedder file
//
const std = @import("std");

const c = @cImport({
    @cInclude("wayland-client.h");
    @cInclude("flutter_embedder.h");
    @cInclude("wlr-layer-shell-unstable-v1-client-protocol.h");
});

pub const FlutterEmbedder = struct {
    display: ?*c.wl_display = null,
    registry: ?*c.wl_registry = null,
    compositor: ?*c.wl_compositor = null,
    layer_shell: ?*c.zwlr_layer_shell_v1 = null,
    surface: ?*c.wl_surface = null,
    layer_surface: ?*c.zwlr_layer_surface_v1 = null,

    pub fn init(self: *FlutterEmbedder) !void {
        self.display = c.wl_display_connect(null);
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
            "my_flutter_layer",
        );

        if (self.layer_surface == null) return error.LayerSurfaceFailed;

        c.zwlr_layer_surface_v1_set_size(self.layer_surface.?, 1280, 720);
        c.zwlr_layer_surface_v1_set_anchor(
            self.layer_surface.?,
            c.ZWLR_LAYER_SURFACE_V1_ANCHOR_TOP | c.ZWLR_LAYER_SURFACE_V1_ANCHOR_LEFT,
        );
        c.wl_surface_commit(self.surface.?);
    }

    pub fn run(self: *FlutterEmbedder) !void {
        const config = c.FlutterOpenGLRendererConfig{};
        config.make_current = fn (userdata: ?anyopaque) bool{return false};
        config.clear_current = fn (userdata: ?anyopaque) bool{return false};
        config.present = fn (userdata: ?anyopaque) bool{return false};
        config.fbo_callback = fn (?*anyopaque) u32{
            //TODO: IMPLEMENT
            return 0,
        };

        while (true) {
            if (c.wl_display_dispatch(self.display) == -1) {
                break;
            }
        }
    }

    fn global_registry_handler(
        data: ?*anyopaque,
        registry: ?*c.struct_wl_registry,
        name: u32,
        iface: [*c]const u8,
        version: u32,
    ) callconv(.C) void {
        const embedder: *FlutterEmbedder = @ptrCast(@alignCast(data));
        if (std.mem.eql(u8, std.mem.span(iface), "wl_compositor")) {
            embedder.compositor = @ptrCast(
                c.wl_registry_bind(
                    registry,
                    name,
                    &[_]c.wl_interface{c.wl_compositor_interface},
                    version,
                ),
            );
        } else if (std.mem.eql(u8, std.mem.span(iface), "zwlr_layer_shell_v1")) {
            embedder.layer_shell = @ptrCast(
                c.wl_registry_bind(
                    registry,
                    name,
                    &[_]c.wl_interface{c.zwlr_layer_surface_v1_interface},
                    version,
                ),
            );
        }
    }

    fn global_registry_remover(_: ?*anyopaque, _: ?*c.wl_registry, _: u32) callconv(.C) void {}
};

// *const fn (?*anyopaque, ?*cimport.struct_wl_registry, u32, [*c]const u8, u32) callconv(.C) void
// *const fn (?*anyopaque, ?*cimport.struct_wl_registry, u32, [*c]u8, u32) callconv(.C) void
//
// @ptrCast([*c]u32, @alignCast(@alignOf(*u32), surface.*.pixels));

// *const fn (?*anyopaque, ?*cimport.struct_wl_registry, u32) callconv(.C) void
// *const fn (?*anyopaque, *cimport.struct_wl_registry, u32) void
//
// zwlr_layer_surface_v1_interface
