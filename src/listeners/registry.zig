const c = @import("../c_imports.zig").c;
const std = @import("std");
const WindowManager = @import("../window/manager.zig").WindowManager;

pub const wl_registry_listener = c.wl_registry_listener{
    .global = global_registry_handler,
    .global_remove = global_registry_remover,
};

fn global_registry_handler(
    data: ?*anyopaque,
    registry: ?*c.struct_wl_registry,
    name: u32,
    iface: [*c]const u8,
    version: u32,
) callconv(.C) void {
    const manager: *WindowManager = @ptrCast(@alignCast(data));

    if (std.mem.eql(u8, std.mem.span(iface), "wl_compositor")) {
        manager.compositor = @ptrCast(
            c.wl_registry_bind(
                registry,
                name,
                &c.wl_compositor_interface,
                version,
            ),
        );
        return;
    }

    if (std.mem.eql(u8, std.mem.span(iface), "zwlr_layer_shell_v1")) {
        manager.layer_shell = @ptrCast(
            c.wl_registry_bind(
                registry,
                name,
                &c.zwlr_layer_shell_v1_interface,
                version,
            ),
        );
        return;
    }

    if (std.mem.eql(u8, std.mem.span(iface), "wl_seat")) {
        manager.seat = @ptrCast(
            c.wl_registry_bind(
                registry,
                name,
                &c.wl_seat_interface,
                3,
            ),
        );
        return;
    }

    if (std.mem.eql(u8, std.mem.span(iface), "wl_output")) {
        std.debug.print("?", .{});
    }
}

fn global_registry_remover(_: ?*anyopaque, _: ?*c.wl_registry, _: u32) callconv(.C) void {}
