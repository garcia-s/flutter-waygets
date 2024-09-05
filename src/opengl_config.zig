const std = @import("std");
const c = @cImport({
    @cInclude("flutter_embedder.h");
    @cInclude("EGL/egl.h");
    @cInclude("EGL/eglext.h");
});

//TODO: OpenGL context setup
///The parameter here is a pointer to what we passed as "user_data"
///which for now is the FlutterEmbedder instance
pub fn CreateFlutterOpenGLRenderConfig() c.FlutterOpenGLRendererConfig {
    return .{
        .struct_size = @sizeOf(c.FlutterOpenGLRendererConfig),
        .make_current = make_current,
        .clear_current = clear_current,
        .present = present,
        .fbo_callback = fbo_callback,
        .gl_proc_resolver = gl_proc_resolver,
    };
}

