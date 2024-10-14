const c = @import("../c_imports.zig").c;
const std = @import("std");

//Maybe useful
pub const PointerViewInfo = struct {
    view_id: i64,
};

pub const PointerManager = struct {
    engine: *c.FlutterEngine = undefined,
    alloc: std.mem.Allocator = std.heap.page_allocator,

    event: c.FlutterPointerEvent = c.FlutterPointerEvent{
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
};
