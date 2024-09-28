const c = @import("c_imports.zig").c;
const std = @import("std");
const FLWindow = @import("fl_window.zig").FLWindow;
const PointerManager = @import("pointer_manager.zig").PointerManager;

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
    const state: *PointerManager = @ptrCast(@alignCast(data));
    state.mouse_focused = surface.?;
}
fn frame_handler(_: ?*anyopaque, _: ?*c.struct_wl_pointer) callconv(.C) void {}

pub fn pointer_leave_handler(
    _: ?*anyopaque,
    _: ?*c.struct_wl_pointer,
    _: u32,
    _: ?*c.struct_wl_surface,
) callconv(.C) void {}

pub fn pointer_motion_handler(
    data: ?*anyopaque,
    _: ?*c.struct_wl_pointer,
    _: u32,
    x: i32,
    y: i32,
) callconv(.C) void {
    const state: *PointerManager = @ptrCast(@alignCast(data));
    if (state.mouse_focused == null) return;

    var event = &state.event;

    event.x = c.wl_fixed_to_double(x);
    event.y = c.wl_fixed_to_double(y);

    event.timestamp = @intCast(std.time.milliTimestamp());
    event.phase = if (event.buttons == 0) c.kHover else c.kMove;

    const r = c.FlutterEngineSendPointerEvent(state.engine.*, event, 1);
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
    const state: *PointerManager = @ptrCast(@alignCast(data));
    if (state.mouse_focused == null) return;

    var event = &state.event;
    const btn_val: i64 = @as(i64, 1) << @intCast(btn - 272);
    event.buttons = event.buttons ^ btn_val;

    event.phase = if (bt_state == 0) c.kUp else c.kDown;

    const r = c.FlutterEngineSendPointerEvent(state.engine.*, event, 1);
    if (r != c.kSuccess) {
        std.debug.print("Not sending event", .{});
    }
}

pub fn pointer_axis_handler(
    _: ?*anyopaque,
    _: ?*c.struct_wl_pointer,
    _: u32,
    _: u32,
    _: i32,
) callconv(.C) void {}
