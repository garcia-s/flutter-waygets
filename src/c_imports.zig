pub const c = @cImport({
    @cDefine("WL_EGL_PLATFORM", "1");
    @cInclude("wayland-egl.h");
    @cInclude("xkbcommon/xkbcommon.h");
    @cInclude("EGL/egl.h");
    @cInclude("EGL/eglext.h");
    @cInclude("GL/glu.h");
    @cInclude("GL/glext.h");
    @cInclude("GL/gl.h");
    @cInclude("GLFW/glfw3.h");
    @cInclude("GLFW/glfw3native.h");
    @cInclude("wayland-client.h");
    @cInclude("wlr-layer-shell-unstable-v1-client-protocol.h");
    @cInclude("flutter_embedder.h");
});
