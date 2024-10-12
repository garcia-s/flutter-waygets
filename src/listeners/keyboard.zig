const std = @import("std");
const c = @import("../c_imports.zig").c;
const FLEmbedder = @import("../embedder.zig").FLEmbedder;

pub const wl_keyboard_listener = c.wl_keyboard_listener{
    .keymap = keyboard_keymap_handler,
    .enter = keyboard_enter_handler,
    .leave = keyboard_leave_handler,
    .key = keyboard_key_handler,
    .modifiers = keyboard_modifiers_handler,
};

// Keyboard event handlers
fn keyboard_keymap_handler(
    data: ?*anyopaque,
    _: ?*c.wl_keyboard,
    format: u32,
    fd: i32,
    size: u32,
) callconv(.C) void {
    //We only know how to xkb for now
    if (format != 1) return;

    const e: *FLEmbedder = @ptrCast(@alignCast(data));
    if (e.keyboard.xkb.fd == fd and e.keyboard.xkb.size == size) {
        return;
    }
    const m: [*:0]const u8 = @ptrFromInt(
        std.os.linux.mmap(
            null,
            size,
            std.os.linux.PROT.READ,
            std.os.linux.MAP{ .TYPE = std.os.linux.MAP_TYPE.SHARED },
            fd,
            0,
        ),
    );

    e.keyboard.xkb.keymap = c.xkb_keymap_new_from_string(
        e.keyboard.xkb.context,
        @ptrCast(m),
        c.XKB_KEYMAP_FORMAT_TEXT_V1,
        c.XKB_KEYMAP_COMPILE_NO_FLAGS,
    );

    if (e.keyboard.xkb.keymap == null) {
        std.debug.print("XKB Keymap failed \n", .{});
        return;
    }
    //
    e.keyboard.xkb.state = c.xkb_state_new(e.keyboard.xkb.keymap);
    if (e.keyboard.xkb.state == null) {
        //maybe cleanup?
        std.debug.print("XKB State failed \n", .{});
        return;
    }

    e.keyboard.xkb.fd = fd;
    e.keyboard.xkb.size = size;
}

///We do nothing in this call ???
fn keyboard_enter_handler(
    _: ?*anyopaque,
    _: ?*c.wl_keyboard,
    _: u32,
    _: ?*c.wl_surface,
    _: ?*c.wl_array,
) callconv(.C) void {
    // const e: *FLEmbedder = @ptrCast(@alignCast(data));
    // e.focused = surface.?;
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
    _: u32, //serial
    _: u32, //time
    k: u32, //key
    state: u32, //key_state
) callconv(.C) void {
    // how to handle the damn keyboard,
    const e: *FLEmbedder = @ptrCast(@alignCast(data));

    if (e.keyboard.xkb.keymap == null or
        e.keyboard.xkb.state == null or
        e.keyboard.xkb.context == null) return;

    if (e.keyboard.edit_state != null)
        return e.keyboard.handleTextInput(e.engine, k, state);
}

///Keep for RawKeyboardEvent implementation
const MessageEvent = struct {
    type: []u8,
    keymap: []u8,
    toolkit: []u8,
    scanCode: u32,
    modifiers: u32,
    // code: []u8,
    // location: u32,
    keyCode: u32,

    specifiedLogicalKey: u32,
    // metaState: u32,
};

fn keyboard_modifiers_handler(
    data: ?*anyopaque,
    _: ?*c.wl_keyboard,
    _: u32, //Serial
    depressed: u32,
    latched: u32,
    locked: u32,
    group: u32,
) callconv(.C) void {
    const e: *FLEmbedder = @ptrCast(@alignCast(data));
    if (e.keyboard.xkb.keymap == null or
        e.keyboard.xkb.state == null or
        e.keyboard.xkb.context == null) return;

    _ = c.xkb_state_update_mask(
        e.keyboard.xkb.state,
        depressed,
        latched,
        locked,
        0,
        0,
        group,
    );
}
