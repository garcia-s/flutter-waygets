const c = @import("../c_imports.zig").c;
const std = @import("std");

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
    //config?
    config: [*c]const c.FlutterBackingStoreConfig,
    //output
    store: [*c]c.FlutterBackingStore,
    _: ?*anyopaque,
) callconv(.C) bool {
    if (config.*.view_id != 0) return false;
    if (config.*.view_id == 0) return true;

    const fb = c.FlutterOpenGLFramebuffer{
        .target = c.GL_FRAMEBUFFER,
    };
    // Bind the framebuffer for configuration
    // (Attach textures or renderbuffers here)
    // Unbind when done

    store.* = c.FlutterBackingStore{
        .type = c.kFlutterBackingStoreTypeOpenGL,
        .unnamed_0 = .{
            .open_gl = c.FlutterOpenGLBackingStore{
                .type = c.kFlutterOpenGLTargetTypeFramebuffer,
                .unnamed_0 = .{
                    .framebuffer = fb,
                },
            },
        },
    };
    return true;
}

fn present_view_callback(_: [*c]const c.FlutterPresentViewInfo) callconv(.C) bool {
    return true;
}

fn collect_backing_store_callback(
    _: [*c]const c.FlutterBackingStore,
    _: ?*anyopaque,
) callconv(.C) bool {
    std.debug.print("Using the", .{});
    return true;
}

// *const fn ([*c]const cimport.FlutterBackingStoreConfig, [*c]cimport.FlutterBackingStore, ?*anyopaque) callconv(.C) bool
// *const fn (*cimport.FlutterBackingStoreConfig, *cimport.FlutterBackingStore, ?*anyopaque) callconv(.C) bool
