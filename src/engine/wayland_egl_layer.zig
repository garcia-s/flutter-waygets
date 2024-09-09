const c = @import("../c_imports.zig").c;
const std = @import("std");
const WaylandManager = @import("wayland_manager.zig").WaylandManager;

pub const WaylandEGLSurface = struct {
    surface: ?*c.wl_surface = null,
    layer_surface: ?*c.zwlr_layer_surface_v1 = null,
    dummy_surface: ?*c.wl_surface = null,
};

pub fn CreateWaylandEglSurface(wl: *const WaylandManager) !*WaylandEGLSurface {
    var wl_egl = WaylandEGLSurface{};
    wl_egl.surface = c.wl_compositor_create_surface(wl.wl_compositor);

    if (wl_egl.surface == null) {
        std.debug.print("Failed to get a wayland surface\n", .{});
        return error.SurfaceCreationFailed;
    }

    wl_egl.dummy_surface = c.wl_compositor_create_surface(wl.wl_compositor);

    if (wl_egl.surface == null) {
        std.debug.print("Failed to get a wayland surface\n", .{});
        return error.SurfaceCreationFailed;
    }

    //PASS IT AS CONFIG, like the layer
    wl_egl.layer_surface = c.zwlr_layer_shell_v1_get_layer_surface(
        wl.wl_layer_shell,
        wl_egl.surface,
        null, // Output
        c.ZWLR_LAYER_SHELL_V1_LAYER_TOP,
        "flutter",
    );

    if (wl_egl.layer_surface == null) {
        std.debug.print("Failed to initialize a layer surface\n", .{});
        return error.LayerSurfaceFailed;
    }

    //Why isn't this here
    const layer_listener = c.struct_zwlr_layer_surface_v1_listener{
        .configure = configure,
        .closed = closed,
    };
    _ = c.zwlr_layer_surface_v1_add_listener(
        wl_egl.layer_surface,
        &layer_listener,
        null,
    );

    //Pass it as configs
    c.zwlr_layer_surface_v1_set_anchor(
        wl_egl.layer_surface,
        c.ZWLR_LAYER_SURFACE_V1_ANCHOR_TOP,
    );

    //Pass it as configs
    _ = c.zwlr_layer_surface_v1_set_size(wl_egl.layer_surface, 1280, 100);
    _ = c.zwlr_layer_surface_v1_set_exclusive_zone(wl_egl.layer_surface, 100);

    c.wl_surface_commit(wl_egl.surface);

    if (c.wl_display_dispatch(wl.wl_display) < 0) {
        std.debug.print("Failed to dispatch the initial layer surface commit\n", .{});
        return error.LayerSurfaceFailed;
    }

    return &wl_egl;
}

fn configure(
    _: ?*anyopaque,
    surface: ?*c.struct_zwlr_layer_surface_v1,
    serial: u32,
    _: u32,
    _: u32,
) callconv(.C) void {
    c.zwlr_layer_surface_v1_ack_configure(
        surface,
        serial,
    );
}

fn closed(_: ?*anyopaque, _: ?*c.struct_zwlr_layer_surface_v1) callconv(.C) void {
    std.debug.print("Surface was closed \n", .{});
}
