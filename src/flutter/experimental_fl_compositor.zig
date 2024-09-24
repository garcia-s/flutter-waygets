const c = @import("../c_imports.zig").c;
const std = @import("std");
pub const stubData = struct {
    fbo: *c_uint = undefined,
};

pub fn create_flutter_compositor() *const c.FlutterCompositor {
    return &c.FlutterCompositor{
        .struct_size = @sizeOf(c.FlutterCompositor),
        .create_backing_store_callback = create_backing_store_callback,
        .collect_backing_store_callback = collect_backing_store_callback,
        .avoid_backing_store_cache = false,
        .present_view_callback = present_view_callback,
    };
}

fn create_backing_store_callback(
    //Here we receive the size of of the render surface
    //And we receive the view_id too
    conf: [*c]const c.FlutterBackingStoreConfig,
    //output
    store: [*c]c.FlutterBackingStore,
    _: ?*anyopaque,
) callconv(.C) bool {
    const glGenFrameBuffers: c.PFNGLGENFRAMEBUFFERSPROC = @ptrCast(
        c.eglGetProcAddress("glGenFrameBuffers"),
    );

    const glCheckFramebufferStatus: c.PFNGLCHECKFRAMEBUFFERSTATUSPROC = @ptrCast(
        c.eglGetProcAddress("glCheckFramebufferStatus"),
    );

    const glBindFramebuffer: c.PFNGLBINDFRAMEBUFFERPROC = @ptrCast(
        c.eglGetProcAddress("glGenFrameBuffers"),
    );

    const glFramebufferTexture2D: c.PFNGLFRAMEBUFFERTEXTURE2DPROC =
        @ptrCast(c.eglGetProcAddress("glFramebufferTexture2D"));

    const glDrawBuffers: c.PFNGLDRAWBUFFERSPROC =
        @ptrCast(c.eglGetProcAddress("glDrawBuffers"));

    var name: c_uint = undefined;
    glGenFrameBuffers.?(1, &name);
    glBindFramebuffer.?(c.GL_FRAMEBUFFER, name);

    const fb = c.FlutterOpenGLFramebuffer{
        .target = c.GL_TEXTURE_2D,
        .name = name,
    };

    var current: c_int = undefined;
    c.glGetIntegerv(c.GL_FRAMEBUFFER_BINDING, &current);
    std.debug.print("CURRENT FB {d}\n", .{current});
    // c.glViewport(
    //     0,
    //     0,
    //     @intFromFloat(conf.*.size.width),
    //     @intFromFloat(conf.*.size.height),
    // );

    var tex: c_uint = 0;
    c.glGenTextures(1, @ptrCast(&tex));

    c.glBindTexture(c.GL_TEXTURE_2D, tex);
    c.glTexImage2D(
        c.GL_TEXTURE_2D,
        0,
        c.GL_BGRA_EXT,
        @intFromFloat(conf.*.size.width),
        @intFromFloat(conf.*.size.height),
        0,
        c.GL_BGRA_EXT,
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

    glFramebufferTexture2D.?(
        c.GL_FRAMEBUFFER,
        c.GL_COLOR_ATTACHMENT0,
        c.GL_TEXTURE_2D,
        tex,
        0,
    );

    const err = c.glGetError();
    if (err != c.GL_NO_ERROR) {
        std.debug.print("Error in framebufferTexture2D!!!: {d}\n", .{err});
    }
    const drawBuffers: [1]c.GLenum = .{c.GL_COLOR_ATTACHMENT0};
    glDrawBuffers.?(1, &drawBuffers);
    std.debug.print("Tex: {d}\n", .{tex});

    if (glCheckFramebufferStatus.?(c.GL_FRAMEBUFFER) != c.GL_FRAMEBUFFER_COMPLETE) {
        std.debug.print("------------Framebuffer is incomplete------------\n", .{});
        return false;
    }

    glBindFramebuffer.?(c.GL_FRAMEBUFFER, 0);
    c.glBindTexture(c.GL_TEXTURE_2D, 0);

    store.*.struct_size = @sizeOf(c.FlutterBackingStore);
    store.*.type = c.kFlutterBackingStoreTypeOpenGL;
    store.*.did_update = false;
    store.*.unnamed_0.open_gl = c.FlutterOpenGLBackingStore{};
    store.*.unnamed_0.open_gl.type = c.kFlutterOpenGLTargetTypeFramebuffer;
    store.*.unnamed_0.open_gl.unnamed_0.framebuffer = fb;

    return true;
}

fn present_view_callback(info: [*c]const c.FlutterPresentViewInfo) callconv(.C) bool {
    var current: c_int = 0;
    c.glGetIntegerv(c.GL_FRAMEBUFFER_BINDING, &current);
    std.debug.print("CURRENT FB 2 {d}\n", .{current});

    const glBindFramebuffer: c.PFNGLBINDFRAMEBUFFERPROC = @ptrCast(
        c.eglGetProcAddress("glBindFramebuffer"),
    );

    const glCheckFramebufferStatus: c.PFNGLCHECKFRAMEBUFFERSTATUSPROC = @ptrCast(
        c.eglGetProcAddress("glCheckFramebufferStatus"),
    );

    for (0..info.*.layers_count) |i| {
        std.debug.print("Ran\n", .{});
        const layer = info.*.layers[i];
        const store: [*c]const c.FlutterBackingStore = layer.*.unnamed_0.backing_store.?;
        const fb = store.*.unnamed_0.open_gl.unnamed_0.framebuffer;

        glBindFramebuffer.?(c.GL_FRAMEBUFFER, fb.name);
        c.glViewport(0, 0, 1920, 400);

        c.glClearColor(1, 1, 1, 1);
        c.glClear(c.GL_COLOR_BUFFER_BIT);

        if (glCheckFramebufferStatus.?(c.GL_FRAMEBUFFER) != c.GL_FRAMEBUFFER_COMPLETE) {
            std.debug.print("------------Framebuffer is incomplete------------\n", .{});
            return false;
        }

        if (store == null) {
            continue;
        }

        if (layer.*.type == c.kFlutterLayerContentTypeBackingStore) {}
        //Unbind
        glBindFramebuffer.?(c.GL_FRAMEBUFFER, 0);
    }

    return true;
}

fn collect_backing_store_callback(
    _: [*c]const c.FlutterBackingStore,
    _: ?*anyopaque,
) callconv(.C) bool {
    std.debug.print("Using the", .{});
    return true;
}

// glGenFramebuffers(1, &framebuffer.name);
//
// // Bind the framebuffer for configuration
// glBindFramebuffer(GL_FRAMEBUFFER, framebuffer.name);
//
// // (Attach textures or renderbuffers here)
//
// glBindFramebuffer(GL_FRAMEBUFFER, 0); // Unbind when done
//
// return framebuffer;
