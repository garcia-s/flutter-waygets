const c = @import("c_imports.zig").c;
const std = @import("std");

const config_attrib = [_]c.EGLint{
    c.EGL_RENDERABLE_TYPE, c.EGL_OPENGL_ES2_BIT,
    c.EGL_SURFACE_TYPE,    c.EGL_WINDOW_BIT,
    c.EGL_RED_SIZE,        8,
    c.EGL_GREEN_SIZE,      8,
    c.EGL_BLUE_SIZE,       8,
    c.EGL_ALPHA_SIZE,      8,
    // c.EGL_DEPTH_SIZE,      0,
    // c.EGL_STENCIL_SIZE,    8,
    c.EGL_NONE,
};

pub const WLEgl = struct {
    display: c.EGLDisplay = null,
    config: c.EGLConfig = null,
    context: c.EGLContext = undefined,
    resource_context: c.EGLContext = undefined,
    //should have the contexts

    pub fn init(self: *WLEgl, wl_display: *c.wl_display) !void {
        self.display = c.eglGetDisplay(
            wl_display,
        );

        if (self.display == c.EGL_NO_DISPLAY)
            return error.eglGetDisplayFailed;

        if (c.eglInitialize(self.display, null, null) != c.EGL_TRUE)
            return error.eglInitializeFailed;

        if (c.eglBindAPI(c.EGL_OPENGL_ES_API) != c.EGL_TRUE) {
            return error.eglbindfailed;
        }

        var num_config: c.EGLint = 0;

        const conf_result = c.eglChooseConfig(
            self.display,
            &config_attrib,
            &self.config,
            1,
            &num_config,
        );

        if (conf_result != c.EGL_TRUE or num_config == 0) {
            std.debug.print("failed to get a config: (egl code {x})\n", .{c.eglGetError()});
            return error.eglchooseconfigfailed;
        }
    }
};
