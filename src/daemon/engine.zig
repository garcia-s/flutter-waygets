const std = @import("std");
const c = @import("../c_imports.zig").c;
const WaylandEGL = @import("wl_egl.zig").WaylandEGL;
const InputState = @import("input_state.zig").InputState;
const WaylandManager = @import("wl_manager.zig").WaylandManager;
const FLEngine = @import("../flutter/fl_engine.zig").FLEngine;

pub const YaraEngine = struct {
    alloc: std.mem.Allocator = undefined,
    egl: WaylandEGL = WaylandEGL{},
    wl: WaylandManager = WaylandManager{},

    //this might be modified by multiple threads
    input_state: InputState = InputState{},
    engines: std.StringHashMap(*FLEngine) = undefined,

    pub fn run(self: *YaraEngine, args: [][]u8) !void {
        //Init the state
        try self.input_state.init();
        try self.wl.init(&self.input_state);
        try self.egl.init(self.wl.display);
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        self.alloc = gpa.allocator();

        const cwd = std.fs.cwd();
        const dir = try cwd.openDir(args[1], .{ .iterate = true });

        var iterator = dir.iterate();

        while (true) {
            const entry = iterator.next() catch break;
            if (entry == null) break;
            // Check if the entry is a directory
            if (entry.?.kind != .directory) continue;

            std.debug.print("Hello from engine", .{});
            const e = try self.alloc.create(FLEngine);

            const path = try std.fmt.allocPrint(
                self.alloc,
                "{s}/{s}",
                .{ args[1], entry.?.name },
            );

            //Adding it to the input state
            _ = try std.Thread.spawn(.{}, runProject, .{ e, path, self });
        }

        while (true) {
            _ = c.wl_display_dispatch(self.wl.display);
        }
    }

    pub fn runProject(e: *FLEngine, path: []u8, engine: *YaraEngine) !void {
        try e.init(path, engine);
        try e.run();
    }
};
