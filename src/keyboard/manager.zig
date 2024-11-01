const c = @import("../c_imports.zig").c;
const std = @import("std");
const TextInputClient = @import("../textinput/messages.zig").TextInputClient;
const EditingValue = @import("../textinput/channel.zig").EditingValue;
const XKBState = @import("./xkb.zig").XKBState;
const InputManager = @import("../textinput/manager.zig").InputManager;
const HWKeyboardManager = @import("../hw_keyboard/manager.zig").HWKeyboardManager;
const udev = @import("./udev.zig");

pub const KeyboardManager = struct {
    engine: *c.FlutterEngine = undefined,
    xkb: XKBState = XKBState{},
    input: InputManager = InputManager{},
    hw_keyboard: HWKeyboardManager = HWKeyboardManager{},
    event: KeyEvent = KeyEvent{},
    repeat: ?std.Thread = null,
    repeating: bool = false,

    pub fn init(self: *KeyboardManager, engine: *c.FlutterEngine) !void {
        self.engine = engine;
        self.xkb.context = c.xkb_context_new(
            c.XKB_CONTEXT_NO_FLAGS,
        );
        self.hw_keyboard.init(self.xkb);
        try self.input.init(&self.xkb);

        if (self.xkb.context == null) {
            return error.FailedTocreateKeyboardContext;
        }
    }
    pub fn dispatch_key(
        self: *KeyboardManager,
        serial: u32, //serial
        key: u32,
        state: u32,
    ) void {
        self.event.serial = serial;
        self.event.key = key;
        self.event.state = state;

        self.hw_keyboard.handle_input(
            self.event.key,
            self.event.state,
            self.engine.*,
        );
        switch (state) {
            1 => {
                self.input.handle_input(
                    self.event.key,
                    self.engine.*,
                );
            },
            0 => {},
            else => return,
        }
    }

    pub fn dispatch_repeat(self: *KeyboardManager) void {
        var serial = self.event.serial;
        while (self.repeating) {
            if (serial != self.event.serial) {
                serial = self.event.serial;
                std.time.sleep(std.time.ns_per_ms * 300);
                continue;
            }

            if (self.event.state == 1) {
                self.input.handle_input(
                    self.event.key,
                    self.engine.*,
                );
            }
            std.time.sleep(std.time.ns_per_ms * 40);
        }
    }

    pub fn repeat_loop(self: *KeyboardManager) void {
        self.repeating = true;
        self.repeat = std.Thread.spawn(
            .{},
            dispatch_repeat,
            .{self},
        ) catch return;
    }

    pub fn stop_repeat(self: *KeyboardManager) void {
        self.repeating = false;
        self.repeat.?.join();
        self.repeat = null;
    }
};

const KeyEvent = struct {
    serial: u32 = 0,
    key: u32 = 0,
    state: u32 = 0,
};
