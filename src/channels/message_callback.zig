const std = @import("std");
const WindowConfig = @import("../window/window.zig").WindowConfig;
const c = @import("../c_imports.zig").c;
const FLEmbedder = @import("../embedder.zig").FLEmbedder;
const MessageHandler = @import("handler.zig").MessageHandler;
const platform_channel_handler = @import("platform.zig").platform_channel_handler;
const keyboard_channel_handler = @import("keyboard.zig").keyboard_channel_handler;
const textinput_channel_handler = @import("textinput.zig").textinput_channel_handler;

const channel_map = std.StaticStringMap(MessageHandler).initComptime(.{
    .{ "flutter/platform", platform_channel_handler },
    .{ "flutter/keyboard", keyboard_channel_handler },
    .{ "flutter/textinput", textinput_channel_handler },
});

pub fn platform_message_callback(
    message: [*c]const c.FlutterPlatformMessage,
    data: ?*anyopaque,
) callconv(.C) void {
    const embedder: *FLEmbedder = @ptrCast(@alignCast(data));
    const ch: []const u8 = std.mem.span(message.*.channel);
    const handler = channel_map.get(ch);

    const msg: []const u8 = message.*.message[0..message.*.message_size];
    if (handler) |h| {
        h(msg, embedder, message.*.response_handle) catch {
            _ = c.FlutterEngineSendPlatformMessageResponse(
                embedder.engine,
                message.*.response_handle,
                null,
                0,
            );
            return;
        };
        return;
    }

    _ = c.FlutterEngineSendPlatformMessageResponse(
        embedder.engine,
        message.*.response_handle,
        null,
        0,
    );
}
