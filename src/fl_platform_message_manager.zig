const std = @import("std");
const c = @import("c_imports.zig").c;

pub fn platform_message_callback(message: [*c]const c.FlutterPlatformMessage, _: ?*anyopaque) callconv(.C) void {
    std.debug.print("Platform message received {s}\n", .{message.*.message});
}
