const std = @import("std");
const c = @import("c_imports.zig").c;
const FLView = @import("fl_view.zig").FLView;

const ctx_attrib: [*c]c.EGLint = @constCast(&[_]c.EGLint{
    c.EGL_CONTEXT_CLIENT_VERSION, 2,
    c.EGL_NONE,
});

const surface_attrib = [_]c.EGLint{c.EGL_NONE};

pub const FLWindow = struct {
    name: *[]u8 = undefined,
    wl_surface: *c.struct_wl_surface = undefined,
    window: *c.struct_wl_egl_window = undefined,
    surface: c.EGLSurface = undefined,

    pub fn init(
        self: *FLWindow,
        compositor: *c.struct_wl_compositor,
        layer_shell: *c.struct_zwlr_layer_shell_v1,
        display: c.EGLDisplay,
        config: c.EGLConfig,
        view: *const FLView,
    ) !void {
        self.wl_surface = c.wl_compositor_create_surface(compositor) orelse {
            std.debug.print("failed to get a wayland surface\n", .{});
            return error.SurfaceCreationFailed;
        };

        self.wl_layer_surface = c.zwlr_layer_shell_v1_get_layer_surface(
            layer_shell,
            self.wl_surface,
            null,
            view.layer,
            @ptrCast(&view.name),
        ) orelse {
            std.debug.print("Failed to initialize a layer surface\n", .{});
            return error.LayerSurfaceFailed;
        };
        //
        const layer_listener = c.struct_zwlr_layer_surface_v1_listener{
            .configure = configure,
            .closed = closed,
        };

        _ = c.zwlr_layer_surface_v1_add_listener(
            self.wl_layer_surface,
            &layer_listener,
            null,
        );

        const anchor_mask: u32 =
            @intCast(c.ZWLR_LAYER_SURFACE_V1_ANCHOR_TOP * @intFromBool(view.anchors.top) |
            c.ZWLR_LAYER_SURFACE_V1_ANCHOR_LEFT * @intFromBool(view.anchors.left) |
            c.ZWLR_LAYER_SURFACE_V1_ANCHOR_BOTTOM * @intFromBool(view.anchors.bottom) |
            c.ZWLR_LAYER_SURFACE_V1_ANCHOR_RIGHT * @intFromBool(view.anchors.right));

        //Pass it as configs
        c.zwlr_layer_surface_v1_set_anchor(
            self.wl_layer_surface,
            anchor_mask,
        );

        //Pass it as configs
        _ = c.zwlr_layer_surface_v1_set_size(
            self.wl_layer_surface,
            view.width,
            view.height,
        );

        _ = c.zwlr_layer_surface_v1_set_keyboard_interactivity(
            self.wl_layer_surface,
            view.keyboard_interactivity,
        );

        _ = c.zwlr_layer_surface_v1_set_exclusive_zone(
            self.wl_layer_surface,
            @intCast(view.exclusive_zone),
        );

        self.window = c.wl_egl_window_create(
            self.wl_surface,
            @intCast(view.width),
            @intCast(view.height),
        ) orelse {
            std.debug.print("Error creating dummy window", .{});
            return error.GetEglPlatformWindowFailed;
        };

        c.wl_surface_commit(self.wl_surface);
        self.surface = c.eglCreateWindowSurface(
            display,
            config,
            self.window,
            &surface_attrib,
        );

        if (self.surface == c.EGL_NO_SURFACE) {
            std.debug.print("Failed to create the EGL surface\n", .{});
            return error.EglSurfaceFailed;
        }
    }

    pub fn destroy(_: *FLWindow) !void {}
};

fn configure(
    _: ?*anyopaque,
    surface: ?*c.struct_zwlr_layer_surface_v1,
    serial: u32,
    _: u32,
    _: u32,
) callconv(.C) void {
    c.zwlr_layer_surface_v1_ack_configure(surface, serial);
}

fn closed(_: ?*anyopaque, _: ?*c.struct_zwlr_layer_surface_v1) callconv(.C) void {
    std.debug.print("Surface was closed \n", .{});
}
