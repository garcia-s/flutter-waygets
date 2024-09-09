const std = @import("std");
const FlutterEngine = @import("engine/engine.zig").FlutterEngine;

pub fn main() anyerror!void {
    const alloc = std.heap.page_allocator;
    const args = try std.process.argsAlloc(alloc);

    if (args.len < 3) {
        return error.InvalidArguments;
    }

    var engine = FlutterEngine{};
    engine.run(args) catch |err| {
        std.debug.print("Error running Flutter embedder: {?}\n ", .{err});
    };
}
