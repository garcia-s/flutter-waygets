const std = @import("std");
const c = @import("../c_imports.zig").c;
const MessageHandler = @import("../channels/handler.zig").MessageHandler;
const FLEmbedder = @import("../embedder.zig").FLEmbedder;
const TextInputClient = @import("messages.zig").TextInputClient;
const EditingValue = @import("messages.zig").EditingValue;

const TextInputHandler = *const fn (
    *const ?std.json.Value,
    *FLEmbedder,
    ?*const c.FlutterPlatformMessageResponseHandle,
) anyerror!void;

const textinput_channel = std.StaticStringMap(TextInputHandler).initComptime(.{
    .{ "TextInput.setEditingState", set_editing_state },
    .{ "TextInput.setClient", set_client },
    // TextInput.setEditableSizeAndTransform
    // TextInput.setMarkedTextRect
    // TextInput.setStyle
    // TextInput.setEditingState
    // TextInput.show
    // TextInput.requestAutofill
    // TextInput.setCaretRect
});

pub fn textinput_channel_handler(
    message: []const u8,
    embedder: *FLEmbedder,
    handle: ?*const c.FlutterPlatformMessageResponseHandle,
) anyerror!void {
    var gp = std.heap.GeneralPurposeAllocator(.{}){};

    // std.debug.print("Message: {s}", .{message});
    const p = std.json.parseFromSlice(
        std.json.Value,
        gp.allocator(),
        message,
        .{ .ignore_unknown_fields = true },
    ) catch return;

    defer p.deinit();
    const m = p.value.object.get("method") orelse {
        return send_empty_response(embedder, handle);
    };

    const args = p.value.object.get("args");

    const method = textinput_channel.get(m.string) orelse {
        const data = "";
        _ = c.FlutterEngineSendPlatformMessageResponse(
            embedder.engine,
            handle,
            data.ptr,
            data.len,
        );
        return;
    };
    //
    try method(&args, embedder, handle);
}

pub fn set_editing_state(
    args: *const ?std.json.Value,
    embedder: *FLEmbedder,
    handle: ?*const c.FlutterPlatformMessageResponseHandle,
) anyerror!void {
    const a = args.* orelse {
        return send_empty_response(embedder, handle);
    };

    const p = std.json.parseFromValue(
        EditingValue,
        embedder.keyboard.input.gp.allocator(),
        a,
        .{ .ignore_unknown_fields = true },
    ) catch return send_empty_response(
        embedder,
        handle,
    );

    embedder.keyboard.input.editing_value = p.value;
    return send_empty_response(embedder, handle);
}

pub fn set_client(
    args: *const ?std.json.Value,
    embedder: *FLEmbedder,
    handle: ?*const c.FlutterPlatformMessageResponseHandle,
) anyerror!void {
    const a = args.* orelse {
        return send_empty_response(embedder, handle);
    };

    embedder.keyboard.input.current_id = a.array.items[0].integer;

    std.debug.print("Before Parsing \n", .{});
    const p = std.json.parseFromValue(
        TextInputClient,
        embedder.keyboard.input.gp.allocator(),
        a.array.items[1],
        .{ .ignore_unknown_fields = true },
    ) catch |e| {
        std.debug.print("Error parsing, {?}\n", .{e});
        return send_empty_response(
            embedder,
            handle,
        );
    };

    std.debug.print("Test can we pass the parser \n", .{});
    embedder.keyboard.input.text_client = p.value;

    //TODO: Don't know if this is the way to respond
    return send_empty_response(
        embedder,
        handle,
    );
}

pub fn send_empty_response(
    embedder: *FLEmbedder,
    handle: ?*const c.FlutterPlatformMessageResponseHandle,
) void {
    const data = "[0]";
    _ = c.FlutterEngineSendPlatformMessageResponse(
        embedder.engine,
        handle,
        data.ptr,
        data.len,
    );
}
