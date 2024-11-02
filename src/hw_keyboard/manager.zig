const c = @import("../c_imports.zig").c;
const std = @import("std");
const EditingValue = @import("../textinput/messages.zig").EditingValue;
const XKBState = @import("../keyboard/xkb.zig").XKBState;
const udev_to_hid = @import("../keyboard/udev_hid.zig").udev_to_hid;

pub const HWKeyboardManager = struct {
    xkb: *XKBState = undefined,
    event: c.FlutterKeyEvent = c.FlutterKeyEvent{
        .struct_size = @sizeOf(c.FlutterKeyEvent),
        .device_type = c.kFlutterKeyEventDeviceTypeKeyboard,
        // timestamp: f64 = @import("std").mem.zeroes(f64),
        // type: FlutterKeyEventType = @import("std").mem.zeroes(FlutterKeyEventType),
        // physical: u64 = @import("std").mem.zeroes(u64),
        // logical: u64 = @import("std").mem.zeroes(u64),
        // character: [*c]const u8 = @import("std").mem.zeroes([*c]const u8),
        // synthesized: bool = @import("std").mem.zeroes(bool),
        // device_type: FlutterKeyEventDeviceType = @import("std").mem.zeroes(FlutterKeyEventDeviceType),
    },

    pub fn init(self: *HWKeyboardManager, xkb: *XKBState) void {
        self.xkb = xkb;
    }

    pub fn handle_input(
        self: *HWKeyboardManager,
        key: u32,
        state: u32,
        engine: *c.FlutterEngine,
    ) void {
        self.event.type = switch (state) {
            0 => c.kFlutterKeyEventTypeUp,
            1 => c.kFlutterKeyEventTypeDown,
            2 => c.kFlutterKeyEventTypeRepeat,
            else => 0,
        };

        // self.event.timestamp = c.FlutterEngineGetCurrentTime();
        self.event.physical = @intCast(udev_to_hid(key));
        self.event.logical = c.xkb_state_key_get_one_sym(
            self.xkb.state,
            key + 8,
        );

        _ = c.FlutterEngineSendKeyEvent(
            engine.*,
            &self.event,
            null,
            null,
        );
    }
};
