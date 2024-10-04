const c = @import("c_imports.zig").c;
const FLEmbedder = @import("embedder.zig").FLEmbedder;
const FLWindow = @import("fl_window.zig").FLWindow;
const std = @import("std");

pub fn create_renderer_config() c.FlutterOpenGLRendererConfig {
    return c.FlutterOpenGLRendererConfig{
        .struct_size = @sizeOf(c.FlutterOpenGLRendererConfig),
        .present = present,
        .make_current = make_current,
        .make_resource_current = make_resource_current,
        .clear_current = clear_current,
        .fbo_callback = fbo_callback,
        .gl_proc_resolver = gl_proc_resolver,
        .fbo_reset_after_present = true,
    };
}

pub fn make_current(data: ?*anyopaque) callconv(.C) bool {
    const embedder: *FLEmbedder = @ptrCast(@alignCast(data));
    const window: ?FLWindow = embedder.windows.get(0);
    var surface: c.EGLSurface = c.EGL_NO_SURFACE;

    if (window != null) {
        surface = window.?.surface;
    }

    const result = c.eglMakeCurrent(
        embedder.egl.display,
        surface,
        surface,
        embedder.egl.context,
    );

    if (result != c.EGL_TRUE) {
        std.debug.print("ERROR MAKING THE SURFACE CONTEXT CURRENT: {x}\n", .{c.eglGetError()});
        return false;
    }
    return true;
}

pub fn clear_current(data: ?*anyopaque) callconv(.C) bool {
    const embedder: *FLEmbedder = @ptrCast(@alignCast(data));

    const result = c.eglMakeCurrent(
        embedder.egl.display,
        c.EGL_NO_SURFACE,
        c.EGL_NO_SURFACE,
        c.EGL_NO_CONTEXT,
    );

    if (result != c.EGL_TRUE) {
        std.debug.print("Error in EGL: {x}\n", .{c.eglGetError()});
        return true;
    }
    return true;
}

pub fn present(data: ?*anyopaque) callconv(.C) bool {
    const embedder: *FLEmbedder = @ptrCast(@alignCast(data));
    const window: FLWindow = embedder.windows.get(0) orelse {
        return false;
    };
    _ = c.eglSwapBuffers(
        embedder.egl.display,
        window.surface,
    );

    return true;
}

pub fn fbo_callback(_: ?*anyopaque) callconv(.C) u32 {
    return 0;
}
// resource context setup.
pub fn make_resource_current(data: ?*anyopaque) callconv(.C) bool {
    const embedder: *FLEmbedder = @ptrCast(@alignCast(data));

    const result = c.eglMakeCurrent(
        embedder.egl.display,
        c.EGL_NO_SURFACE,
        c.EGL_NO_SURFACE,
        embedder.egl.resource_context,
    );

    std.debug.print("Error?: {x}\n", .{c.eglGetError()});
    if (result == c.EGL_FALSE) {
        std.debug.print("Error MAKING RESOURCE CURRENT: {X}\n", .{c.eglGetError()});
        return false;
    }

    return true;
}

pub fn gl_proc_resolver(_: ?*anyopaque, proc_name: [*c]const u8) callconv(.C) ?*anyopaque {
    const result: ?*anyopaque = @ptrCast(@constCast(
        c.eglGetProcAddress(proc_name),
    ));

    if (result != null) return result;
    std.debug.print("Error resolving process name {x}", .{c.eglGetError()});
    return null;
}
