const c = @import("../c_imports.zig").c;
const FLWindow = @import("fl_window.zig").FLWindow;
const std = @import("std");
pub const stubData = struct {
    fbo: *c_uint = undefined,
};

pub fn create_flutter_compositor(window: *FLWindow) c.FlutterCompositor {
    return c.FlutterCompositor{
        .struct_size = @sizeOf(c.FlutterCompositor),
        .create_backing_store_callback = @ptrCast(&create_backing_store_callback),
        .present_view_callback = @ptrCast(&present_view_callback),
        .collect_backing_store_callback = @ptrCast(&collect_backing_store_callback),
        .avoid_backing_store_cache = false,
        .user_data = @ptrCast(window),
    };
}

pub fn create_backing_store_callback(
    conf: [*c]const c.FlutterBackingStoreConfig,
    store: [*c]c.FlutterBackingStore,
    _: ?*anyopaque,
) callconv(.C) bool {
    const glGenFramebuffers: c.PFNGLGENFRAMEBUFFERSPROC = @ptrCast(
        c.eglGetProcAddress("glGenFramebuffers"),
    );

    const glCheckFramebufferStatus: c.PFNGLCHECKFRAMEBUFFERSTATUSPROC = @ptrCast(
        c.eglGetProcAddress("glCheckFramebufferStatus"),
    );

    const glBindFramebuffer: c.PFNGLBINDFRAMEBUFFERPROC = @ptrCast(
        c.eglGetProcAddress("glBindFramebuffer"),
    );

    const glFramebufferTexture2D: c.PFNGLFRAMEBUFFERTEXTURE2DPROC =
        @ptrCast(c.eglGetProcAddress("glFramebufferTexture2D"));

    const glDrawBuffers: c.PFNGLDRAWBUFFERSPROC =
        @ptrCast(c.eglGetProcAddress("glDrawBuffers"));

    // const glDrawBuffers: c.PFNGLDRAWBUFFERSPROC = @ptrCast(
    //     c.eglGetProcAddress("glDrawBuffers"),
    // );

    var name: c_uint = undefined;
    glGenFramebuffers.?(1, &name);
    glBindFramebuffer.?(c.GL_FRAMEBUFFER, @intCast(name));

    var tex: c_uint = 0;
    c.glGenTextures(1, @ptrCast(&tex));
    c.glBindTexture(c.GL_TEXTURE_2D, tex);

    c.glTexImage2D(
        c.GL_TEXTURE_2D,
        0,
        c.GL_RGBA8,
        @intFromFloat(conf.*.size.width),
        @intFromFloat(conf.*.size.height),
        0,
        c.GL_RGBA,
        c.GL_UNSIGNED_BYTE,
        null,
    );

    c.glTexParameteri(
        c.GL_TEXTURE_2D,
        c.GL_TEXTURE_MIN_FILTER,
        c.GL_LINEAR,
    );

    c.glTexParameteri(
        c.GL_TEXTURE_2D,
        c.GL_TEXTURE_MAG_FILTER,
        c.GL_LINEAR,
    );
    //Why is this?
    c.glBindTexture(c.GL_TEXTURE_2D, 0);

    glFramebufferTexture2D.?(
        c.GL_FRAMEBUFFER,
        c.GL_COLOR_ATTACHMENT0,
        c.GL_TEXTURE_2D,
        tex,
        0,
    );

    const drawBuffers: [1]c.GLenum = .{c.GL_COLOR_ATTACHMENT0};
    glDrawBuffers.?(1, &drawBuffers);

    if (glCheckFramebufferStatus.?(c.GL_FRAMEBUFFER) != c.GL_FRAMEBUFFER_COMPLETE) {
        std.debug.print("------------Framebuffer is incomplete------------\n", .{});
        return false;
    }

    const fb = c.FlutterOpenGLFramebuffer{
        //Did I just spent 30 years trying to configure an incorrectly named parameter, well yes,
        //this is not the "Target" this is the god damn format
        .target = c.GL_RGBA8,
        .name = name,
        .destruction_callback = destroy_callback,
    };

    store.*.struct_size = @sizeOf(c.FlutterBackingStore);
    store.*.type = c.kFlutterBackingStoreTypeOpenGL;
    store.*.did_update = false;
    store.*.unnamed_0.open_gl = c.FlutterOpenGLBackingStore{};
    store.*.unnamed_0.open_gl.type = c.kFlutterOpenGLTargetTypeFramebuffer;
    store.*.unnamed_0.open_gl.unnamed_0.framebuffer = fb;

    glBindFramebuffer.?(c.GL_FRAMEBUFFER, 0);
    return true;
}

pub fn destroy_callback(_: ?*anyopaque) callconv(.C) void {}

pub fn present_view_callback(info: [*c]const c.FlutterPresentViewInfo) callconv(.C) bool {
    const glBindFramebuffer: c.PFNGLBINDFRAMEBUFFERPROC = @ptrCast(
        c.eglGetProcAddress("glBindFramebuffer"),
    );

    const glBlitFramebuffer: c.PFNGLBLITFRAMEBUFFERPROC = @ptrCast(
        c.eglGetProcAddress("glBlitFramebuffer"),
    );
    for (0..info.*.layers_count) |i| {
        const layer = info.*.layers[i];
        const backs: [*c]const c.FlutterBackingStore = layer.*.unnamed_0.backing_store.?;
        const fb = backs.*.unnamed_0.open_gl.unnamed_0.framebuffer;

        if (backs == null) {
            continue;
        }

        glBindFramebuffer.?(c.GL_READ_FRAMEBUFFER, fb.name);
        glBindFramebuffer.?(c.GL_DRAW_FRAMEBUFFER, 0);
        c.glViewport(
            0,
            0,
            @intFromFloat(layer.*.size.width),
            @intFromFloat(layer.*.size.height),
        );
        glBlitFramebuffer.?(
            0,
            0,
            @intFromFloat(layer.*.size.width),
            @intFromFloat(layer.*.size.height),
            0,
            0,
            @intFromFloat(layer.*.size.width),
            @intFromFloat(layer.*.size.height),
            c.GL_COLOR_BUFFER_BIT, // Copy the color buffer
            c.GL_NEAREST, // Nearest filtering
        );

        glBindFramebuffer.?(c.GL_FRAMEBUFFER, 0);
        const window: *FLWindow = @ptrCast(@alignCast(info.*.user_data));
        _ = c.eglSwapBuffers(window.display, window.surface);
    }

    return true;
}

pub fn collect_backing_store_callback(
    _: [*c]const c.FlutterBackingStore,
    _: ?*anyopaque,
) callconv(.C) bool {
    return true;
}
