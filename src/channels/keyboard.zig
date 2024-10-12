const std = @import("std");
const c = @import("../c_imports.zig").c;
const MessageHandler = @import("handler.zig").MessageHandler;
const FLEmbedder = @import("../embedder.zig").FLEmbedder;

pub fn keyboard_channel_handler(
    message: []const u8,
    embedder: *FLEmbedder,
    handle: ?*const c.FlutterPlatformMessageResponseHandle,
) anyerror!void {
    const method = keyboard_channel.get(message) orelse {
        return error.NullMethodCall;
    };

    try method(message, embedder, handle);
}

const keyboard_channel = std.StaticStringMap(MessageHandler).initComptime(.{
    // .{ "\x07\x10getKeyboardState", get_keyboard_state },
});

pub fn get_keyboard_state(
    _: []const u8,
    embedder: *FLEmbedder,
    handle: ?*const c.FlutterPlatformMessageResponseHandle,
) anyerror!void {
    const data = "{}";
    _ = c.FlutterEngineSendPlatformMessageResponse(
        embedder.engine,
        handle,
        data,
        0,
    );
}
