const c = @import("../c_imports.zig").c;
const std = @import("std");
const WaylandEGL = @import("wl_egl.zig").WaylandEGL;
const EGLWindow = @import("../flutter/fl_window.zig").FLWindow;
const wl_keyboard_listener = @import("wl_keyboard_listener.zig").wl_keyboard_listener;
const wl_registry_listener = @import("wl_registry_listener.zig").wl_registry_listener;
const wl_pointer_listener = @import("wl_pointer_listener.zig").wl_pointer_listener;

pub const WLManager = struct {
    display: *c.wl_display = undefined,
    registry: *c.wl_registry = undefined,
    compositor: *c.wl_compositor = undefined,
    seat: *c.struct_wl_seat = undefined,
    layer_shell: *c.zwlr_layer_shell_v1 = undefined,

    pub fn init(self: *WLManager) !void {
        self.display = c.wl_display_connect(null) orelse {
            std.debug.print("Failed to get a wayland display\n", .{});
            return error.WaylandConnectionFailed;
        };

        self.registry = c.wl_display_get_registry(self.display) orelse {
            std.debug.print("Failed to get the wayland registry\n", .{});
            return error.RegistryFailed;
        };

        const reg_result = c.wl_registry_add_listener(
            self.registry,
            &wl_registry_listener,
            self,
        );
        //Check if this should be done like this
        if (reg_result < 0) {
            std.debug.print("Failed to initialize the wayland layer shell and/or compositor\n", .{});
            return error.MissingGlobalObjects;
        }

        // Round-trip to get the global objects
        _ = c.wl_display_roundtrip(self.display);

        if (self.compositor == undefined or self.layer_shell == undefined or self.seat == undefined) {
            std.debug.print("Failed to bind objects to registry", .{});
            return error.MissingGlobalObjects;
        }

        // const pointer = c.wl_seat_get_pointer(self.seat) orelse {
        //     std.debug.print("Failed to retrieve a pointer", .{});
        //     return error.ErrorRetrievingPointer;
        // };

        // _ = c.wl_pointer_add_listener(
        //     pointer,
        //     &wl_pointer_listener,
        //     input_state,
        // );

        // const keyboard = c.wl_seat_get_keyboard(self.seat) orelse {
        //     return error.ErrorRetrievingKeyboard;
        // };
        //
        // _ = c.wl_keyboard_add_listener(
        //     keyboard,
        //     &wl_keyboard_listener,
        //     input_state,
        // );
    }
};
