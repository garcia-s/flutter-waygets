const std = @import("std");
const c = @import("../c_imports.zig");

const keyboard_listener = c.wl_keyboard_listener{
    .keymap = keyboard_keymap_handler,
    .enter = keyboard_enter_handler,
    .leave = keyboard_leave_handler,
    .key = keyboard_key_handler,
    .modifiers = keyboard_modifiers_handler,
};

// Keyboard event handlers
fn keyboard_keymap_handler(
    keyboard: *c.wl_keyboard,
    format: u32,
    fd: i32,
    size: u32,
    data: *anyopaque,
) void {}

fn keyboard_enter_handler(
    keyboard: *c.wl_keyboard,
    serial: u32,
    surface: *c.wl_surface,
    keys: [*:0]const u32,
    data: *anyopaque,
) void {
    std.debug.print("Keyboard focus entered\n", .{});
}

fn keyboard_leave_handler(
    keyboard: *c.wl_keyboard,
    surface: *c.wl_surface,
    serial: u32,
    data: *anyopaque,
) void {
    std.debug.print("Keyboard focus left\n", .{});
}

fn keyboard_key_handler(
    keyboard: *c.wl_keyboard,
    serial: u32,
    time: u32,
    key: u32,
    state: u32,
    data: *anyopaque,
) void {
    const action = if (state == c.WL_KEYBOARD_KEY_STATE_PRESSED) "pressed" else "released";
    std.debug.print("Key {} {}\n", .{ key, action });
}

fn keyboard_modifiers_handler(
    keyboard: *c.wl_keyboard,
    serial: u32,
    mods_depressed: u32,
    mods_latched: u32,
    mods_locked: u32,
    group: u32,
    data: *anyopaque,
) void {
    std.debug.print("Keyboard modifiers changed\n", .{});
}
