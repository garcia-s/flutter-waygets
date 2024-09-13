const std = @import("std");
const c = @import("../c_imports.zig").c;
const WindowState = @import("window_state.zig").WindowState;

//TODO: OpenGL context setup The parameter here is
//a pointer to what we passed as "user_data"
//which for now is the FlutterEngine instance

const ctx_attrib: [*c]c.EGLint = @constCast(&[_]c.EGLint{
    c.EGL_CONTEXT_CLIENT_VERSION, 2,
    c.EGL_NONE,
});

pub const EGLWindow = struct {
    state: WindowState = undefined,
    //Wayland stuff
    wl_surface: *c.wl_surface = undefined,
    wl_layer_surface: *c.zwlr_layer_surface_v1 = undefined,
    wl_dummy_surface: *c.wl_surface = undefined,

    ///Window stuff
    window: *c.struct_wl_egl_window = undefined,
    display: c.EGLDisplay = null,
    surface: c.EGLSurface = null,
    resource_surface: c.EGLSurface = null,
    resource_context: c.EGLContext = null,
    dummy_window: ?*c.struct_wl_egl_window = null,
    dummy_surface: ?*c.struct_wl_surface = null,
    context: c.EGLContext = null,

    pub fn init(
        self: *EGLWindow,
        wl_display: *c.wl_display,
        wl_compositor: *c.struct_wl_compositor,
        wl_layer_shell: *c.struct_zwlr_layer_shell_v1,
        egldisplay: c.EGLDisplay,
        config: c.EGLConfig,
        state: WindowState,
    ) !void {
        self.state = state;
        self.display = egldisplay;

        self.wl_surface = c.wl_compositor_create_surface(wl_compositor) orelse {
            std.debug.print("failed to get a wayland surface\n", .{});
            return error.SurfaceCreationFailed;
        };
        self.dummy_surface = c.wl_compositor_create_surface(wl_compositor) orelse {
            std.debug.print("failed to get a wayland surface\n", .{});
            return error.surfacecreationfailed;
        };

        //pass it as config, like the layer
        self.wl_layer_surface = c.zwlr_layer_shell_v1_get_layer_surface(
            wl_layer_shell,
            self.wl_surface,
            null, // output
            c.ZWLR_LAYER_SHELL_V1_LAYER_TOP,
            "flutter",
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

        //Pass it as configs
        c.zwlr_layer_surface_v1_set_anchor(
            self.wl_layer_surface,
            c.ZWLR_LAYER_SURFACE_V1_ANCHOR_TOP,
        );

        //Pass it as configs
        _ = c.zwlr_layer_surface_v1_set_size(
            self.wl_layer_surface,
            state.width,
            state.height,
        );
        _ = c.zwlr_layer_surface_v1_set_exclusive_zone(
            self.wl_layer_surface,
            @intCast(state.exclusive_zone),
        );

        c.wl_surface_commit(self.wl_surface);

        self.window = c.wl_egl_window_create(
            self.wl_surface,
            @intCast(state.width),
            @intCast(state.height),
        ) orelse {
            return error.GetEglPlatformWindowFailed;
        };

        self.dummy_window = c.wl_egl_window_create(
            self.dummy_surface,
            @intCast(state.width),
            @intCast(state.height),
        ) orelse {
            return error.GetEglPlatformWindowFailed;
        };

        self.context = c.eglCreateContext(
            self.display,
            config,
            null,
            @constCast(ctx_attrib),
        ) orelse {
            return error.EglContextCreateFailed;
        };

        self.resource_context = c.eglCreateContext(
            self.display,
            config,
            self.context,
            @constCast(ctx_attrib),
        ) orelse {
            return error.EglContextCreateFailed;
        };

        const surface_attrib = [_]c.EGLint{c.EGL_NONE};

        self.surface = c.eglCreateWindowSurface(
            self.display,
            config,
            self.window,
            &surface_attrib,
        ) orelse {
            return error.EglSurfaceCreateFailed;
        };

        self.resource_surface = c.eglCreateWindowSurface(
            self.display,
            config,
            self.dummy_window,
            &surface_attrib,
        ) orelse {
            return error.EglSurfaceCreateFailed;
        };

        if (c.wl_display_dispatch(wl_display) < 0) {
            std.debug.print("Failed to dispatch the initial layer surface commit\n", .{});
            return error.LayerSurfaceFailed;
        }
    }

    pub fn destroy(self: *EGLWindow) !void {
        _ = c.eglDestroySurface(self.display, self.surface);
        _ = c.eglDestroySurface(self.display, self.resource_surface);

        _ = c.eglDestroyContext(self.display, self.resource_context);
        _ = c.eglDestroyContext(self.display, self.resource_context);

        _ = c.wl_egl_window_destroy(self.window);
        _ = c.wl_egl_window_destroy(self.dummy_window);

        _ = c.zwlr_layer_surface_v1_destroy(self.wl_layer_surface);
        //
        _ = c.wl_surface_destroy(self.wl_surface);
    }
};

fn configure(
    _: ?*anyopaque,
    surface: ?*c.struct_zwlr_layer_surface_v1,
    serial: u32,
    _: u32,
    _: u32,
) callconv(.C) void {
    std.debug.print("RETURNING LAYER ACK\n", .{});
    c.zwlr_layer_surface_v1_ack_configure(
        surface,
        serial,
    );
}

fn closed(_: ?*anyopaque, _: ?*c.struct_zwlr_layer_surface_v1) callconv(.C) void {
    std.debug.print("Surface was closed \n", .{});
}
