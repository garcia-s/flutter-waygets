const std = @import("std");
const c = @import("../c_imports.zig").c;

const FLWindow = @import("fl_window.zig").FLWindow;
const WindowConfig = @import("../daemon/window_config.zig").WindowConfig;
const WindowAnchors = @import("../daemon/window_config.zig").WindowAnchors;
const tasks = @import("fl_task_runners.zig");
//TODO: Move
const loader = @import("../daemon/flutter_aot_loader.zig");
const create_renderer_config = @import("fl_render_config.zig").create_renderer_config;
const YaraEngine = @import("../daemon/engine.zig").YaraEngine;
pub const FLEngine = struct {
    gpa: std.heap.GeneralPurposeAllocator(.{}) = undefined,
    alloc: std.mem.Allocator = undefined,
    path: [][]u8 = undefined,
    window: *FLWindow = undefined,
    daemon: *YaraEngine = undefined,
    engine_args: c.FlutterProjectArgs = undefined,
    engine: c.FlutterEngine = undefined,
    renderer_runner: *tasks.FLTaskRunner = undefined,
    platform_runner: *tasks.FLTaskRunner = undefined,

    pub fn init(self: *FLEngine, root_path: []u8, daemon: *YaraEngine) !void {
        self.gpa = std.heap.GeneralPurposeAllocator(.{}){};
        self.alloc = self.gpa.allocator();

        const conf_path = try std.fmt.allocPrint(self.alloc, "{s}/{s}", .{
            root_path,
            "config.json",
        });
        //C NEEDS this two to be null terminated strings if they are not it'll never shut up about it
        const assets_path = try std.fmt.allocPrintZ(self.alloc, "{s}/{s}", .{
            root_path,
            "flutter_assets",
        });
        const icu_path = try std.fmt.allocPrintZ(self.alloc, "{s}/{s}", .{
            root_path,
            "icudtl.dat",
        });

        const fd = try std.fs.cwd().openFile(conf_path, .{ .mode = .read_only });
        const buff = try fd.readToEndAlloc(self.alloc, 2048);
        defer self.alloc.free(buff);
        const winconf = try std.json.parseFromSlice(WindowConfig, self.alloc, buff, .{});

        self.engine_args = c.FlutterProjectArgs{
            .struct_size = @sizeOf(c.FlutterProjectArgs),
            .assets_path = @ptrCast(assets_path.ptr),
            .icu_data_path = @ptrCast(icu_path.ptr),
        };

        const aot_path = try std.fmt.allocPrint(self.alloc, "{s}{s}", .{
            root_path,
            "/lib/libapp.so",
        });

        if (c.FlutterEngineRunsAOTCompiledDartCode()) {
            try loader.get_aot_data(
                aot_path,
                &self.engine_args.vm_snapshot_data,
                &self.engine_args.vm_snapshot_instructions,
                &self.engine_args.isolate_snapshot_data,
                &self.engine_args.isolate_snapshot_instructions,
            );
        }

        var config = c.FlutterRendererConfig{
            .type = c.kOpenGL,
            .unnamed_0 = .{
                .open_gl = create_renderer_config(),
            },
        };

        self.daemon = daemon;
        self.window = try self.alloc.create(FLWindow);

        try self.window.init(
            self.daemon.wl.compositor,
            self.daemon.wl.layer_shell,
            self.daemon.egl.display,
            self.daemon.egl.config,
            winconf.value,
        );

        self.renderer_runner = try self.alloc.create(tasks.FLTaskRunner);
        self.platform_runner = try self.alloc.create(tasks.FLTaskRunner);

        try self.renderer_runner.init(
            self.alloc,
            std.Thread.getCurrentId(),
            &self.engine,
        );

        try self.platform_runner.init(
            self.alloc,
            std.Thread.getCurrentId(),
            &self.engine,
        );

        self.engine_args.custom_task_runners = &c.FlutterCustomTaskRunners{
            .struct_size = @sizeOf(c.FlutterCustomTaskRunners),
            .render_task_runner = &c.FlutterTaskRunnerDescription{
                .struct_size = @sizeOf(c.FlutterTaskRunnerDescription),
                .user_data = self.renderer_runner,
                .runs_task_on_current_thread_callback = tasks.runs_task_on_current_thread,
                .post_task_callback = &tasks.post_task_callback,
                .identifier = 1,
            },

            .platform_task_runner = &c.FlutterTaskRunnerDescription{
                .struct_size = @sizeOf(c.FlutterTaskRunnerDescription),
                .user_data = self.platform_runner,
                .runs_task_on_current_thread_callback = tasks.runs_task_on_current_thread,
                .post_task_callback = tasks.post_task_callback,
                .identifier = 2,
            },
        };

        const res = c.FlutterEngineInitialize(
            1,
            &config,
            &self.engine_args,
            self.window,
            &self.engine,
        );

        if (res != c.kSuccess) {
            return error.FailedToRunFlutterEngine;
        }

        // _ = try std.Thread.spawn(.{}, run, .{self});
        //
        //
        try self.daemon.input_state.map.put(self.window.wl_surface, self.engine);
    }

    pub fn run(self: *FLEngine) !void {
        //     // const argsv = [_][*:0]const u8{
        //     //     "--trace-skia",
        //     //     "--debug", "--verbose",
        //     // };
        //     var engine_args =
        try self.window.commit(
            self.daemon.wl.display,
            self.daemon.egl.config,
        );

        const result = c.FlutterEngineRunInitialized(self.engine);

        if (result != c.kSuccess) {
            std.debug.print("Failed to run the flutter engine \n", .{});
            return error.FlutterEngineRunFailed;
        }

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
        const window = try self.alloc.create(FLWindow);

        try self.window.init(
            self.daemon.wl.compositor,
            self.daemon.wl.layer_shell,
            self.daemon.egl.display,
            self.daemon.egl.config,
            WindowConfig{
                .auto_initialize = true,
                .width = 300,
                .height = 300,
                .exclusive_zone = 300,
                .layer = 2,
                .anchors = WindowAnchors{
                    .top = true,
                    .left = false,
                    .bottom = false,
                    .right = false,
                },
                .margin = null,
                .keyboard_interactivity = 1,
            },
        );
        const ev2 = c.FlutterWindowMetricsEvent{
            .struct_size = @sizeOf(c.FlutterWindowMetricsEvent),
            .width = window.state.width,
            .height = window.state.height,
            .pixel_ratio = 1,
            .left = 0,
            .top = 0,
            .physical_view_inset_top = 0,
            .physical_view_inset_right = 0,
            .physical_view_inset_bottom = 0,
            .physical_view_inset_left = 0,
            .display_id = 0,
            .view_id = 1,
        };

        const view = c.FlutterAddViewInfo{
            .struct_size = @sizeOf(c.FlutterAddViewInfo),
            .view_id = 1,
            .view_metrics = &ev2,
            .user_data = window,
            .add_view_callback = add_view_callback,
        };

        const res = c.FlutterEngineAddView(self.engine, &view);
        if (res != c.kSuccess) {
            std.debug.print("Failed to add view\n", .{});
        }

        _ = c.FlutterEngineSendWindowMetricsEvent(self.engine, &event);
        _ = c.FlutterEngineSendWindowMetricsEvent(self.engine, &ev2);
        while (true) {
            std.time.sleep(30 * 1000 * 1000);
            std.debug.print("Running \n", .{});
            self.renderer_runner.run_next_task();
            self.platform_runner.run_next_task();
        }
    }
};

fn add_view_callback(_: [*c]const c.FlutterAddViewResult) callconv(.C) void {}
