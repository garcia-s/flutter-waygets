const std = @import("std");
const FLView = @import("fl_view.zig").FLView;
const c = @import("c_imports.zig").c;
const FLEmbedder = @import("embedder.zig").FLEmbedder;

const PlatformMethodDescription = struct {
    method: []u8,
    args: ?[]u8,
};

pub fn platform_message_callback(
    message: [*c]const c.FlutterPlatformMessage,
    _: ?*anyopaque,
) callconv(.C) void {
    // const embedder: *FLEmbedder = @ptrCast(@alignCast(data));
    var gp = std.heap.GeneralPurposeAllocator(.{}){};

    const str: [:0]const u8 = std.mem.span(message.*.channel);

    std.debug.print("Found the channel {s}\n", .{message.*.channel});
    const channel = channel_map.get(str) orelse return;

    //Get the string
    const json: [:0]const u8 = std.mem.span(message.*.message);
    std.debug.print("Message is: {s}\n", .{message.*.message});

    //Parse the method,
    const parsed = std.json.parseFromSlice(
        PlatformMethodDescription,
        gp.allocator(),
        json,
        .{},
    ) catch |err| {
        std.debug.print("Error {?}\n", .{err});
        return;
    };

    defer parsed.deinit();
    const method = channel.get(parsed.value.method) orelse {
        return;
    };

    method(parsed.value.args) catch {
        return;
    };
}

const channel_map = std.StaticStringMap(
    std.StaticStringMap(*const fn (?[]u8) anyerror!void),
).initComptime(
    .{
        .{ "flutter/platform", platform_channels },
    },
);

const platform_channels = std.StaticStringMap(
    *const fn (?[]u8) anyerror!void,
).initComptime(
    .{
        .{ "add_view", add_view_handler },
    },
);

fn add_view_handler(_: ?[]u8) !void {
    std.debug.print("Hello from add_view", .{});
}
