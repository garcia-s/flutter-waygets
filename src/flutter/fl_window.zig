const std = @import("std");
const c = @import("../c_imports.zig").c;
const WindowConfig = @import("../daemon/window_config.zig").WindowConfig;

const ctx_attrib: [*c]c.EGLint = @constCast(&[_]c.EGLint{
    c.EGL_CONTEXT_CLIENT_VERSION, 2,
    c.EGL_NONE,
});

pub const FLWindow = struct {
    state: WindowConfig = undefined,

    display: c.EGLDisplay = undefined,

    wl_layer_surface: *c.zwlr_layer_surface_v1 = undefined,
    wl_surface: *c.struct_wl_surface = undefined,
    window: *c.struct_wl_egl_window = undefined,
    surface: c.EGLSurface = undefined,
    context: c.EGLContext = undefined,

    dummy_window: *c.struct_wl_egl_window = undefined,
    dummy_surface: *c.struct_wl_surface = undefined,
    resource_context: c.EGLContext = undefined,
    resource_surface: c.EGLSurface = undefined,

    pub fn init(
        self: *FLWindow,
        compositor: *c.struct_wl_compositor,
        layer_shell: *c.struct_zwlr_layer_shell_v1,
        egldisplay: c.EGLDisplay,
        _: c.EGLConfig,
        state: WindowConfig,
    ) !void {
        self.state = state;
        self.display = egldisplay;

        self.wl_surface = c.wl_compositor_create_surface(compositor) orelse {
            std.debug.print("failed to get a wayland surface\n", .{});
            return error.SurfaceCreationFailed;
        };

        self.dummy_surface = c.wl_compositor_create_surface(compositor) orelse {
            std.debug.print("failed to get a wayland surface\n", .{});
            return error.surfacecreationfailed;
        };

        //pass it as config, like the layer
        self.wl_layer_surface = c.zwlr_layer_shell_v1_get_layer_surface(
            layer_shell,
            self.wl_surface,
            null, // output
            self.state.layer,
            //Please change this to the name of the app
            "yara_layer",
        ) orelse {
            std.debug.print("Failed to initialize a layer surface\n", .{});
            return error.LayerSurfaceFailed;
        };

        const layer_listener = c.struct_zwlr_layer_surface_v1_listener{
            .configure = configure,
            .closed = closed,
        };

        _ = c.zwlr_layer_surface_v1_add_listener(
            self.wl_layer_surface,
            &layer_listener,
            null,
        );
        const anchor_mask: u32 = @intCast(c.ZWLR_LAYER_SURFACE_V1_ANCHOR_TOP * @intFromBool(self.state.anchors.top) |
            c.ZWLR_LAYER_SURFACE_V1_ANCHOR_LEFT * @intFromBool(self.state.anchors.left) |
            c.ZWLR_LAYER_SURFACE_V1_ANCHOR_BOTTOM * @intFromBool(self.state.anchors.bottom) |
            c.ZWLR_LAYER_SURFACE_V1_ANCHOR_RIGHT * @intFromBool(self.state.anchors.right));

        std.debug.print("ANCHOR: {d}\n", .{anchor_mask});
        //Pass it as configs
        c.zwlr_layer_surface_v1_set_anchor(
            self.wl_layer_surface,
            anchor_mask,
        );

        //Pass it as configs
        _ = c.zwlr_layer_surface_v1_set_size(
            self.wl_layer_surface,
            state.width,
            state.height,
        );

        _ = c.zwlr_layer_surface_v1_set_keyboard_interactivity(
            self.wl_layer_surface,
            state.keyboard_interactivity,
        );

        _ = c.zwlr_layer_surface_v1_set_exclusive_zone(
            self.wl_layer_surface,
            @intCast(state.exclusive_zone),
        );

        self.window = c.wl_egl_window_create(
            self.wl_surface,
            @intCast(state.width),
            @intCast(state.height),
        ) orelse {
            std.debug.print("Error creating dummy window", .{});
            return error.GetEglPlatformWindowFailed;
        };

        self.dummy_window = c.wl_egl_window_create(
            self.dummy_surface,
            @intCast(state.width),
            @intCast(state.height),
        ) orelse {
            std.debug.print("Error creating dummy window", .{});
            return error.GetEglPlatformWindowFailed;
        };
    }

    //
    pub fn destroy(_: *FLWindow) !void {}

    pub fn commit(
        self: *FLWindow,
        display: *c.wl_display,
        config: c.EGLConfig,
    ) !void {
        c.wl_surface_commit(self.wl_surface);

        const surface_attrib = [_]c.EGLint{c.EGL_NONE};

        self.surface = c.eglCreateWindowSurface(
            self.display,
            config,
            self.window,
            &surface_attrib,
        );

        if (self.surface == c.EGL_NO_SURFACE) {
            std.debug.print("Failed to create the EGL surface\n", .{});
            return error.EglSurfaceFailed;
        }

        self.context = c.eglCreateContext(
            self.display,
            config,
            null,
            @constCast(ctx_attrib),
        );

        if (self.context == c.EGL_NO_CONTEXT) {
            std.debug.print("Failed to create the EGL context\n", .{});
            return error.EglContextFaield;
        }

        self.resource_context = c.eglCreateContext(
            self.display,
            config,
            self.context,
            @constCast(ctx_attrib),
        );

        if (self.resource_context == c.EGL_NO_CONTEXT) {
            std.debug.print("Failed to create the EGL resource_context\n", .{});
            return error.EglResourceContextFailed;
        }

        self.resource_surface = c.eglCreateWindowSurface(
            self.display,
            config,
            self.dummy_window,
            &surface_attrib,
        );

        if (self.resource_surface == c.EGL_NO_SURFACE) {
            std.debug.print("Failed to create the EGL resource_surface\n", .{});
            return error.EglResourceSurfaceFailed;
        }

        if (c.wl_display_dispatch(display) < 0) {
            std.debug.print("Failed to dispatch the layer engine\n", .{});
            return error.LayerSurfaceFailed;
        }
    }
};

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
