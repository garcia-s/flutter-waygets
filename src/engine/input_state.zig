const c = @import("../c_imports.zig").c;
const std = @import("std");

pub const InputState = struct {
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

    mouse_focused: ?*c.struct_wl_surface = null,
    keyboard_focused: ?*c.struct_wl_surface = null,
    map: std.AutoHashMap(*c.struct_wl_surface, c.FlutterEngine) = undefined,

    pub fn init(self: *InputState) void {
        const alloc = std.heap.page_allocator;
        self.map = std.AutoHashMap(
            *c.struct_wl_surface,
            c.FlutterEngine,
        ).init(alloc);
    }

    pub fn deinit(self: *InputState) void {
        return self.map.deinit();
    }
};
