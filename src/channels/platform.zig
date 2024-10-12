const std = @import("std");
const c = @import("../c_imports.zig").c;
const FLEmbedder = @import("../embedder.zig").FLEmbedder;
const FLView = @import("../fl_view.zig").FLView;
const MessageHandler = @import("handler.zig").MessageHandler;

const platform_channel = std.StaticStringMap(MessageHandler).initComptime(.{
    .{ "add_view", add_view_handler },
});

pub fn platform_channel_handler(
    str: []const u8,
    embedder: *FLEmbedder,
    handle: ?*const c.FlutterPlatformMessageResponseHandle,
) !void {
    var gp = std.heap.GeneralPurposeAllocator(.{}){};

    const p = try std.json.parseFromSlice(
        struct { method: []u8 },
        gp.allocator(),
        str,
        .{ .ignore_unknown_fields = true },
    );
    const method = platform_channel.get(p.value.method) orelse {
        return error.NullMethodCall;
    };

    try method(str, embedder, handle);
}

fn add_view_handler(
    str: []const u8,
    embedder: *FLEmbedder,
    handle: ?*const c.FlutterPlatformMessageResponseHandle,
) !void {
    var gp = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gp.allocator();

    const p = std.json.parseFromSlice(
        struct { method: []u8, args: [1]FLView },
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
        .{embedder.window_count - 1},
    );

    defer alloc.free(data);

    _ = c.FlutterEngineSendPlatformMessageResponse(
        embedder.engine,
        handle,
        data,
        data.len,
    );
}

fn remove_view_handler(
    str: []const u8,
    embedder: *FLEmbedder,
    handle: ?*const c.FlutterPlatformMessageResponseHandle,
) !void {
    var gp = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gp.allocator();

    const p = std.json.parseFromSlice(struct {
        method: []u8,
        args: [1]FLView,
    }, alloc, str, .{ .ignore_unknown_fields = true }) catch |err| {
        std.debug.print("Error: {?}", .{err});
        return;
    };

    try embedder.egl.windows.remove();

    defer p.deinit();
    const data = try std.fmt.allocPrintZ(
        alloc,
        "[{{\"view_id\": {d} }}]",
        .{embedder.window_count - 1},
    );

    defer alloc.free(data);

    _ = c.FlutterEngineSendPlatformMessageResponse(
        embedder.engine,
        handle,
        data,
        data.len,
    );
}
