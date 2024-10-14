const c = @import("../c_imports.zig").c;
const std = @import("std");
const WindowConfig = @import("config.zig").WindowConfig;
const FLWindow = @import("window.zig").FLWindow;
const wl_registry_listener = @import("../listeners/registry.zig").wl_registry_listener;

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
    wl_display: *c.wl_display = undefined,
    registry: *c.wl_registry = undefined,
    compositor: *c.wl_compositor = undefined,
    seat: *c.struct_wl_seat = undefined,
    layer_shell: *c.zwlr_layer_shell_v1 = undefined,

    ///EGL display
    display: c.EGLDisplay = null,
    config: c.EGLConfig = null,
    context: c.EGLContext = undefined,
    resource_context: c.EGLContext = undefined,
    //should have the contexts

    pub fn init(self: *WindowManager) !void {
        //TODO: GET ALL THE SCREENS
        self.wl_display = c.wl_display_connect(null) orelse {
            std.debug.print("Failed to get a wayland display\n", .{});
            return error.WaylandConnectionFailed;
        };

        self.registry = c.wl_display_get_registry(self.wl_display) orelse {
            std.debug.print("Failed to get the wayland registry\n", .{});
            return error.RegistryFailed;
        };

        const reg_result = c.wl_registry_add_listener(
            self.registry,
            &wl_registry_listener,
            self,
        );
        //Check if this should be done like this
        if (reg_result < 0) {
            std.debug.print("Failed to initialize the wayland layer shell and/or compositor\n", .{});
            return error.MissingGlobalObjects;
        }

        // Round-trip to get the global objects
        _ = c.wl_display_roundtrip(self.wl_display);

        if (self.compositor == undefined or self.layer_shell == undefined or self.seat == undefined) {
            std.debug.print("Failed to bind objects to registry", .{});
            return error.MissingGlobalObjects;
        }
        self.display = c.eglGetDisplay(
            self.wl_display,
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
