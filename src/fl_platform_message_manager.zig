const std = @import("std");
const FLView = @import("fl_view.zig").FLView;
const c = @import("c_imports.zig").c;
const FLEmbedder = @import("embedder.zig").FLEmbedder;

const MessageHandler = *const fn (
    [:0]const u8,
    *FLEmbedder,
    ?*const c.FlutterPlatformMessageResponseHandle,
) anyerror!void;

const channel_map = std.StaticStringMap(std.StaticStringMap(MessageHandler)).initComptime(.{
    .{ "flutter/platform", platform_channels },
});

const platform_channels = std.StaticStringMap(MessageHandler).initComptime(.{
    .{ "add_view", add_view_handler },
});

fn add_view_handler(
    str: [:0]const u8,
    embedder: *FLEmbedder,
    handle: ?*const c.FlutterPlatformMessageResponseHandle,
) !void {
    var gp = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gp.allocator();

    const p = std.json.parseFromSlice(
        struct {
            method: []u8,
            args: [1]FLView,
        },
        alloc,
        str,
        .{ .ignore_unknown_fields = true },
    ) catch |err| {
        std.debug.print("Error: {?}", .{err});
        return;
    };

    try embedder.add_view(p.value.args[0]);
    defer p.deinit();
    const data = try std.fmt.allocPrintZ(
        alloc,
        "[{{\"view_id\": {d} }}]",
        .{embedder.egl.window_count - 1},
    );

    defer alloc.free(data);

    _ = c.FlutterEngineSendPlatformMessageResponse(
        embedder.engine,
        handle,
        data,
        data.len,
    );
}

pub fn platform_message_callback(
    message: [*c]const c.FlutterPlatformMessage,
    data: ?*anyopaque,
) callconv(.C) void {
    const embedder: *FLEmbedder = @ptrCast(@alignCast(data));
    var gp = std.heap.GeneralPurposeAllocator(.{}){};
    const str: [:0]const u8 = std.mem.span(message.*.channel);

    const channel = channel_map.get(str) orelse {
        _ = c.FlutterEngineSendPlatformMessageResponse(
            embedder.engine,
            message.*.response_handle,
            null,
            0,
        );
        return;
    };

    //Get the string
    const jstr: [:0]const u8 = std.mem.span(message.*.message);

    //Parse the method
    const p = std.json.parseFromSlice(
        struct { method: []u8 },
        gp.allocator(),
        jstr,
        .{ .ignore_unknown_fields = true },
    ) catch {
        _ = c.FlutterEngineSendPlatformMessageResponse(
            embedder.engine,
            message.*.response_handle,
            null,
            0,
        );
        return;
    };

    defer p.deinit();
    const method = channel.get(p.value.method) orelse {
        _ = c.FlutterEngineSendPlatformMessageResponse(
            embedder.engine,
            message.*.response_handle,
            null,
            0,
        );
        return;
    };

    method(jstr, embedder, message.*.response_handle) catch {
        _ = c.FlutterEngineSendPlatformMessageResponse(
            embedder.engine,
            message.*.response_handle,
            null,
            0,
        );
        return;
    };
}
