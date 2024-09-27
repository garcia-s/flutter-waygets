const std = @import("std");
const c = @import("c_imports.zig").c;

const FLEmbedder = @import("embedder.zig").FLEmbedder;
pub fn platform_message_callback(
    message: [*c]const c.FlutterPlatformMessage,
    _: ?*anyopaque,
) callconv(.C) void {
    // const embedder: *FLEmbedder = @ptrCast(@alignCast(data));
    var gp = std.heap.GeneralPurposeAllocator(.{}){};
    //handle each
    const str: [:0]const u8 = std.mem.span(message.*.channel);
    if (std.mem.eql(u8, str, "flutter/platform")) {
        std.debug.print("Message: {s}\n", .{message.*.message});
        const json: [:0]const u8 = std.mem.span(message.*.message);

        //Parse the YA- SON
        const parsed = std.json.parseFromSlice(
            PlatformMethodDescription,
            gp.allocator(),
            json,
            .{},
        ) catch return;

        defer parsed.deinit();
        handle_platform_method(parsed.value);
    }
}

pub fn handle_platform_method(_: *PlatformMethodDescription) void {}

const PlatformMethodDescription = struct {
    method: []u8,
    args: ?[]u8,
};
