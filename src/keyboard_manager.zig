const c = @import("c_imports.zig").c;
const std = @import("std");
const TextInputClient = @import("channels/textinput.zig").TextInputClient;
const EditingValue = @import("channels/textinput.zig").EditingValue;

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
    current_id: i64 = 0,
    current_client: ?TextInputClient = null,
    edit_state: ?EditingValue = null,
    key_buff: []u8 = undefined,
    json_buff: []u8 = undefined,
    message: c.FlutterPlatformMessage = c.FlutterPlatformMessage{
        .struct_size = @sizeOf(c.FlutterPlatformMessage),
    },
    event: c.FlutterKeyEvent = c.FlutterKeyEvent{
        .struct_size = @sizeOf(c.FlutterKeyEvent),
        .device_type = c.kFlutterKeyEventDeviceTypeKeyboard,
    },

    pub fn init(self: *KeyboardManager) !void {
        self.key_buff = self.gp.allocator().alloc(u8, 2) catch {
            return;
        };

        self.json_buff = self.gp.allocator().alloc(u8, 1024) catch {
            return;
        };
        self.xkb.context = c.xkb_context_new(c.XKB_CONTEXT_NO_FLAGS);
        if (self.xkb.context == null) {
            return error.FailedTocreateKeyboardContext;
        }
    }

    pub fn destroy(self: *KeyboardManager) !void {
        const alloc = self.gp.allocator();
        alloc.free(self.key_buff);
        if (self.edit_state) |e| alloc.free(e);
        if (self.current_client) |e| alloc.free(e);
    }
};
