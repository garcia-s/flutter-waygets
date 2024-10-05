const std = @import("std");
const c = @import("../c_imports.zig").c;
const MessageHandler = @import("handler.zig").MessageHandler;
const FLEmbedder = @import("../embedder.zig").FLEmbedder;

const TextInputClient = struct {
    viewId: i64,
    // obscureText: bool,
    // autocorrect: bool,
    // smartDashesType: u32,
    // smartQuotesType: u32,
    // enableSuggestions: bool,
    // enableInteractiveSelection: bool,
    // actionLabel: []u8,
    // inputAction: []u8,
    // textCapitalization: []u8,
    // keyboardAppearance: []u8,
    // enableIMEPersonalizedLearning: bool,
    // contentCommitMimeTypes: [][]u8,
    // enableDeltaModel: bool,
};

const InputType = struct {
    signed: []u8,
    decimal: []u8,
    readOnly: bool,
};

const EditingValue = struct {
    text: []u8,
    selectionBase: i32,
    selectionExtent: i32,
    selectionAffinity: []u8,
    selectionIsDirectional: false,
    composingBase: i32,
    composingExtent: i32,
};

const AutoFill = struct {
    uniqueIdentifier: []u8,
    hints: [][]u8,
    editingValue: EditingValue,
};

const textinput_channel = std.StaticStringMap(MessageHandler).initComptime(.{
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
        struct { method: []u8 },
        gp.allocator(),
        message,
        .{ .ignore_unknown_fields = true },
    ) catch {
        std.debug.print("Could not decode the method\n", .{});
        return;
    };
    std.debug.print("P channel: {s}\n", .{p.value.method});
    const method = textinput_channel.get(p.value.method) orelse {
        const data = "";
        _ = c.FlutterEngineSendPlatformMessageResponse(
            embedder.engine,
            handle,
            data.ptr,
            data.len,
        );
        return;
    };

    try method(message, embedder, handle);
}

pub fn set_editing_state(
    _: []const u8,
    embedder: *FLEmbedder,
    handle: ?*const c.FlutterPlatformMessageResponseHandle,
) anyerror!void {
    const data = "[{\"text\": \"hello\", \"selectionBase\":0}]";
    _ = c.FlutterEngineSendPlatformMessageResponse(
        embedder.engine,
        handle,
        data.ptr,
        data.len,
    );
}

const SetClientArgs = struct {
    args: [1]i64,
};
pub fn set_client(
    message: []const u8,
    embedder: *FLEmbedder,
    handle: ?*const c.FlutterPlatformMessageResponseHandle,
) anyerror!void {
    var gp = std.heap.GeneralPurposeAllocator(.{}){};

    const val = std.json.parseFromSlice(
        std.json.Value,
        gp.allocator(),
        message,
        .{ .ignore_unknown_fields = true },
    ) catch {
        std.debug.print("Failed to parse Setclient data\n", .{});
    };
    std.debug.print("Val: {?}\n", .{val.value});

    const data = "[0]";
    _ = c.FlutterEngineSendPlatformMessageResponse(
        embedder.engine,
        handle,
        data.ptr,
        data.len,
    );
}
