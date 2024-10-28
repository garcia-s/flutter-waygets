const c = @import("../c_imports.zig").c;
const std = @import("std");
const XKBState = @import("../keyboard/xkb.zig").XKBState;
const udev = @import("../keyboard/udev.zig");
const TextInputClient = @import("messages.zig").TextInputClient;
const EditingValue = @import("messages.zig").EditingValue;

const update = "TextInputClient.updateEditingState";
const performAction = "TextInputClient.performAction";

const update_fmt =
    \\{{
    \\  "method":"{s}",
    \\  "args": [
    \\      {d}, 
    \\      {s}
    \\  ]
    \\}}
;

pub const InputManager = struct {
    gp: std.heap.GeneralPurposeAllocator(.{}) =
        std.heap.GeneralPurposeAllocator(.{}){},

    current_id: i64 = 0,
    current_key: ?u32 = null,
    key_buff: []u8 = undefined,
    json_buff: []u8 = undefined,
    text_client: ?TextInputClient = null,
    editing_value: ?EditingValue = null,
    xkb: *XKBState = undefined,
    message: c.FlutterPlatformMessage = c.FlutterPlatformMessage{
        .struct_size = @sizeOf(c.FlutterPlatformMessage),
        .channel = @constCast("flutter/textinput"),
    },

    pub fn init(self: *InputManager, xkb: *XKBState) !void {
        self.xkb = xkb;
        self.key_buff = self.gp.allocator().alloc(u8, 2) catch {
            return;
        };

        self.json_buff = self.gp.allocator().alloc(u8, 1024) catch {
            return;
        };
    }

    pub fn handle_input(
        self: *InputManager,
        key: u32,
        engine: c.FlutterEngine,
    ) void {
        if (self.text_client == null) return;

        switch (key) {
            //Delete
            udev.KEY_BACKSPACE => self.handle_backspace(engine),
            //Submit
            udev.KEY_ENTER => self.handle_submit(engine),
            udev.KEY_1...udev.KEY_MINUS,
            //Characters
            udev.KEY_Q...udev.KEY_RIGHTBRACE,
            udev.KEY_A...udev.KEY_GRAVE,
            udev.KEY_BACKSLASH...udev.KEY_SLASH,
            udev.KEY_SPACE,
            => self.handle_char(engine, key),

            //TODO: MISSING COPY, PASTE AND OTHER GOODIES
            else => {
                return;
            },
        }
    }

    fn handle_char(
        self: *InputManager,
        engine: c.FlutterEngine,
        key: u32,
    ) void {
        const end = c.xkb_state_key_get_utf8(
            self.xkb.state,
            key + 8,
            self.key_buff.ptr,
            self.key_buff.len,
        );

        self.editing_value.?.text = std.fmt.allocPrint(
            self.gp.allocator(),
            "{s}{s}",
            .{
                self.editing_value.?.text,
                self.key_buff[0..@intCast(end)],
            },
        ) catch return;

        self.editing_value.?.selectionBase =
            @intCast(self.editing_value.?.text.len);

        self.editing_value.?.selectionExtent =
            @intCast(self.editing_value.?.text.len);

        self.dispatch_input_event(engine);
    }

    ///This function handles the keyboard whenever an input field is focused
    fn dispatch_input_event(self: *InputManager, engine: c.FlutterEngine) void {
        const json = std.json.stringifyAlloc(
            self.gp.allocator(),
            self.editing_value,
            .{},
        ) catch return;

        defer self.gp.allocator().free(json);

        const b = std.fmt.bufPrint(
            self.json_buff,
            update_fmt,
            .{
                update,
                self.current_id,
                json,
            },
        ) catch return;

        self.message.message = b.ptr;
        self.message.message_size = b.len;

        _ = c.FlutterEngineSendPlatformMessage(
            engine,
            &self.message,
        );
    }

    pub fn handle_backspace(self: *InputManager, engine: c.FlutterEngine) void {
        var edit = &(self.editing_value orelse return);
        const len = edit.text.len;
        if (len != 0) {
            edit.text = edit.text[0 .. len - 1];
            self.dispatch_input_event(engine);
            return;
        }
        //TODO: maybe hook it up to a system sound efect
    }

    pub fn handle_submit(self: *InputManager, engine: c.FlutterEngine) void {
        //TODO: figure out how to handle submit
        const a = std.fmt.allocPrint(self.gp.allocator(),
            \\"{s}"
        , .{
            self.text_client.?.inputAction,
        }) catch return;

        defer self.gp.allocator().free(a);

        const b = std.fmt.bufPrint(
            self.json_buff,
            update_fmt,
            .{
                performAction,
                self.current_id,
                a,
            },
        ) catch return;

        self.message.message = b.ptr;
        self.message.message_size = b.len;

        _ = c.FlutterEngineSendPlatformMessage(
            engine,
            &self.message,
        );
    }
};
