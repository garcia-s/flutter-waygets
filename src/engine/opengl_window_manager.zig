const std = @import("std");
const c = @import("../c_imports.zig").c;
const WaylandManager = @import("wayland_manager.zig").WaylandManager;
const eglwl = @import("wayland_egl_layer.zig");
//TODO: OpenGL context setup
///The parameter here is a pointer to what we passed as "user_data"
///which for now is the FlutterEngine instance
pub const WindowConfig = struct {
    width: usize,
    height: usize,
};

pub const OpenGLWindow = struct {
    wl: *eglwl.WaylandEGLSurface = undefined,
    display: c.EGLDisplay = null,
    surface: c.EGLSurface = null,
    resource_surface: c.EGLSurface = null,
    resource_context: c.EGLContext = null,
    window: ?*c.struct_wl_egl_window = null,
    dummy_window: ?*c.struct_wl_egl_window = null,
    context: c.EGLContext = null,
    config: c.EGLConfig = undefined,
    ctx_attrib: [*c]c.EGLint = @constCast(&[_]c.EGLint{
        c.EGL_CONTEXT_CLIENT_VERSION, 2,
        c.EGL_NONE,
    }),

    pub fn init(self: *OpenGLWindow, wl: *WaylandManager) !void {

        //TODO PASS A POINTER TO THE CONFIG
        self.display = c.eglGetDisplay(
            wl.wl_display,
        );

        if (self.display == c.EGL_NO_DISPLAY)
            return error.EglGetDisplayFailed;

        if (c.eglInitialize(self.display, null, null) != c.EGL_TRUE)
            return error.EglInitializeFailed;

        if (c.eglBindAPI(c.EGL_OPENGL_ES_API) != c.EGL_TRUE) {
            return error.EglBindFailed;
        }

        const config_attrib = [_]c.EGLint{
            c.EGL_RENDERABLE_TYPE, c.EGL_OPENGL_ES2_BIT,
            c.EGL_SURFACE_TYPE,    c.EGL_WINDOW_BIT,
            c.EGL_RED_SIZE,        8,
            c.EGL_GREEN_SIZE,      8,
            c.EGL_BLUE_SIZE,       8,
            c.EGL_ALPHA_SIZE,      8,
            c.EGL_DEPTH_SIZE,      0,
            c.EGL_STENCIL_SIZE,    8,
            c.EGL_NONE,
        };

        var num_config: c.EGLint = 0;

        const conf_result = c.eglChooseConfig(
            self.display,
            &config_attrib,
            &self.config,
            1,
            &num_config,
        );

        if (conf_result != c.EGL_TRUE or num_config == 0) {
            std.debug.print("Failed to get a config: (EGL code {X})\n", .{c.eglGetError()});
            return error.EglChooseConfigFailed;
        }

        self.wl = try eglwl.CreateWaylandEglSurface(wl);

        self.window = c.wl_egl_window_create(
            self.wl.surface,
            1980,
            100,
        );

        if (self.window == null)
            return error.GetEglPlatformWindowFailed;

        self.dummy_window = c.wl_egl_window_create(
            self.wl.dummy_surface,
            1980,
            100,
        );

        if (self.dummy_window == null)
            return error.GetEglPlatformWindowFailed;

        self.context = c.eglCreateContext(
            self.display,
            self.config,
            null,
            self.ctx_attrib,
        );

        if (self.context == c.EGL_NO_CONTEXT)
            return error.EglContextCreateFailed;
        //
        self.resource_context = c.eglCreateContext(
            self.display,
            self.config,
            self.context,
            self.ctx_attrib,
        );

        if (self.resource_context == c.EGL_NO_CONTEXT) {
            return error.EglContextCreateFailed;
        }

        const surface_attrib = [_]c.EGLint{c.EGL_NONE};

        self.surface = c.eglCreateWindowSurface(
            self.display,
            self.config,
            self.window,
            &surface_attrib,
        );

        if (self.surface == c.EGL_NO_SURFACE)
            return error.EglSurfaceCreateFailed;

        self.resource_surface = c.eglCreateWindowSurface(
            self.display,
            self.config,
            self.dummy_window,
            &surface_attrib,
        );

        if (self.resource_surface == c.EGL_NO_SURFACE) {
            return error.EglSurfaceCreateFailed;
        }
    }
};
