const c = @import("../c_imports.zig").c;
const std = @import("std");
const FLWindow = @import("../window/window.zig").FLWindow;
const FLEmbedder = @import("../embedder.zig").FLEmbedder;

pub const wl_pointer_listener = c.wl_pointer_listener{
    .leave = pointer_leave_handler,
    .enter = pointer_enter_handler,
    .motion = pointer_motion_handler,
    .button = pointer_button_handler,
    .axis = pointer_axis_handler,
    .frame = frame_handler,
};

pub fn pointer_enter_handler(
    data: ?*anyopaque,
    _: ?*c.struct_wl_pointer,
    _: u32,
    surface: ?*c.struct_wl_surface,
    _: i32,
    _: i32,
) callconv(.C) void {
    const e: *FLEmbedder = @ptrCast(@alignCast(data));
    e.pointer.event.view_id = e.view_surface_map.get(surface.?) orelse -1;
}

fn frame_handler(_: ?*anyopaque, _: ?*c.wl_pointer) callconv(.C) void {}

pub fn pointer_leave_handler(
    data: ?*anyopaque,
    _: ?*c.struct_wl_pointer,
    _: u32,
    _: ?*c.struct_wl_surface,
) callconv(.C) void {
    const e: *FLEmbedder = @ptrCast(@alignCast(data));

    var event = &e.pointer.event;
    event.x = c.wl_fixed_to_double(0);
    event.y = c.wl_fixed_to_double(0);

    event.timestamp = c.FlutterEngineGetCurrentTime();
    event.phase = if (event.buttons == 0) c.kHover else c.kMove;

    const r = c.FlutterEngineSendPointerEvent(
        e.engine,
        event,
        1,
    );

    if (r != c.kSuccess) {
        std.debug.print("Couldn't send pointer event", .{});
    }
}

pub fn pointer_motion_handler(
    data: ?*anyopaque,
    _: ?*c.struct_wl_pointer,
    _: u32,
    x: i32,
    y: i32,
) callconv(.C) void {
    const e: *FLEmbedder = @ptrCast(@alignCast(data));

    var event = &e.pointer.event;
    event.x = c.wl_fixed_to_double(x);
    event.y = c.wl_fixed_to_double(y);

    event.timestamp = c.FlutterEngineGetCurrentTime();
    event.phase = if (event.buttons == 0) c.kHover else c.kMove;

    const r = c.FlutterEngineSendPointerEvent(
        e.engine,
        event,
        1,
    );
    if (r != c.kSuccess) {
        std.debug.print("Not sendin event x:{d}, y:{d}\n", .{ x, y });
    }
}

pub fn pointer_button_handler(
    data: ?*anyopaque,
    _: ?*c.struct_wl_pointer,
    //Serial code of the event
    _: u32,
    //time of the event
    _: u32,
    //button..
    btn: u32,
    //State of the button
    bt_state: u32,
) callconv(.C) void {
    const e: *FLEmbedder = @ptrCast(@alignCast(data));

    var event = &e.pointer.event;
    const btn_val: i64 = @as(i64, 1) << @intCast(btn - 272);
    event.signal_kind = c.kFlutterPointerSignalKindNone;
    event.buttons = event.buttons ^ btn_val;
    event.phase = if (bt_state == 0) c.kUp else c.kDown;

    const r = c.FlutterEngineSendPointerEvent(e.engine, event, 1);
    if (r != c.kSuccess) {
        std.debug.print("Not sending event", .{});
    }
}

pub fn pointer_axis_handler(
    data: ?*anyopaque,
    _: ?*c.struct_wl_pointer,
    _: u32, //Time
    axis: u32, //Axis
    value: i32, //Axis value
) callconv(.C) void {
    const e: *FLEmbedder = @ptrCast(@alignCast(data));
    var event = &e.pointer.event;
    event.phase = c.kHover;
    event.signal_kind = c.kFlutterPointerSignalKindScroll;

    const delta: f64 = @as(f64, @floatFromInt(value)) / 120;

    if (axis == c.WL_POINTER_AXIS_VERTICAL_SCROLL) {
        event.scroll_delta_y = delta;
    } else event.scroll_delta_x = delta;

    _ = c.FlutterEngineSendPointerEvent(e.engine, event, 1);
    event.scroll_delta_x = 0;
    event.scroll_delta_y = 0;
}
