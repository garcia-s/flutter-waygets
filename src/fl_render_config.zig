const c = @import("c_imports.zig").c;
const WLEgl = @import("wl_egl.zig").WLEgl;
const std = @import("std");

pub fn create_renderer_config() c.FlutterOpenGLRendererConfig {
    return c.FlutterOpenGLRendererConfig{
        .struct_size = @sizeOf(c.FlutterOpenGLRendererConfig),
        .make_current = make_current,
        .present = present,
        .make_resource_current = make_resource_current,
        .clear_current = clear_current,
        .fbo_callback = fbo_callback,
        .gl_proc_resolver = gl_proc_resolver,
    };
}

pub fn make_current(data: ?*anyopaque) callconv(.C) bool {
    std.debug.print("Running make current\n", .{});
    const wlegl: *WLEgl = @ptrCast(@alignCast(data));

    const result = c.eglMakeCurrent(
        wlegl.display,
        wlegl.windows[0].surface,
        wlegl.windows[0].surface,
        wlegl.context,
    );

    if (result != c.EGL_TRUE) {
        std.debug.print("ERROR MAKING THE SURFACE CONTEXT CURRENT: {x}\n", .{c.eglGetError()});
        return false;
    }
    return true;
}

pub fn clear_current(data: ?*anyopaque) callconv(.C) bool {
    const wlegl: *WLEgl = @ptrCast(@alignCast(data));

    const result = c.eglMakeCurrent(
        wlegl.display,
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
    std.debug.print("Running present\n", .{});
    const wlegl: *WLEgl = @ptrCast(@alignCast(data));

    const result = c.eglSwapBuffers(
        wlegl.display,
        wlegl.windows[0].surface,
    );

    if (result != c.EGL_TRUE) {
        std.debug.print("Error in EGL: {x}", .{c.eglGetError()});
        return false;
    }

    return true;
}

pub fn fbo_callback(_: ?*anyopaque) callconv(.C) u32 {
    return 0;
}
// resource context setup.
pub fn make_resource_current(data: ?*anyopaque) callconv(.C) bool {
    const wlegl: *WLEgl = @ptrCast(@alignCast(data));
    std.debug.print("Running make resource {?}\n", .{wlegl.windows[0]});

    const result = c.eglMakeCurrent(
        wlegl.display,
        wlegl.windows[0].resource_surface,
        wlegl.windows[0].resource_surface,
        wlegl.resource_context,
    );

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
