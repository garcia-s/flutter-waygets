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
fn keyboard_enter_handler(_: ?*anyopaque, _: ?*c.wl_keyboard, _: u32, _: ?*c.wl_surface, _: ?*c.wl_array) callconv(.C) void {
    // const e: *FLEmbedder = @ptrCast(@alignCast(data));
    // e.focused = surface.?;
}

fn keyboard_leave_handler(_: ?*anyopaque, _: ?*c.wl_keyboard, _: u32, _: ?*c.wl_surface) callconv(.C) void {}

fn keyboard_key_handler(
    data: ?*anyopaque,
    _: ?*c.wl_keyboard,
    //serial
    _: u32,
    //time
    _: u32,
    //key
    _: u32,
    //key_state
    _: u32,
) callconv(.C) void {
    const e: *FLEmbedder = @ptrCast(@alignCast(data));

    if (e.keyboard.xkb.keymap == null or
        e.keyboard.xkb.keymap == null or
        e.keyboard.xkb.context == null) return;

    e.keyboard.event.character = "a";
    e.keyboard.event.physical = 0x00070004;
    e.keyboard.event.logical = 0x00000000061;
    e.keyboard.event.timestamp = @as(f64, @floatFromInt(c.FlutterEngineGetCurrentTime(e.engine))) / 1e3;
    e.keyboard.event.type = c.kFlutterKeyEventTypeDown;
    e.keyboard.event.synthesized = true;

    var res = c.FlutterEngineSendKeyEvent(
        e.engine,
        @ptrCast(&e.keyboard.event),
        key_callback,
        null,
    );

    if (res != c.kSuccess) {
        std.debug.print("Some error while sending the key\n", .{});
    }

    //--------- Key pressed ----------
    // static constexpr char kTypeValueUp[] = "keyup";
    // static constexpr char kTypeValueDown[] = "keydown";
    //
    // static constexpr char kKeyCodeKey[] = "keyCode";
    // static constexpr char kScanCodeKey[] = "scanCode";
    // static constexpr char kModifiersKey[] = "modifiers";
    // static constexpr char kSpecifiedLogicalKey[] = "specifiedLogicalKey";
    // static constexpr char kUnicodeScalarValuesKey[] = "unicodeScalarValues";
    var gp = std.heap.GeneralPurposeAllocator(.{}){};
    var m = MessageEvent{
        .type = @constCast("keydown"),
        .keymap = @constCast("linux"),
        .toolkit = @constCast("glfw"),
        .modifiers = 0,
        .scanCode = 0x04,
        .keyCode = 0x97,
        .specifiedLogicalKey = 0x00000000061,
    };

    const b = std.json.stringifyAlloc(gp.allocator(), m, .{}) catch {
        std.debug.print("Cannot create buffer for message", .{});
        return;
    };
    defer gp.allocator().free(b);

    var event = c.FlutterPlatformMessage{
        .struct_size = @sizeOf(c.FlutterPlatformMessage),
        .channel = "flutter/keyevent",
        .message_size = b.len,
        .message = b.ptr,
    };

    _ = c.FlutterPlatformMessageCreateResponseHandle(
        e.engine,
        platformResponse,
        null,
        @ptrCast(&event.response_handle),
    );
    res = c.FlutterEngineSendPlatformMessage(
        e.engine,
        &event,
    );

    if (res != c.kSuccess) {
        std.debug.print("Some error while sending the key\n", .{});
    }

    e.keyboard.event.type = c.kFlutterKeyEventTypeUp;
    e.keyboard.event.timestamp = @as(f64, @floatFromInt(c.FlutterEngineGetCurrentTime(e.engine))) / 1e3;

    _ = c.FlutterEngineSendKeyEvent(
        e.engine,
        &e.keyboard.event,
        key_callback,
        null,
    );
    m.type = @constCast("keyup");
    const b2 = std.json.stringifyAlloc(gp.allocator(), m, .{}) catch {
        std.debug.print("Cannot create buffer for message", .{});
        return;
    };
    defer gp.allocator().free(b2);
    event.message = b2.ptr;
    event.message_size = b2.len;

    _ = c.FlutterEngineSendPlatformMessage(
        e.engine,
        &event,
    );
}

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

pub fn key_callback(result: bool, _: ?*anyopaque) callconv(.C) void {
    std.debug.print("What key result {}\n", .{result});
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

fn platformResponse(res: [*c]const u8, _: usize, _: ?*anyopaque) callconv(.C) void {
    std.debug.print("Response arrived: {s}\n", .{res});
}
