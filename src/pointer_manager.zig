const c = @import("c_imports.zig").c;
const std = @import("std");

pub const PointerViewInfo = struct {
    view_id: i64,
    //maybe more infor
};

pub const PointerManager = struct {
    engine: *c.FlutterEngine = undefined,
    alloc: std.mem.Allocator = std.heap.page_allocator,
    mouse_focused: ?*c.struct_wl_surface = null,

    map: std.AutoHashMap(*c.struct_wl_surface, *c.FlutterEngine) = undefined,

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

    pub fn init(self: *PointerManager, alloc: std.mem.Allocator, engine: *c.FlutterEngine) !void {
        self.engine = engine;
        self.map = std.AutoHashMap(*c.struct_wl_surface, *c.FlutterEngine)
            .init(alloc);
    }

    pub fn deinit(self: *PointerManager) void {
        self.map.deinit();
    }
};
