const std = @import("std");
const c = @import("../c_imports.zig").c;
const FlutterEmbedder = @import("engine.zig").FlutterEmbedder;

const mgr_instance = WaylandManager{};

const WaylandEngineSurface = struct {
    surface: ?*c.wl_surface = null,
    layer_surface: ?*c.zwlr_layer_surface_v1 = null,
    dummy_surface: ?*c.wl_surface = null,
};

pub fn GetWLManager() *WaylandManager {
    if (mgr_instance.initialized == false) mgr_instance.init();
    return &mgr_instance;
}

//TODO: MIGHT NEED A MUTEX
const WaylandManager = struct {
    initialized: bool = false,
    wl_display: ?*c.wl_display = null,
    wl_registry: ?*c.wl_registry = null,
    wl_compositor: ?*c.wl_compositor = null,
    wl_seat: ?*c.wl_compositor = null,
    wl_layer_shell: ?*c.zwlr_layer_shell_v1 = null,

    pub fn init(self: *WaylandManager) !void {
        self.display = c.wl_display_connect("wayland-1");

        if (self.display == null) {
            std.debug.print("Failed to get a wayland display\n", .{});
            return error.WaylandConnectionFailed;
        }

        self.registry = c.wl_display_get_registry(self.display);
        if (self.registry == null) {
            std.debug.print("Failed to get the wayland registry\n", .{});
            return error.RegistryFailed;
        }

        const registry_listener = c.wl_registry_listener{
            .global = global_registry_handler,
            .global_remove = global_registry_remover,
        };

        const reg_result = c.wl_registry_add_listener(self.registry, &registry_listener, self);
        //Check if this should be done like this
        if (reg_result < 0) {
            std.debug.print("Failed to initialize the wayland layer shell and/or compositor\n", .{});
            return error.MissingGlobalObjects;
        }
        // Round-trip to get the global objects
        _ = c.wl_display_roundtrip(self.display);

        if (self.wl_compositor == null or self.wl_layer_shell == null or self.wl_seat) {
            std.debug.print("Failed to bind objects to registry", .{});
            return error.MissingGlobalObjects;
        }

        self.initialized = true;
    }

    //PASSS CONFIGS???? MAYBE ??
    pub fn get_surface(self: WaylandManager) !*WaylandEngineSurface {
        const wl_engine_surf = WaylandEngineSurface{};
        wl_engine_surf.surface = c.wl_compositor_create_surface(self.compositor);

        if (wl_engine_surf.surface == null) {
            std.debug.print("Failed to get a wayland surface\n", .{});
            return error.SurfaceCreationFailed;
        }

        wl_engine_surf.dummy_surface = c.wl_compositor_create_surface(self.compositor);

        if (wl_engine_surf.surface == null) {
            std.debug.print("Failed to get a wayland surface\n", .{});
            return error.SurfaceCreationFailed;
        }

        //PASS IT AS CONFIG, like the layer
        wl_engine_surf.layer_surface = c.zwlr_layer_shell_v1_get_layer_surface(
            self.wl_layer_shell,
            wl_engine_surf.surface,
            null, // Output
            c.ZWLR_LAYER_SHELL_V1_LAYER_TOP,
            "flutter",
        );

        if (wl_engine_surf.layer_surface == null) {
            std.debug.print("Failed to initialize a layer surface\n", .{});
            return error.LayerSurfaceFailed;
        }

        const layer_listener = c.struct_zwlr_layer_surface_v1_listener{
            .configure = configure,
            .closed = closed,
        };
        _ = c.zwlr_layer_surface_v1_add_listener(
            wl_engine_surf.layer_surface,
            &layer_listener,
            self,
        );

        //Pass it as configs
        c.zwlr_layer_surface_v1_set_anchor(
            wl_engine_surf.layer_surface,
            c.ZWLR_LAYER_SURFACE_V1_ANCHOR_TOP,
        );
        //Pass it as configs
        _ = c.zwlr_layer_surface_v1_set_size(wl_engine_surf.layer_surface, 1280, 100);
        _ = c.zwlr_layer_surface_v1_set_exclusive_zone(wl_engine_surf.layer_surface, 100);
        c.wl_surface_commit(self.surface);

        if (c.wl_display_dispatch(self.display) < 0) {
            std.debug.print("Failed to dispatch the initial layer surface commit\n", .{});
            return error.LayerSurfaceFailed;
        }

        return &wl_engine_surf;
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

fn configure(
    _: ?*anyopaque,
    surface: ?*c.struct_zwlr_layer_surface_v1,
    serial: u32,
    _: u32,
    _: u32,
) callconv(.C) void {
    c.zwlr_layer_surface_v1_ack_configure(
        surface,
        serial,
    );
}

fn closed(_: ?*anyopaque, _: ?*c.struct_zwlr_layer_surface_v1) callconv(.C) void {
    std.debug.print("Surface was closed \n", .{});
}

const wayland = @import("wayland-client-protocol");

var display: ?*wayland.wl_display = null;
var seat: ?*wayland.wl_seat = null;

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
