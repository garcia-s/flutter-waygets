const c = @import("../c_imports.zig").c;
const std = @import("std");
const TextInputClient = @import("../channels/textinput.zig").TextInputClient;
const EditingValue = @import("../channels/textinput.zig").EditingValue;
const XKBState = @import("./xkb.zig").XKBState;
const udev = @import("./udev.zig");

pub const RawKeyboardManager = struct {
    event: c.FlutterKeyEvent = c.FlutterKeyEvent{
        .struct_size = @sizeOf(c.FlutterKeyEvent),
        .device_type = c.kFlutterKeyEventDeviceTypeKeyboard,
    },
};
