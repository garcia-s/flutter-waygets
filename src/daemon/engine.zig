const std = @import("std");
const c = @import("../c_imports.zig").c;
const WaylandEGL = @import("wl_egl.zig").WaylandEGL;
const InputState = @import("input_state.zig").InputState;
const WaylandManager = @import("wl_manager.zig").WaylandManager;
const FLEngine = @import("../flutter/fl_engine.zig").FLEngine;

pub const YaraEngine = struct {
    alloc: std.mem.Allocator = undefined,
    input_state: InputState = InputState{},
    egl: WaylandEGL = WaylandEGL{},
    wl: WaylandManager = WaylandManager{},
    engines: std.StringHashMap(*FLEngine) = undefined,
    //So the engine should:
    //Initalize the wayland Initialize EGL stuff
    //Get the configs and AOT from the projects
    //Initialize the global platform channel
    //Initialize the projects and run the ones that are oath to be ran
    //
    //  For that we need;
    //  A path to the yara apps folder
    //  path should also contain a valid icudtl.dat somewhere || A single one?

    pub fn run(self: *YaraEngine, args: [][]u8) !void {
        self.alloc = std.heap.page_allocator;
        self.input_state.init(self.alloc);
        try self.wl.init(&self.input_state);
        try self.egl.init(self.wl.display);

        //This allocator might need to be changed to a general or arena

        const cwd = std.fs.cwd();
        const dir = try cwd.openDir(args[1], .{ .iterate = true });

        self.engines = std.StringHashMap(*FLEngine).init(self.alloc);

        var iterator = dir.iterate();
        while (true) {
            const entry = iterator.next() catch break;
            if (entry == null) break;
            // Check if the entry is a director
            if (entry.?.kind != .directory) continue;
            //try to load the config file
            //This will fail;
            var e = try self.alloc.create(FLEngine);
            const path = try std.fmt.allocPrint(
                self.alloc,
                "{s}/{s}",
                .{ args[1], entry.?.name },
            );
            e.init(path, self) catch continue;
            //Adding it to the input state
            try self.input_state.map.put(e.window.wl_surface, e.engine);
            try self.engines.put(entry.?.name, e);
        }

        while (true) {
            _ = c.wl_display_dispatch(self.wl.display);
        }
    }

    pub fn reload() !void {}
};

fn render_callback(_: ?*anyopaque) callconv(.C) void {}
