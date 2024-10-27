const c = @import("../c_imports.zig").c;
const std = @import("std");
const XKBState = @import("./xkb.zig").XKBState;
const udev = @import("./udev.zig");
const TextInputClient = @import("../messages/textinput.zig").TextInputClient;
const EditingValue = @import("../messages/textinput.zig").EditingValue;

const update = "TextInputClient.updateEditingState";

const update_fmt =
    \\{{
    \\  "method":"{s}",
    \\  "args": [
    \\      {d}, 
    \\          {s}
    \\  ]
    \\}}
;

pub const InputManager = struct {
    gp: std.heap.GeneralPurposeAllocator(.{}) =
        std.heap.GeneralPurposeAllocator(.{}){},
    key_buff: []u8 = undefined,
    json_buff: []u8 = undefined,
    text_client: ?TextInputClient = null,
    message: c.FlutterPlatformMessage = c.FlutterPlatformMessage{
        .struct_size = @sizeOf(c.FlutterPlatformMessage),
        .channel = @constCast("flutter/textinput"),
    },

    pub fn init(self: *InputManager) !void {
        self.key_buff = self.gp.allocator().alloc(u8, 2) catch {
            return;
        };

        self.json_buff = self.gp.allocator().alloc(u8, 1024) catch {
            return;
        };
    }

    pub fn handle_text_input(
        _: *InputManager,
        _: c.FlutterEngine,
        _: ?u32,
    ) void {

        //     const end = c.xkb_state_key_get_utf8(
        //         self.xkb.state,
        //         key + 8,
        //         self.key_buff.ptr,
        //         self.key_buff.len,
        //     );

        // if (key == udev.KEY_BACKSPACE) {
        //     const len = self.edit_state.?.text.len;
        //     if (len != 0)
        //         self.edit_state.?.text =
        //             self.edit_state.?.text[0 .. len - 1];
        // } else {

        //
        //     self.edit_state.?.text = std.fmt.allocPrint(
        //         self.gp.allocator(),
        //         "{s}{s}",
        //         .{
        //             self.edit_state.?.text,
        //             self.key_buff[0..@intCast(end)],
        //         },
        //     ) catch return;
        // }
        //
        // self.edit_state.?.selectionBase =
        //     @intCast(self.edit_state.?.text.len);
        //
        // self.edit_state.?.selectionExtent =
        //     @intCast(self.edit_state.?.text.len);
        //
        // self.dispatch_input_event(engine);
    }

    ///This function handles the keyboard whenever an input field is focused
    fn dispatch_input_event(_: *InputManager, _: c.FlutterEngine) void {
        // const json = std.json.stringifyAlloc(
        //     self.gp.allocator(),
        //     self.edit_state,
        //     .{},
        // ) catch return;
        //
        // defer self.gp.allocator().free(json);
        //
        // const b = std.fmt.bufPrint(
        //     self.json_buff,
        //     update_fmt,
        //     .{
        //         1,
        //         json,
        //     },
        // ) catch return;
        //
        // self.message.message = b.ptr;
        // self.message.message_size = b.len;
        //
        // _ = c.FlutterEngineSendPlatformMessage(
        //     engine,
        //     &self.message,
        // );
    }

    pub fn handle_backspace(self: *InputManager, engine: c.FlutterEngine) void {
        var edit = &self.text_client.?.EditingValue;
        const len = edit.text.len;
        if (len != 0) {
            edit.text = edit.text[0 .. len - 1];
            self.dispatch_input_event(engine);
            return;
        }
        //TODO: maybe hook it up to a system sound efect
    }

    pub fn handle_submit(self: *InputManager, _: c.FlutterEngine) void {
        //TODO: figure out how to handle submit
        const b = std.fmt.bufPrint(
            self.json_buff,
            update_fmt,
            .{
                self.text_client.?.inputAction,
                1,
                "{}",
            },
        ) catch return;

        self.message.message = b.ptr;
        self.message.message_size = b.len;
    }
};
