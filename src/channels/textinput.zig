const std = @import("std");
const c = @import("../c_imports.zig").c;
const MessageHandler = @import("handler.zig").MessageHandler;
const FLEmbedder = @import("../embedder.zig").FLEmbedder;

const TextInputHandler = *const fn (
    *const ?std.json.Value,
    *FLEmbedder,
    ?*const c.FlutterPlatformMessageResponseHandle,
) anyerror!void;

pub const TextInputClient = struct {
    viewId: i64,
    obscureText: bool,
    autocorrect: bool,
    smartDashesType: u32,
    smartQuotesType: u32,
    enableSuggestions: bool,
    enableInteractiveSelection: bool,
    actionLabel: ?[]u8,
    inputAction: []u8,
    textCapitalization: []u8,
    keyboardAppearance: []u8,
    enableIMEPersonalizedLearning: bool,
    contentCommitMimeTypes: [][]u8,
    enableDeltaModel: bool,
    inputType: InputType,
    EditingValue: EditingValue,
    autofill: AutoFill,
};

const InputType = struct {
    //FIXME: I don't know if this is the correct type
    signed: ?[]u8,
    decimal: ?[]u8,
    readOnly: bool,
};

pub const EditingValue = struct {
    text: []u8,
    selectionBase: i32,
    selectionExtent: i32,
    selectionAffinity: []u8,
    selectionIsDirectional: bool,
    composingBase: i32,
    composingExtent: i32,
};

const AutoFill = struct {
    uniqueIdentifier: []u8,
    hints: [][]u8,
    editingValue: EditingValue,
};

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
        embedder.keyboard.gp.allocator(),
        a,
        .{ .ignore_unknown_fields = true },
    ) catch return send_empty_response(embedder, handle);

    embedder.keyboard.edit_state = p.value;
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

    embedder.keyboard.current_id = a.array.items[0].integer;

    const p = std.json.parseFromValue(
        TextInputClient,
        embedder.keyboard.gp.allocator(),
        a.array.items[1],
        .{ .ignore_unknown_fields = true },
    ) catch return send_empty_response(
        embedder,
        handle,
    );

    embedder.keyboard.current_client = p.value;

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
