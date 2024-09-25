const c = @import("../c_imports.zig").c;
const std = @import("std");

const ctx_attrib: [*c]c.EGLint = @constCast(&[_]c.EGLint{
    c.EGL_CONTEXT_CLIENT_VERSION, 2,
    c.EGL_NONE,
});

pub const FLRenderer = struct {
    context: c.EGLContext = undefined,
    resource_context: c.EGLContext = undefined,

    pub fn init(self: *FLRenderer, config: c.EGLConfig) !void {
        self.context = c.eglCreateContext(
            self.display,
            config,
            null,
            @constCast(ctx_attrib),
        );

        if (self.context == c.EGL_NO_CONTEXT) {
            std.debug.print("Failed to create the EGL context\n", .{});
            return error.EglContextFaield;
        }

        self.resource_context = c.eglCreateContext(
            self.display,
            config,
            self.context,
            @constCast(ctx_attrib),
        );

        if (self.resource_context == c.EGL_NO_CONTEXT) {
            std.debug.print("Failed to create the EGL resource_context\n", .{});
            return error.EglResourceContextFailed;
        }
    }
};
