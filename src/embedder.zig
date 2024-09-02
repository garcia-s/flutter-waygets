//Embedder file
//
const std = @import("std");

const c = @cImport({
    @cDefine("WLR_USE_UNSTABLE", "");
    @cInclude("flutter_embedder.h");
    @cInclude("wayland-client.h");
    @cInclude("wlr/types/wlr_layer_shell_v1.h");
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

        //THIS IS PURE HALLUCINATION
        // self.layer_surface = c.zwlr_layer_shell_v1_get_layer_surface(
        //     self.layer_shell.?,
        //     self.surface.?,
        //     null, // Output
        //     c.ZWLR_LAYER_SHELL_V1_LAYER_TOP,
        //     "my_flutter_layer",
        // );

        if (self.layer_surface == null) return error.LayerSurfaceFailed;

        // Set size and anchor
        c.zwlr_layer_surface_v1_set_size(self.layer_surface.?, 1280, 720);
        c.zwlr_layer_surface_v1_set_anchor(
            self.layer_surface.?,
            c.ZWLR_LAYER_SURFACE_V1_ANCHOR_TOP | c.ZWLR_LAYER_SURFACE_V1_ANCHOR_LEFT,
        );
        c.wl_surface_commit(self.surface.?);
    }

    pub fn run(self: *FlutterEmbedder) !void {
        while (true) {
            if (c.wl_display_dispatch(self.display) == -1) {
                break;
            }
        }
    }

    fn global_registry_handler(
        _: ?*anyopaque,
        _: ?*c.struct_wl_registry,
        _: u32,
        _: [*c]const u8,
        _: u32,
    ) callconv(.C) void {}

    fn global_registry_remover(_: ?*anyopaque, _: ?*c.wl_registry, _: u32) callconv(.C) void {}
};

// *const fn (?*anyopaque, ?*cimport.struct_wl_registry, u32) callconv(.C) void
// *const fn (?*anyopaque, *cimport.struct_wl_registry, u32) void
//
// zwlr_layer_surface_v1_interface
