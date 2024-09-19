pub const c = @cImport({
    @cDefine("WL_EGL_PLATFORM", "1");
    @cInclude("wayland-egl.h");
    @cInclude("xkbcommon/xkbcommon.h");
    @cInclude("GLFW/glfw3.h");
    @cInclude("EGL/egl.h");
    @cInclude("EGL/eglext.h");
    @cInclude("wayland-client.h");
    @cInclude("wlr-layer-shell-unstable-v1-client-protocol.h");
    @cInclude("flutter_embedder.h");
});
