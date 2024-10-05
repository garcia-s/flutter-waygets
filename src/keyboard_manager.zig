const c = @import("c_imports.zig").c;
const std = @import("std");
const TextInputClient = @import("channels/textinput.zig").TextInputClient;

pub const XKBState = struct {
    fd: i32 = 0,
    size: u32 = 0,
    context: ?*c.struct_xkb_context = null,
    keymap: ?*c.struct_xkb_keymap = null,
    state: ?*c.struct_xkb_state = null,
};

pub const KeyboardManager = struct {
    gp: std.heap.GeneralPurposeAllocator(.{}) = std.heap.GeneralPurposeAllocator(.{}){},
    xkb: XKBState = XKBState{},
    inputs: std.AutoHashMap([]u8, TextInputClient) = undefined,
    event: c.FlutterKeyEvent = c.FlutterKeyEvent{
        .struct_size = @sizeOf(c.FlutterKeyEvent),
        .device_type = c.kFlutterKeyEventDeviceTypeKeyboard,
        .timestamp = 0,
        .physical = 0,
        .logical = 0,
        .character = 0,
        .synthesized = false,
    },

    pub fn init(self: *KeyboardManager) !void {
        self.inputs = std.AutoHashMap([]u8, TextInputClient)
            .init(self.gp.allocator());
        self.xkb.context = c.xkb_context_new(c.XKB_CONTEXT_NO_FLAGS);
        if (self.xkb.context == null) {
            return error.FailedTocreateKeyboardContext;
        }
    }
};
