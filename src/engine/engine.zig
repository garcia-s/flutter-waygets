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
    engines: []c.FlutterEngine = undefined,
    wl_display: *c.wl_display = undefined,
    wl_registry: *c.wl_registry = undefined,
    wl_compositor: *c.wl_compositor = undefined,
    wl_seat: *c.struct_wl_seat = undefined,
    wl_layer_shell: *c.zwlr_layer_shell_v1 = undefined,

    pub fn run(self: *YaraEngine, args: [][]u8) !void {
        //Init all the wayland stuff
        try self.init();
        //Init all the egl stuff
        try self.egl.init(self.wl_display);

        const e_alloc = std.heap.page_allocator;
        self.engines = try e_alloc.alloc(c.FlutterEngine, 1);

        var window = EGLWindow{};

        try window.init(
            self.wl_display,
            self.wl_compositor,
            self.wl_layer_shell,
            self.egl.display,
            self.egl.config,
            WindowState{
                .width = 500,
                .height = 1080,
                .closed = false,
            },
        );

        const alloc = std.heap.page_allocator;
        const assets_path = try std.fmt.allocPrint(
            alloc,
            "{s}{s}",
            .{ args[1], "/build/release/app/flutter_assets" },
        );

        const aot_alloc = std.heap.page_allocator;
        const aot_path = try std.fmt.allocPrint(aot_alloc, "{s}{s}", .{ assets_path, "/../lib/libapp.so" });

        // const argsv = [_][*:0]const u8{
        //     "--trace-skia",
        //     "--debug", "--verbose",
        // };
        var engine_args = c.FlutterProjectArgs{
            .struct_size = @sizeOf(c.FlutterProjectArgs),
            .assets_path = @ptrCast(assets_path.ptr),
            .icu_data_path = @ptrCast(args[2]),

            // .aot_data = aot_out,
            // .command_line_argv = @ptrCast(&argsv),
            // .command_line_argc = @intCast(argsv.len),
        };

        if (c.FlutterEngineRunsAOTCompiledDartCode()) {
            try aot.get_aot_data(
                aot_path,
                &engine_args.vm_snapshot_data,
                &engine_args.vm_snapshot_instructions,
                &engine_args.isolate_snapshot_data,
                &engine_args.isolate_snapshot_instructions,
            );
        }

        std.debug.print("ENGINE ARGS: {?}\n", .{engine_args});

        const config: c.FlutterRendererConfig = c.FlutterRendererConfig{
            .unnamed_0 = .{ .open_gl = OpenGLRendererConfig },
            .type = c.kOpenGL,
        };

        const eng = c.FlutterEngineInitialize(
            1,
            &config,
            &engine_args,
            &window,
            &self.engines[0],
        );

        if (eng != c.kSuccess)
            return error.FailedToRunFlutterEngine;

        _ = c.FlutterEngineRunInitialized(self.engines[0]);

        try self.input_state.map.put(window.wl_surface, self.engines[0]);
        const event = c.FlutterWindowMetricsEvent{
            .struct_size = @sizeOf(c.FlutterWindowMetricsEvent),
            .width = 500,
            .height = 1080,
            .pixel_ratio = 1,
            .left = 0,
            .top = 0,
            .physical_view_inset_top = 0,
            .physical_view_inset_right = 0,
            .physical_view_inset_bottom = 0,
            .physical_view_inset_left = 0,
            .display_id = 0,
            .view_id = 0,
        };
        _ = c.FlutterEngineSendWindowMetricsEvent(self.engines[0], &event);
        // const data: c.FlutterEngineAOTData = undefined;
        // _ = c.FlutterEngineCollectAOTData(data);
        while (true) {
            _ = c.wl_display_dispatch(self.wl_display);
        }
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
};
