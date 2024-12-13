const std = @import("std");
const c = @import("../c_imports.zig").c;
const KeyboardManager = @import("manager.zig").KeyboardManager;

pub const wl_keyboard_listener = c.wl_keyboard_listener{
    .keymap = keyboard_keymap_handler,
    .enter = keyboard_enter_handler,
    .leave = keyboard_leave_handler,
    .key = keyboard_key_handler,
    .repeat_info = repeat_info,
    .modifiers = keyboard_modifiers_handler,
};

const MessageEvent = struct {
    type: []u8,
    keymap: []u8,
    toolkit: []u8,
    scanCode: u32,
    modifiers: u32,
    keyCode: u32,
    specifiedLogicalKey: u32,
    // metaState: u32,
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

    const e: *KeyboardManager = @ptrCast(@alignCast(data));
    if (e.xkb.fd == fd and e.xkb.size == size) {
        return;
    }

    const m: [*:0]const u8 = @ptrFromInt(
        std.os.linux.mmap(
            null,
            size,
            std.os.linux.PROT.READ,
            std.os.linux.MAP{
                .TYPE = std.os.linux.MAP_TYPE.SHARED,
            },
            fd,
            0,
        ),
    );

    defer _ = std.os.linux.munmap(m, size);

    const keymap: *c.struct_xkb_keymap = c.xkb_keymap_new_from_string(
        e.xkb.context,
        @ptrCast(m),
        c.XKB_KEYMAP_FORMAT_TEXT_V1,
        c.XKB_KEYMAP_COMPILE_NO_FLAGS,
    ) orelse {
        std.debug.print("XKB Keymap failed \n", .{});
        return;
    };

    defer c.xkb_keymap_unref(keymap);

    e.xkb.state = c.xkb_state_new(keymap) orelse {
        std.debug.print("XKB State failed \n", .{});
        return;
    };

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();

    var env = std.process.getEnvMap(alloc) catch {
        std.debug.print("Failed to create get environment variables", .{});
        return;
    };

    defer env.deinit();

    var locale = env.get("LC_ALL");
    if (locale == null) locale = env.get("LC_CTYPE");
    if (locale == null) locale = env.get("LANG");
    if (locale == null) locale = @constCast("C");

    const clocale = alloc.dupeZ(u8, locale.?) catch {
        std.debug.print("Failed to dupe the locale Env variable", .{});
        return;
    };

    defer alloc.free(clocale);
    const compose_table = c.xkb_compose_table_new_from_locale(
        e.xkb.context,
        @ptrCast(clocale),
        c.XKB_COMPOSE_COMPILE_NO_FLAGS,
    ) orelse {
        std.debug.print("Failed to create an XKB compose table", .{});
        return;
    };

    defer c.xkb_compose_table_unref(compose_table);
    e.xkb.compose = c.xkb_compose_state_new(
        compose_table,
        c.XKB_COMPOSE_COMPILE_NO_FLAGS,
    ) orelse {
        std.debug.print("Failed to create an XKB compose state", .{});
        return;
    };

    // GLFW does this, IDK why but, they save the indexes but IDK if these really change
    //TODO: Friendly reminder to check how to do this. We still have a bunch of keyboard bugs
    //
    //
    // _glfw.wl.xkb.controlIndex = xkb_keymap_mod_get_index(_glfw.wl.xkb.keymap, "Control");
    // _glfw.wl.xkb.altIndex = xkb_keymap_mod_get_index(_glfw.wl.xkb.keymap, "Mod1");
    // _glfw.wl.xkb.shiftIndex = xkb_keymap_mod_get_index(_glfw.wl.xkb.keymap, "Shift");
    // _glfw.wl.xkb.superIndex = xkb_keymap_mod_get_index(_glfw.wl.xkb.keymap, "Mod4");
    // _glfw.wl.xkb.capsLockIndex = xkb_keymap_mod_get_index(_glfw.wl.xkb.keymap, "Lock");
    // _glfw.wl.xkb.numLockIndex = xkb_keymap_mod_get_index(_glfw.wl.xkb.keymap, "Mod2");

    e.xkb.fd = fd;
    e.xkb.size = size;
}

///We do nothing in this call ???
fn keyboard_enter_handler(
    _: ?*anyopaque,
    _: ?*c.wl_keyboard,
    _: u32,
    _: ?*c.wl_surface,
    _: ?*c.wl_array,
) callconv(.C) void {}

fn keyboard_leave_handler(
    data: ?*anyopaque,
    _: ?*c.wl_keyboard,
    _: u32,
    _: ?*c.wl_surface,
) callconv(.C) void {
    const e: *KeyboardManager = @ptrCast(@alignCast(data));
    e.stop_repeat();
}

fn keyboard_key_handler(
    data: ?*anyopaque,
    _: ?*c.wl_keyboard,
    serial: u32, //serial
    _: u32, //time
    key: u32, //key
    state: u32, //key_state
) callconv(.C) void {
    const e: *KeyboardManager = @ptrCast(@alignCast(data));
    e.dispatch_key(serial, key, state);
}

fn keyboard_modifiers_handler(
    data: ?*anyopaque,
    _: ?*c.wl_keyboard,
    _: u32, //Serial
    depressed: u32,
    latched: u32,
    locked: u32,
    group: u32,
) callconv(.C) void {
    const e: *KeyboardManager = @ptrCast(@alignCast(data));
    _ = c.xkb_state_update_mask(
        e.xkb.state,
        depressed,
        latched,
        locked,
        0,
        0,
        group,
    );
}

pub fn repeat_info(
    _: ?*anyopaque,
    _: ?*c.wl_keyboard,
    _: i32,
    _: i32,
) callconv(.C) void {}
