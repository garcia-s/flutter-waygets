const std = @import("std");
const c = @import("../c_imports.zig").c;
const InputState = @import("input_state.zig").InputState;

pub const wl_keyboard_listener = c.wl_keyboard_listener{
    .keymap = keyboard_keymap_handler,
    .enter = keyboard_enter_handler,
    .leave = keyboard_leave_handler,
    .key = keyboard_key_handler,
    .modifiers = keyboard_modifiers_handler,
};

// Keyboard event handlers
fn keyboard_keymap_handler(
    _: ?*anyopaque,
    _: ?*c.wl_keyboard,
    _: u32,
    //File descriptor??
    _: i32,
    //Keymap size??
    _: u32,
) callconv(.C) void {
    std.debug.print("Keyboard map ran\n", .{});
}

fn keyboard_enter_handler(
    data: ?*anyopaque,
    _: ?*c.wl_keyboard,
    _: u32,
    surface: ?*c.wl_surface,
    _: ?*c.wl_array,
) callconv(.C) void {
    const state: *InputState = @ptrCast(@alignCast(data));
    state.mouse_focused = surface.?;
}

fn keyboard_leave_handler(
    _: ?*anyopaque,
    _: ?*c.wl_keyboard,
    _: u32,
    _: ?*c.wl_surface,
) callconv(.C) void {}

fn keyboard_key_handler(
    data: ?*anyopaque,
    _: ?*c.wl_keyboard,
    //serial
    _: u32,
    //time
    _: u32,
    //key
    key: u32,
    //key_state
    k_state: u32,
) callconv(.C) void {
    const state: *InputState = @ptrCast(@alignCast(data));
    if (state.mouse_focused == null) return;
    const engine = state.map.get(state.mouse_focused.?) orelse {
        return;
    };

    std.debug.print("Key info: {d} {d}\n", .{ key, k_state });
    const event = c.FlutterKeyEvent{
        .struct_size = @sizeOf(c.FlutterKeyEvent),
        .timestamp = @floatFromInt(c.FlutterEngineGetCurrentTime()),
        .logical = key,
        .device_type = c.kFlutterKeyEventDeviceTypeKeyboard,
        // logical: u64 = @import("std").mem.zeroes(u64),
        .type = if (k_state == 1) c.kFlutterKeyEventTypeDown else c.kFlutterKeyEventTypeUp,
        // physical: u64 = @import("std").mem.zeroes(u64),
        // synthesized: bool = @import("std").mem.zeroes(bool),
        // device_type: FlutterKeyEventDeviceType = @import("std").mem.zeroes(FlutterKeyEventDeviceType),

    };

    const res = c.FlutterEngineSendKeyEvent(
        engine,
        &event,
        null,
        null,
    );

    if (res != c.kSuccess) {
        std.debug.print("Some error while sending the key\n", .{});
    }
}

fn keyboard_modifiers_handler(
    _: ?*anyopaque,
    _: ?*c.wl_keyboard,
    _: u32,
    _: u32,
    _: u32,
    _: u32,
    _: u32,
) callconv(.C) void {
    std.debug.print("Keyboard modifiers changed\n", .{});
}
