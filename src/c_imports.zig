pub const c = @cImport({
    @cInclude("wayland-egl.h");
    @cInclude("GL/gl.h");
    @cInclude("GL/glu.h");
    @cInclude("wayland-egl.h");
    @cInclude("EGL/egl.h");
    @cInclude("EGL/eglplatform.h");
    @cInclude("EGL/eglext.h");
    @cInclude("wayland-client.h");
    @cInclude("flutter_embedder.h");
    @cInclude("wlr-layer-shell-unstable-v1-client-protocol.h");
});
