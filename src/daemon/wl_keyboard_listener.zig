const std = @import("std");
const c = @import("../c_imports.zig").c;

pub const keyboard_listener = c.wl_keyboard_listener{
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
    _: i32,
    _: u32,
) callconv(.C) void {}

fn keyboard_enter_handler(
    _: ?*anyopaque,
    _: ?*c.wl_keyboard,
    _: u32,
    _: ?*c.wl_surface,
    _: ?*c.wl_array,
) callconv(.C) void {
    std.debug.print("Keyboard focus entered\n", .{});
}

fn keyboard_leave_handler(
    _: ?*anyopaque,
    _: ?*c.wl_keyboard,
    _: u32,
    _: ?*c.wl_surface,
) callconv(.C) void {
    std.debug.print("Keyboard focus left\n", .{});
}

fn keyboard_key_handler(
    _: ?*anyopaque,
    _: ?*c.wl_keyboard,
    _: u32,
    _: u32,
    _: u32,
    _: u32,
) callconv(.C) void {}

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
