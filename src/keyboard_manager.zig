const c = @import("c_imports.zig").c;
const std = @import("std");

pub const KeyboardManager = struct {
    focused: ?*c.struct_wl_surface = null,
    xkb: *XKBState = undefined,
    gpa: std.heap.GeneralPurposeAllocator(.{}) = std.heap.GeneralPurposeAllocator(.{}){},
    pub fn init(self: *KeyboardManager) !void {
        self.xkb = try self.gpa.allocator().create(XKBState);
        self.xkb.context = c.xkb_context_new(c.XKB_CONTEXT_NO_FLAGS);
        if (self.xkb.context == null) {
            return error.FailedTocreateKeyboardContext;
        }
    }

    pub fn destroy(self: *KeyboardManager) void {
        self.gpa.allocator().free(self.xkb);
        self.gpa.deinit();
    }
};

pub const XKBState = struct {
    fd: i32 = 0,
    size: u32 = 0,
    context: ?*c.struct_xkb_context = null,
    keymap: ?*c.struct_xkb_keymap = null,
    state: ?*c.struct_xkb_state = null,
};
