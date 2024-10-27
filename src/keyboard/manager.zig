const c = @import("../c_imports.zig").c;
const std = @import("std");
const TextInputClient = @import("../channels/textinput.zig").TextInputClient;
const EditingValue = @import("../channels/textinput.zig").EditingValue;
const XKBState = @import("./xkb.zig").XKBState;
const InputManager = @import("input.zig").InputManager;
const udev = @import("./udev.zig");

pub const KeyboardManager = struct {
    engine: *c.FlutterEngine = undefined,
    xkb: XKBState = XKBState{},
    input: InputManager = InputManager{},
    udev_key: ?u32 = null,
    xkb_key: ?u32 = null,

    pub fn init(self: *KeyboardManager, engine: *c.FlutterEngine) !void {
        self.engine = engine;
        self.xkb.context = c.xkb_context_new(c.XKB_CONTEXT_NO_FLAGS);
        try self.input.init();

        if (self.xkb.context == null) {
            return error.FailedTocreateKeyboardContext;
        }
    }

    pub fn destroy(_: *KeyboardManager) !void {}

    pub fn handle_key(self: *KeyboardManager) !void {
        std.debug.print("Handling text_client {?} \n", .{self.input.text_client});
        if (self.input.text_client != null) {
            self.handle_input();
            return;
        }
        self.handle_raw_keyboard();
    }

    pub fn handle_input(self: *KeyboardManager) void {
        std.debug.print("Key pressed: {?}\n", .{self.udev_key});
        const key = self.udev_key orelse return;
        switch (key) {
            udev.KEY_BACKSPACE => {
                self.input.handle_backspace(self.engine.*);
            },
            udev.KEY_ENTER => {
                std.debug.print("Enter key pressed \n", .{});
                self.input.handle_submit(self.engine.*);
            },
            else => {},
        }
        if (self.udev_key == udev.KEY_BACKSPACE) {}
    }
    pub fn handle_raw_keyboard(_: *KeyboardManager) void {}
};
