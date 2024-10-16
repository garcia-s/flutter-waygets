const c = @import("../c_imports.zig").c;
const std = @import("std");
const TextInputClient = @import("../channels/textinput.zig").TextInputClient;
const EditingValue = @import("../channels/textinput.zig").EditingValue;
const udev = @import("./udev.zig");
const update_fmt =
    \\{{
    \\  "method":"TextInputClient.updateEditingState",
    \\  "args": [
    \\      {d}, 
    \\          {s}
    \\  ]
    \\}}
;

pub const XKBState = struct {
    fd: i32 = 0,
    size: u32 = 0,
    context: ?*c.struct_xkb_context = null,
    keymap: ?*c.struct_xkb_keymap = null,
    state: ?*c.struct_xkb_state = null,
};

pub const KeyboardManager = struct {
    gp: std.heap.GeneralPurposeAllocator(.{}) = std.heap.GeneralPurposeAllocator(.{}){},
    xkb: XKBState = XKBState{},
    current_id: i64 = 0,
    current_client: ?TextInputClient = null,
    edit_state: ?EditingValue = null,
    key_buff: []u8 = undefined,
    json_buff: []u8 = undefined,
    message: c.FlutterPlatformMessage = c.FlutterPlatformMessage{
        .struct_size = @sizeOf(c.FlutterPlatformMessage),
    },

    event: c.FlutterKeyEvent = c.FlutterKeyEvent{
        .struct_size = @sizeOf(c.FlutterKeyEvent),
        .device_type = c.kFlutterKeyEventDeviceTypeKeyboard,
    },

    pub fn init(self: *KeyboardManager) !void {
        self.key_buff = self.gp.allocator().alloc(u8, 2) catch {
            return;
        };

        self.json_buff = self.gp.allocator().alloc(u8, 1024) catch {
            return;
        };

        self.xkb.context = c.xkb_context_new(c.XKB_CONTEXT_NO_FLAGS);
        if (self.xkb.context == null) {
            return error.FailedTocreateKeyboardContext;
        }
    }

    pub fn destroy(self: *KeyboardManager) !void {
        const alloc = self.gp.allocator();
        alloc.free(self.key_buff);
        if (self.edit_state) |e| alloc.free(e);
        if (self.current_client) |e| alloc.free(e);
    }

    ///This function handles the keyboard whenever an input field is focused
    pub fn handleTextInput(
        self: *KeyboardManager,
        engine: c.FlutterEngine,
        key: u32,
        state: u32,
    ) void {
        if (state >= 1) return;
        if (key == udev.KEY_BACKSPACE) {
            std.debug.print("Key backspase\n", .{});
            const len = self.edit_state.?.text.len;
            if (len != 0)
                self.edit_state.?.text =
                    self.edit_state.?.text[0 .. len - 1];
        } else {
            const end = c.xkb_state_key_get_utf8(
                self.xkb.state,
                key + 8,
                self.key_buff.ptr,
                self.key_buff.len,
            );

            self.edit_state.?.text = std.fmt.allocPrint(
                self.gp.allocator(),
                "{s}{s}",
                .{
                    self.edit_state.?.text,
                    self.key_buff[0..@intCast(end)],
                },
            ) catch return;
        }

        self.edit_state.?.selectionBase =
            @intCast(self.edit_state.?.text.len);

        self.edit_state.?.selectionExtent =
            @intCast(self.edit_state.?.text.len);

        self.dispatch_input_event(engine);
    }

    fn dispatch_input_event(self: *KeyboardManager, engine: c.FlutterEngine) void {
        const json = std.json.stringifyAlloc(
            self.gp.allocator(),
            self.edit_state,
            .{},
        ) catch return;

        defer self.gp.allocator().free(json);

        const b = std.fmt.bufPrint(
            self.json_buff,
            update_fmt,
            .{ self.current_id, json },
        ) catch return;

        self.message.channel = @constCast("flutter/textinput");
        self.message.message = b.ptr;
        self.message.message_size = b.len;

        _ = c.FlutterEngineSendPlatformMessage(
            engine,
            &self.message,
        );
    }
};
