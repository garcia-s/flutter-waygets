const c = @import("../c_imports.zig").c;
const std = @import("std");
const WindowManager = @import("../window/manager.zig").WindowManager;
const FLEmbedder = @import("../embedder.zig").FLEmbedder;

pub const RegistryHandler = *const fn (
    *FLEmbedder,
    ?*c.struct_wl_registry,
    u32,
    u32,
) callconv(.C) void;

pub const wl_registry_listener = c.wl_registry_listener{
    .global = global_registry_handler,
    .global_remove = global_registry_remover,
};

const registry_listeners = std.StaticStringMap(
    RegistryHandler,
).initComptime(.{
    .{ "wl_seat", handle_seat },
    .{ "zwlr_layer_shell_v1", handle_layer_shell },
    .{ "wl_compositor", handle_compositor },
    .{ "zwp_text_input_v3", handle_text_input },
});

fn global_registry_remover(
    _: ?*anyopaque,
    _: ?*c.wl_registry,
    _: u32,
) callconv(.C) void {}

fn global_registry_handler(
    data: ?*anyopaque,
    registry: ?*c.struct_wl_registry,
    name: u32,
    iface: [*c]const u8,
    version: u32,
) callconv(.C) void {
    const e: *FLEmbedder = @ptrCast(@alignCast(data));
    const str: []const u8 = std.mem.span(iface);
    const h = registry_listeners.get(str) orelse return;
    h(e, registry, name, version);
}

fn handle_compositor(
    embedder: *FLEmbedder,
    registry: ?*c.struct_wl_registry,
    name: u32,
    version: u32,
) callconv(.C) void {
    embedder.window.compositor = @ptrCast(
        c.wl_registry_bind(
            registry,
            name,
            &c.wl_compositor_interface,
            version,
        ),
    );
}

fn handle_seat(
    embedder: *FLEmbedder,
    registry: ?*c.struct_wl_registry,
    name: u32,
    _: u32,
) callconv(.C) void {
    embedder.seat = @ptrCast(
        c.wl_registry_bind(
            registry,
            name,
            &c.wl_seat_interface,
            3,
        ),
    );
}

fn handle_layer_shell(
    embedder: *FLEmbedder,
    registry: ?*c.struct_wl_registry,
    name: u32,
    version: u32,
) callconv(.C) void {
    embedder.window.layer_shell = @ptrCast(
        c.wl_registry_bind(
            registry,
            name,
            &c.zwlr_layer_shell_v1_interface,
            version,
        ),
    );
}

fn handle_text_input(
    embedder: *FLEmbedder,
    registry: ?*c.struct_wl_registry,
    name: u32,
    version: u32,
) callconv(.C) void {
    embedder.textinput.wl_input = @ptrCast(
        c.wl_registry_bind(
            registry,
            name,
            &c.zwp_text_input_v3_interface,
            version,
        ),
    );
}
