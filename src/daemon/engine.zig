const std = @import("std");
const c = @import("../c_imports.zig").c;
const WaylandEGL = @import("wayland_egl.zig").WaylandEGL;
const EGLWindow = @import("egl_window.zig").EGLWindow;
const InputState = @import("input_state.zig").InputState;
const WindowState = @import("window_state.zig").WindowState;
const aot = @import("elf_aot_data.zig");
const OpenGLRendererConfig = @import("opengl_flutter_config.zig").OpenGLRendererConfig;
const EngineHash = @import("utils.zig").EngineHash;
const keyboard_listener = @import("keyboard_handler.zig").keyboard_listener;
const wl_handler = @import("wayland_registry_handler.zig").wl_listener;
const pointer_listener = @import("pointer_handler.zig").pointer_listener;

pub const YaraEngine = struct {
    input_state: InputState = InputState{},
    egl: WaylandEGL = WaylandEGL{},
    wl_display: *c.wl_display = undefined,
    wl_registry: *c.wl_registry = undefined,
    wl_compositor: *c.wl_compositor = undefined,
    wl_seat: *c.struct_wl_seat = undefined,
    wl_layer_shell: *c.zwlr_layer_shell_v1 = undefined,

    pub fn run(self: *YaraEngine, args: [][]u8) !void {
        const e_alloc = std.heap.page_allocator;
        self.engines = try e_alloc.alloc(c.FlutterEngine, 1);
        //Init all the wayland stuff
        try self.init();
        //Init all the egl stuff
        try self.egl.init(self.wl_display);
    }

    fn init(self: *YaraEngine) !void {
        self.input_state.init();
        self.wl_display = c.wl_display_connect(null) orelse {
            std.debug.print("Failed to get a wayland display\n", .{});
            return error.WaylandConnectionFailed;
        };

        self.wl_registry = c.wl_display_get_registry(self.wl_display) orelse {
            std.debug.print("Failed to get the wayland registry\n", .{});
            return error.RegistryFailed;
        };

        const reg_result = c.wl_registry_add_listener(
            self.wl_registry,
            &wl_handler,
            self,
        );
        //Check if this should be done like this
        if (reg_result < 0) {
            std.debug.print("Failed to initialize the wayland layer shell and/or compositor\n", .{});
            return error.MissingGlobalObjects;
        }
        // Round-trip to get the global objects
        _ = c.wl_display_roundtrip(self.wl_display);

        if (self.wl_compositor == undefined or self.wl_layer_shell == undefined or self.wl_seat == undefined) {
            std.debug.print("Failed to bind objects to registry", .{});
            return error.MissingGlobalObjects;
        }

        const pointer = c.wl_seat_get_pointer(self.wl_seat) orelse {
            std.debug.print("Failed to retrieve a pointer", .{});
            return error.ErrorRetrievingPointer;
        };

        _ = c.wl_pointer_add_listener(
            pointer,
            &pointer_listener,
            &self.input_state,
        );

        const keyboard = c.wl_seat_get_keyboard(self.wl_seat) orelse {
            std.debug.print("Failed to retrieve a pointer", .{});
            return error.ErrorRetrievingPointer;
        };

        _ = c.wl_keyboard_add_listener(
            keyboard,
            &keyboard_listener,
            &self.input_state,
        );
    }

    pub fn reload() void {}
};

fn render_callback(_: ?*anyopaque) callconv(.C) void {}
