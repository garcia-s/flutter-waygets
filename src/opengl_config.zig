const std = @import("std");
const c = @cImport({
    @cInclude("flutter_embedder.h");
    @cInclude("EGL/egl.h");
    @cInclude("EGL/eglext.h");
});

//TODO: OpenGL context setup
///The parameter here is a pointer to what we passed as "user_data"
///which for now is the FlutterEmbedder instance
pub fn CreateFlutterOpenGLRenderConfig() *c.FlutterOpenGLRendererConfig {
    return c.FlutterOpenGLRendererConfig{
        .struct_size = @sizeOf(c.FlutterOpenGLRendererConfig),
        .make_current = make_current,
    };
}

fn make_current(_: ?*anyopaque) callconv(.C) bool {
    const display = c.eglGetDisplay(c.EGL_DEFAULT_DISPLAY);
    if (display == c.EGL_NO_DISPLAY) {
        sdt.debug.print("Failed to get the EGL display\n", .{});
    }
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
fn make_resource_current(_: ?*anyopaque) callconv(.C) bool {
    return true;
}

// fn gl_proc_resolver(_: [*c]const u8) callconv(.C) ?*const u8 {
//     // Your GL proc resolver here
//     return null;
// }

// Implement your surface presentation logic here
fn surface_present(_: ?*anyopaque, _: *anyopaque) callconv(.C) bool {
    return true;
}
