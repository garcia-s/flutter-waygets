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
    wl_input: ?*c.struct_zwp_text_input_v3 = null,
    gp: std.heap.GeneralPurposeAllocator(.{}) =
        std.heap.GeneralPurposeAllocator(.{}){},

    current_id: i64 = 0,
    current_key: ?u32 = null,
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
            else => return,
        }
    }

    // static void inputText(_GLFWwindow* window, uint32_t scancode)
    // {
    //     const xkb_keysym_t* keysyms;
    //     const xkb_keycode_t keycode = scancode + 8;
    //
    //     if (xkb_state_key_get_syms(_glfw.wl.xkb.state, keycode, &keysyms) == 1)
    //     {
    //         const xkb_keysym_t keysym = composeSymbol(keysyms[0]);
    //         const uint32_t codepoint = _glfwKeySym2Unicode(keysym);
    //         if (codepoint != GLFW_INVALID_CODEPOINT)
    //         {
    //             const int mods = _glfw.wl.xkb.modifiers;
    //             const int plain = !(mods & (GLFW_MOD_CONTROL | GLFW_MOD_ALT));
    //             _glfwInputChar(window, codepoint, mods, plain);
    //         }
    //     }
    // }

    fn handle_char(self: *InputManager, engine: c.FlutterEngine, scancode: u32) void {
        var keysyms: [*c]c.xkb_keysym_t = undefined;
        const keycode = scancode + 8;
        // const sym = self.compose_symbol(key + 8);
        if (c.xkb_state_key_get_syms(self.xkb.state, keycode, &keysyms) != 1)
            return;

        const keysym = self.compose_symbol(keysyms[0]);
        //
        //

        if (keysym == c.XKB_KEY_NoSymbol) return;

        var code_points: [4]u8 = undefined;
        const end = std.unicode.utf8Encode(@intCast(keysym), &code_points) catch {
            std.debug.print("Failed to encode unicode symbol", .{});
            return;
        };

        self.editing_value.?.text = std.fmt.allocPrint(
            self.gp.allocator(),
            "{s}{s}",
            .{
                self.editing_value.?.text,
                code_points[0..end],
            },
        ) catch return;

        self.editing_value.?.selectionBase =
            @intCast(self.editing_value.?.text.len);

        self.editing_value.?.selectionExtent =
            @intCast(self.editing_value.?.text.len);

        self.dispatch_input_event(engine);
    }

    fn compose_symbol(self: *InputManager, sym: u32) u32 {
        if (sym == c.XKB_KEY_NoSymbol or self.xkb.compose == null)
            return sym;
        if (c.xkb_compose_state_feed(self.xkb.compose, sym) != c.XKB_COMPOSE_FEED_ACCEPTED)
            return sym;

        switch (c.xkb_compose_state_get_status(self.xkb.compose)) {
            c.XKB_COMPOSE_COMPOSED => {
                return c.xkb_compose_state_get_one_sym(
                    self.xkb.compose,
                );
            },
            c.XKB_COMPOSE_COMPOSING, c.XKB_COMPOSE_CANCELLED => {
                return c.XKB_KEY_NoSymbol;
            },
            else => return sym,
        }
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
        if (len == 0) return;
        var i = len;
        while (i > 0) {
            i -= 1;
            if (edit.text[i] & 0xC0 != 0x80) {
                edit.text = edit.text[0..i];
                break;
            }
        }
        self.dispatch_input_event(engine);
        return;
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
