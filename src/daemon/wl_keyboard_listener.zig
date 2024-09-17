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
    data: ?*anyopaque,
    _: ?*c.wl_keyboard,
    format: u32,
    //File descriptor??
    fd: i32,
    //Keymap size??
    size: u32,
) callconv(.C) void {
    //Not yet ready for other formats
    if (format != 1) return;

    const state: *InputState = @ptrCast(@alignCast(data));

    if (state.xkb.fd == fd and state.xkb.size == size) {
        return;
    }

    const m: [*:0]const u8 = @ptrFromInt(
        std.os.linux.mmap(null, size, std.os.linux.PROT.READ, std.os.linux.MAP{
            .TYPE = std.os.linux.MAP_TYPE.SHARED,
        }, fd, 0),
    );

    std.debug.print("What is bytes {s} \n", .{m});

    state.xkb.keymap = c.xkb_keymap_new_from_string(
        state.xkb.context,
        @ptrCast(m),
        c.XKB_KEYMAP_FORMAT_TEXT_V1,
        c.XKB_KEYMAP_COMPILE_NO_FLAGS,
    );

    if (state.xkb.keymap == null) {
        std.debug.print("XKB Keymap failed \n", .{});
        return;
    }
    //
    state.xkb.state = c.xkb_state_new(state.xkb.keymap);
    if (state.xkb.state == null) {
        //maybe cleanup?
        std.debug.print("XKB State failed \n", .{});
        return;
    }

    state.xkb.fd = fd;
    state.xkb.size = size;
}

fn keyboard_enter_handler(
    data: ?*anyopaque,
    _: ?*c.wl_keyboard,
    _: u32,
    surface: ?*c.wl_surface,
    _: ?*c.wl_array,
) callconv(.C) void {
    const state: *InputState = @ptrCast(@alignCast(data));
    state.keyboard_focused = surface.?;
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

    if (state.xkb.keymap == null or state.xkb.keymap == null or state.xkb.context == null) {
        return;
    }

    const engine = state.map.get(state.keyboard_focused.?) orelse {
        return;
    };

    //--------- Key pressed ----------
    var event = c.FlutterKeyEvent{
        // logical: u64 = @import("std").mem.zeroes(u64),
        // physical: u64 = @import("std").mem.zeroes(u64),
        // synthesized: bool = @import("std").mem.zeroes(bool),
        .struct_size = @sizeOf(c.FlutterKeyEvent),
        .timestamp = @floatFromInt(c.FlutterEngineGetCurrentTime()),
        .device_type = c.kFlutterKeyEventDeviceTypeKeyboard,
        .type = if (k_state == 1) c.kFlutterKeyEventTypeDown else c.kFlutterKeyEventTypeUp,
    };

    if (k_state == 1) {
        const sym = c.xkb_state_key_get_one_sym(state.xkb.state, key + 8);
        const utf = c.xkb_state_key_get_utf32(state.xkb.state, sym);
        event.physical = utf;
        event.logical = utf;
        event.character = @ptrCast(&utf);

        std.debug.print("What key is {d} {d}\n", .{ utf, sym });
    }

    const res = c.FlutterEngineSendKeyEvent(
        engine,
        &event,
        &key_callback,
        null,
    );

    if (res != c.kSuccess) {
        std.debug.print("Some error while sending the key\n", .{});
    }
}
fn key_callback(result: bool, _: ?*anyopaque) callconv(.C) void {
    std.debug.print("What key is {}\n", .{result});
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
