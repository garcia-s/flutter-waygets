const std = @import("std");
const c = @import("../c_imports.zig").c;
const FlutterEmbedder = @import("engine.zig").FlutterEmbedder;

var mgr_instance = WaylandManager{};

pub fn GetWLManager() !*WaylandManager {
    if (mgr_instance.initialized == false) try mgr_instance.init();
    return &mgr_instance;
}

//TODO: MIGHT NEED A MUTEX
pub const WaylandManager = struct {
    initialized: bool = false,
    wl_display: ?*c.wl_display = null,
    wl_registry: ?*c.wl_registry = null,
    wl_compositor: ?*c.wl_compositor = null,
    wl_seat: ?*c.wl_compositor = null,
    wl_layer_shell: ?*c.zwlr_layer_shell_v1 = null,

    fn init(self: *WaylandManager) !void {
        self.wl_display = c.wl_display_connect(null);

        if (self.wl_display == null) {
            std.debug.print("Failed to get a wayland display\n", .{});
            return error.WaylandConnectionFailed;
        }

        self.wl_registry = c.wl_display_get_registry(self.wl_display);
        if (self.wl_registry == null) {
            std.debug.print("Failed to get the wayland registry\n", .{});
            return error.RegistryFailed;
        }

        const registry_listener = c.wl_registry_listener{
            .global = global_registry_handler,
            .global_remove = global_registry_remover,
        };

        const reg_result = c.wl_registry_add_listener(
            self.wl_registry,
            &registry_listener,
            self,
        );
        //Check if this should be done like this
        if (reg_result < 0) {
            std.debug.print("Failed to initialize the wayland layer shell and/or compositor\n", .{});
            return error.MissingGlobalObjects;
        }
        // Round-trip to get the global objects
        _ = c.wl_display_roundtrip(self.wl_display);

        if (self.wl_compositor == null or self.wl_layer_shell == null or self.wl_seat == null) {
            std.debug.print("Failed to bind objects to registry", .{});
            return error.MissingGlobalObjects;
        }

        self.initialized = true;
    }

    fn global_registry_handler(
        data: ?*anyopaque,
        registry: ?*c.struct_wl_registry,
        name: u32,
        iface: [*c]const u8,
        version: u32,
    ) callconv(.C) void {
        const manager: *WaylandManager = @ptrCast(@alignCast(data));
        if (std.mem.eql(u8, std.mem.span(iface), "wl_compositor")) {
            manager.wl_compositor = @ptrCast(
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
            manager.wl_layer_shell = @ptrCast(
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
            manager.wl_seat = @ptrCast(
                c.wl_registry_bind(
                    registry,
                    name,
                    &c.wl_seat_interface,
                    version,
                ),
            );
        }
    }

    fn global_registry_remover(_: ?*anyopaque, _: ?*c.wl_registry, _: u32) callconv(.C) void {}
};

pub fn main() !void {
    // const pointer = wayland.wl_seat_get_pointer(seat.?);
    // const keyboard = wayland.wl_seat_get_keyboard(seat.?);
    //
    // // Add listeners for pointer and keyboard
    // wayland.wl_pointer_add_listener(pointer, &pointer_listener, null);
    // wayland.wl_keyboard_add_listener(keyboard, &keyboard_listener, null);
}

// Pointer event listener
// const pointer_listener = wayland.wl_pointer_listener{
//     .enter = pointer_enter_handler,
//     .leave = pointer_leave_handler,
//     .motion = pointer_motion_handler,
//     .button = pointer_button_handler,
//     .axis = pointer_axis_handler,
// };
//
// // Keyboard event listener
// const keyboard_listener = wayland.wl_keyboard_listener{
//     .keymap = keyboard_keymap_handler,
//     .enter = keyboard_enter_handler,
//     .leave = keyboard_leave_handler,
//     .key = keyboard_key_handler,
//     .modifiers = keyboard_modifiers_handler,
// };
//
// // Pointer event handlers
// fn pointer_enter_handler(
//     pointer: *wayland.wl_pointer,
//     serial: u32,
//     surface: *wayland.wl_surface,
//     surface_x: wl_fixed_t,
//     surface_y: wl_fixed_t,
//     data: *anyopaque,
// ) void {
//     std.debug.print("Pointer entered surface at ({}, {})\n", .{ surface_x, surface_y });
// }
//
// fn pointer_leave_handler(
//     pointer: *wayland.wl_pointer,
//     serial: u32,
//     surface: *wayland.wl_surface,
//     data: *anyopaque,
// ) void {
//     std.debug.print("Pointer left surface\n", .{});
// }
//
// fn pointer_motion_handler(
//     pointer: *wayland.wl_pointer,
//     time: u32,
//     surface_x: wl_fixed_t,
//     surface_y: wl_fixed_t,
//     data: *anyopaque,
// ) void {
//     const x = wl_fixed_to_double(surface_x);
//     const y = wl_fixed_to_double(surface_y);
//     std.debug.print("Pointer moved to ({}, {})\n", .{ x, y });
// }
//
// fn pointer_button_handler(
//     pointer: *wayland.wl_pointer,
//     serial: u32,
//     time: u32,
//     button: u32,
//     state: u32,
//     data: *anyopaque,
// ) void {
//     const action = if (state == wayland.WL_POINTER_BUTTON_STATE_PRESSED) "pressed" else "released";
//     std.debug.print("Pointer button {} {}\n", .{ button, action });
// }
//
// fn pointer_axis_handler(
//     pointer: *wayland.wl_pointer,
//     time: u32,
//     axis: u32,
//     value: wl_fixed_t,
//     data: *anyopaque,
// ) void {
//     std.debug.print("Pointer axis event on axis {} with value {}\n", .{ axis, value });
// }
//
// // Keyboard event handlers
// fn keyboard_keymap_handler(
//     keyboard: *wayland.wl_keyboard,
//     format: u32,
//     fd: i32,
//     size: u32,
//     data: *anyopaque,
// ) void {}
//
// fn keyboard_enter_handler(
//     keyboard: *wayland.wl_keyboard,
//     serial: u32,
//     surface: *wayland.wl_surface,
//     keys: [*:0]const u32,
//     data: *anyopaque,
// ) void {
//     std.debug.print("Keyboard focus entered\n", .{});
// }
//
// fn keyboard_leave_handler(
//     keyboard: *wayland.wl_keyboard,
//     serial: u32,
//     surface: *wayland.wl_surface,
//     data: *anyopaque,
// ) void {
//     std.debug.print("Keyboard focus left\n", .{});
// }
//
// fn keyboard_key_handler(
//     keyboard: *wayland.wl_keyboard,
//     serial: u32,
//     time: u32,
//     key: u32,
//     state: u32,
//     data: *anyopaque,
// ) void {
//     const action = if (state == wayland.WL_KEYBOARD_KEY_STATE_PRESSED) "pressed" else "released";
//     std.debug.print("Key {} {}\n", .{ key, action });
// }
//
// fn keyboard_modifiers_handler(
//     keyboard: *wayland.wl_keyboard,
//     serial: u32,
//     mods_depressed: u32,
//     mods_latched: u32,
//     mods_locked: u32,
//     group: u32,
//     data: *anyopaque,
// ) void {
//     std.debug.print("Keyboard modifiers changed\n", .{});
// }
