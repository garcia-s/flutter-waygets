const std = @import("std");
const c = @import("c_imports.zig").c;
const FlutterEmbedder = @import("embedder.zig").FlutterEmbedder;
//TODO: OpenGL context setup
///The parameter here is a pointer to what we passed as "user_data"
///which for now is the FlutterEmbedder instance
pub const OpenGLManager = struct {
    display: c.EGLDisplay = null,
    surface: c.EGLSurface = null,
    window: ?*c.struct_wl_egl_window = null,
    context: c.EGLContext = null,
    config: c.EGLConfig = null,
    ctx_attrib: [*c]c.EGLint = @constCast(&[_]c.EGLint{
        c.EGL_CONTEXT_CLIENT_VERSION, 2,
        c.EGL_NONE,
    }),

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

        var num_config: c.EGLint = 0;

        if (c.eglChooseConfig(
            self.display.?,
            &config_attrib,
            &self.config,
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

        self.surface = c.eglCreatePlatformWindowSurface(
            self.display,
            self.config,
            self.window,
            &surface_attrib,
        );

        if (self.surface == c.EGL_NO_SURFACE)
            return error.EglSurfaceCreateFailed;

        self.context = c.eglCreateContext(
            self.display,
            self.config,
            null,
            self.ctx_attrib,
        );

        if (self.context == null)
            return error.EglContextCreateFailed;

        if (self.context == c.EGL_NO_CONTEXT)
            return error.EglContextCreateFailed;
    }

    pub fn get_flutter_renderer_config(_: *OpenGLManager) c.FlutterOpenGLRendererConfig {
        return .{
            .struct_size = @sizeOf(c.FlutterOpenGLRendererConfig),
            .make_current = make_current,
            // .make_resource_current = make_resource_current,
            .clear_current = clear_current,
            .present = present,
            .fbo_callback = fbo_callback,
            .gl_proc_resolver = gl_proc_resolver,
        };
    }

    fn make_current(data: ?*anyopaque) callconv(.C) bool {
        const embedder: *FlutterEmbedder = @ptrCast(@alignCast(data));
        const result = c.eglMakeCurrent(
            embedder.open_gl.display,
            embedder.open_gl.surface,
            embedder.open_gl.surface,
            embedder.open_gl.context,
        );
        if (result == c.EGL_FALSE) return false;
        return true;
    }

    //TODO: Setup OpenGL context cleanup
    fn clear_current(data: ?*anyopaque) callconv(.C) bool {
        const embedder: *FlutterEmbedder = @ptrCast(@alignCast(data));
        const result = c.eglMakeCurrent(
            embedder.open_gl.display,
            embedder.open_gl.surface,
            embedder.open_gl.surface,
            embedder.open_gl.context,
        );

        if (result == c.EGL_FALSE) return false;

        c.glClear(c.GL_COLOR_BUFFER_BIT | c.GL_DEPTH_BUFFER_BIT);

        const err = c.glGetError();

        if (err != c.GL_NO_ERROR) return false;

        _ = c.eglSwapBuffers(
            embedder.open_gl.display,
            embedder.open_gl.surface,
        );

        return true;
    }

    //TODO: WTF is a swap buffer?
    fn present(data: ?*anyopaque) callconv(.C) bool {
        const embedder: *FlutterEmbedder = @ptrCast(@alignCast(data));
        const result = c.eglSwapBuffers(
            embedder.open_gl.display,
            embedder.open_gl.surface,
        );

        if (result == c.EGL_FALSE) {
            return false;
        }
        return true;
    }

    //Framebuffer Object (FBO).
    //I dont know what it's and in the example this just returns 0.
    fn fbo_callback(_: ?*anyopaque) callconv(.C) u32 {
        return 0;
    }

    // resource context setup. What in all hells is that?
    fn make_resource_current(data: ?*anyopaque) bool {
        const embedder: *FlutterEmbedder = @ptrCast(@alignCast(data));

        const resource: c.EGLContext = c.eglCreateContext(
            embedder.open_gl.display,
            embedder.open_gl.config,
            embedder.open_gl.context,
            embedder.open_gl.ctx_attrib,
        );

        if (resource == c.EGL_NO_CONTEXT) return false;

        return true;
    }

    fn gl_proc_resolver(_: ?*anyopaque, proc_name: [*c]const u8) callconv(.C) ?*anyopaque {
        const result: ?*anyopaque = @ptrCast(@constCast(
            c.eglGetProcAddress(proc_name),
        ));
        //IDK if I can just return result here;
        //Might be right but it feels wrong
        return result;
    }

    // Implement your surface presentation logic here
    fn surface_present(_: ?*anyopaque, _: *anyopaque) callconv(.C) bool {
        return true;
    }
};
