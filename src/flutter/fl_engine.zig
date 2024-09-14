const std = @import("std");
const c = @import("../c_imports.zig").c;

const FLWindow = @import("fl_window.zig").FLWindow;
const WindowConfig = @import("../daemon/window_config.zig").WindowConfig;
//TODO: Move
const loader = @import("../daemon/flutter_aot_loader.zig");
const create_renderer_config = @import("fl_render_config.zig").create_renderer_config;
const YaraEngine = @import("../daemon/engine.zig").YaraEngine;
pub const FLEngine = struct {
    path: [][]u8 = undefined,
    window: FLWindow = FLWindow{},
    daemon: *YaraEngine = undefined,
    engine_args: c.FlutterProjectArgs = undefined,
    engine: c.FlutterEngine = undefined,

    pub fn init(self: *FLEngine, root_path: []u8, daemon: *YaraEngine) !void {
        const alloc = std.heap.page_allocator;

        const conf_path = try std.fmt.allocPrint(alloc, "{s}/{s}", .{
            root_path,
            "config.json",
        });

        const assets_path = try std.fmt.allocPrint(alloc, "{s}/{s}", .{
            root_path,
            "flutter_assets/",
        });

        const fd = try std.fs.cwd().openFile(conf_path, .{ .mode = .read_only });

        const buff = try fd.readToEndAlloc(alloc, 2048);
        defer alloc.free(buff);

        const winconf = try std.json.parseFromSlice(WindowConfig, alloc, buff, .{});

        const icu_alloc = std.heap.page_allocator;
        const icu_path = try std.fmt.allocPrint(
            icu_alloc,
            "{s}{s}",
            .{ root_path, "/icudtl.dat" },
        );

        self.engine_args = c.FlutterProjectArgs{
            .struct_size = @sizeOf(c.FlutterProjectArgs),
            .assets_path = @ptrCast(assets_path.ptr),
            .icu_data_path = @ptrCast(icu_path),
        };

        const aot_path = try std.fmt.allocPrint(alloc, "{s}{s}", .{
            root_path,
            "/lib/libapp.so",
        });

        try loader.get_aot_data(
            aot_path,
            &self.engine_args.vm_snapshot_data,
            &self.engine_args.vm_snapshot_instructions,
            &self.engine_args.isolate_snapshot_data,
            &self.engine_args.isolate_snapshot_instructions,
        );

        const config: c.FlutterRendererConfig = c.FlutterRendererConfig{
            .type = c.kOpenGL,
            .unnamed_0 = .{
                .open_gl = create_renderer_config(),
            },
        };

        self.daemon = daemon;

        try self.window.init(
            self.daemon.wl.compositor,
            self.daemon.wl.layer_shell,
            self.daemon.egl.display,
            self.daemon.egl.config,
            winconf.value,
        );

        const res = c.FlutterEngineInitialize(
            1,
            &config,
            &self.engine_args,
            &self.window,
            &self.engine,
        );

        if (res != c.kSuccess) {
            return error.FailedToRunFlutterEngine;
        }
        // _ = try std.Thread.spawn(.{}, run, .{self});
        try self.run();
    }

    pub fn run(self: *FLEngine) !void {
        //     // const argsv = [_][*:0]const u8{
        //     //     "--trace-skia",
        //     //     "--debug", "--verbose",
        //     // };
        //     var engine_args =
        //
        try self.window.commit(
            self.daemon.wl.display,
            self.daemon.egl.config,
        );

        _ = c.FlutterEngineRunInitialized(self.engine);

        const event = c.FlutterWindowMetricsEvent{
            .struct_size = @sizeOf(c.FlutterWindowMetricsEvent),
            .width = self.window.state.width,
            .height = self.window.state.height,
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

        _ = c.FlutterEngineSendWindowMetricsEvent(self.engine, &event);
    }
};
