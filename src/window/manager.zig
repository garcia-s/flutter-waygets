const c = @import("../c_imports.zig").c;
const std = @import("std");
const WindowConfig = @import("config.zig").WindowConfig;
const FLWindow = @import("window.zig").FLWindow;

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

const ctx_attrib: [*c]c.EGLint = @constCast(&[_]c.EGLint{
    c.EGL_CONTEXT_CLIENT_VERSION, 2,
    c.EGL_NONE,
});

pub const WindowManager = struct {
    ///Wayland Compositor
    compositor: *c.wl_compositor = undefined,

    layer_shell: *c.zwlr_layer_shell_v1 = undefined,
    ///EGL display
    display: c.EGLDisplay = null,
    config: c.EGLConfig = null,
    context: c.EGLContext = undefined,
    resource_context: c.EGLContext = undefined,
    //should have the contexts

    pub fn init(self: *WindowManager, display: *c.wl_display) !void {
        if (self.compositor == undefined)
            return error.UninitializedWaylandCompositor;

        if (self.layer_shell == undefined)
            return error.UninitializedLayerShell;

        self.display = c.eglGetDisplay(
            display,
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
            return error.eglchooseconfigfailed;
        }

        self.context = c.eglCreateContext(
            self.display,
            self.config,
            null,
            @constCast(ctx_attrib),
        );

        if (self.context == c.EGL_NO_CONTEXT) {
            std.debug.print("Failed to create the EGL context\n", .{});
            return error.EglContextFaield;
        }

        self.resource_context = c.eglCreateContext(
            self.display,
            self.config,
            self.context,
            @constCast(ctx_attrib),
        );

        if (self.resource_context == c.EGL_NO_CONTEXT) {
            std.debug.print("Failed to create the EGL resource_context\n", .{});
            return error.EglResourceContextFailed;
        }
    }
};
