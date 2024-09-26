const c = @import("c_imports.zig").c;
const std = @import("std");

pub const PointerViewInfo = struct {
    view_id: i64,
};

pub const PointerManager = struct {
    engine: *c.FlutterEngine = undefined,
    alloc: std.mem.Allocator = std.heap.page_allocator,
    mouse_focused: ?*c.struct_wl_surface = null,
    map: std.AutoHashMap(*c.struct_wl_surface, *c.FlutterEngine) = undefined,

    pointer_ev: c.FlutterPointerEvent = c.FlutterPointerEvent{
        .struct_size = @sizeOf(c.FlutterPointerEvent),
        .phase = c.kHover,
        .x = 0,
        .y = 0,
        .signal_kind = c.kFlutterPointerSignalKindNone,
        .device_kind = c.kFlutterPointerDeviceKindMouse,
        .scroll_delta_x = 0,
        .scroll_delta_y = 0,
        .view_id = 0,
        .timestamp = 0,
    },

    pub fn deinit(self: *PointerManager) void {
        self.map.deinit();
    }
};

pub const KeyboardManager = struct {
    focused: ?*c.struct_wl_surface = null,
    xkb: *XKBState = undefined,

    // pub fn init(self: *KeyboardManager) !void {
    //     self.xkb = try self.alloc.create(XKBState);
    //     self.xkb.context = c.xkb_context_new(c.XKB_CONTEXT_NO_FLAGS);
    //     if (self.xkb.context == null) {
    //         return error.FailedTocreateKeyboardContext;
    //     }
    // }
};

pub const XKBState = struct {
    fd: i32 = 0,
    size: u32 = 0,
    context: ?*c.struct_xkb_context = null,
    keymap: ?*c.struct_xkb_keymap = null,
    state: ?*c.struct_xkb_state = null,
};
