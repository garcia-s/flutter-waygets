pub const c = @cImport({
    @cDefine("WL_EGL_PLATFORM", "1");
    @cInclude("wayland-egl.h");
    @cInclude("xkbcommon/xkbcommon.h");
    @cInclude("EGL/egl.h");
    @cInclude("EGL/eglext.h");
    @cInclude("GLES/gl.h");
    @cInclude("wayland-client.h");
    @cInclude("wlr-layer-shell-unstable-v1-client-protocol.h");
    @cInclude("flutter_embedder.h");
});
