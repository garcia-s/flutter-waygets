const std = @import("std");
const c = @import("c_imports.zig").c;
//TODO: OpenGL context setup
///The parameter here is a pointer to what we passed as "user_data"
///which for now is the FlutterEmbedder instance
pub const OpenGLManager = struct {
    display: c.EGLDisplay = null,
    window: ?*c.struct_wl_egl_window = null,
    context: ?*anyopaque = null,
    config: ?*anyopaque = null,
    surface: ?*anyopaque = null,

    pub fn init(
        self: *OpenGLManager,
        display: ?*c.struct_wl_display,
        surface: ?*c.struct_wl_surface,
    ) !void {
        if (surface == null)
            return error.NoSurfaceProvidedToOpenGLContext;

        self.display = c.eglGetDisplay(display);

        if (self.display == c.EGL_NO_DISPLAY)
            return error.EglGetDisplayFailed;

        if (c.eglInitialize(self.display, null, null) == c.EGL_FALSE)
            return error.EglInitializeFailed;

        //WHAT DOES THIS DO?
        const config_attrib = [_]c.EGLint{
            c.EGL_RED_SIZE,   8,
            c.EGL_GREEN_SIZE, 8,
            c.EGL_BLUE_SIZE,  8,
            c.EGL_NONE,
        };

        var config: c.EGLConfig = undefined;
        var num_config: c.EGLint = 0;

        if (c.eglChooseConfig(
            self.display.?,
            &config_attrib,
            &config,
            1,
            &num_config,
        ) == c.EGL_FALSE) return error.EglChooseConfigFailed;

        //TODO: FIX HARDCODED WIDTH AND HEIGHT
        self.window = c.wl_egl_window_create(surface, 1280, 720);
        if (self.window == null) return error.GetEglPlatformWindowFailed;

        //TODO: WHAT DOES THESE ATTRIBUTES DO?
        const surface_attrib = [_]c.EGLAttrib{
            c.EGL_NONE,
        };

        const egl_surface = c.eglCreatePlatformWindowSurface(
            self.display,
            config,
            self.window,
            &surface_attrib,
        );

        const context_attribs = [_]c.EGLint{
            c.EGL_CONTEXT_CLIENT_VERSION, 2, // OpenGL ES 2
            c.EGL_NONE,
        };

        if (egl_surface == c.EGL_NO_SURFACE)
            return error.EglSurfaceCreateFailed;

        const context = c.eglCreateContext(
            self.display,
            config,
            null,
            &context_attribs,
        );

        if (context == c.EGL_NO_CONTEXT)
            return error.EglContextCreateFailed;
    }

    pub fn get_flutter_renderer_config(_: *OpenGLManager) c.FlutterOpenGLRendererConfig {
        return .{
            .struct_size = @sizeOf(c.FlutterOpenGLRendererConfig),
            .make_current = make_current,
            .clear_current = clear_current,
            .present = present,
            .fbo_callback = fbo_callback,
            .gl_proc_resolver = gl_proc_resolver,
        };
    }

    fn make_current(_: ?*anyopaque) callconv(.C) bool {
        // const embedder: *FlutterEmbedder = @ptrCast(@alignCast(data));
        return true;
    }

    //TODO: Setup OpenGL context cleanup
    fn clear_current(_: ?*anyopaque) callconv(.C) bool {
        return true;
    }

    //TODO: WTF is a swap buffer?
    fn present(_: ?*anyopaque) callconv(.C) bool {
        return true;
    }

    //Framebuffer Object (FBO).
    //I dont know what it's and in the example this just returns 0.
    fn fbo_callback(_: ?*anyopaque) callconv(.C) u32 {
        return 0;
    }

    //resource context setup. What in all hells is that?
    // fn make_resource_current(_: ?*anyopaque) callconv(.C) bool {
    //     return true;
    // }

    fn gl_proc_resolver(_: ?*anyopaque, _: [*c]const u8) callconv(.C) ?*anyopaque {
        // Your GL proc resolver here
        return null;
    }

    // Implement your surface presentation logic here
    fn surface_present(_: ?*anyopaque, _: *anyopaque) callconv(.C) bool {
        return true;
    }
};
