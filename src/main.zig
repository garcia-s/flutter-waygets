const std = @import("std");
const YaraEngine = @import("daemon/engine.zig").YaraEngine;

pub fn main() anyerror!void {
    const alloc = std.heap.page_allocator;
    const args = try std.process.argsAlloc(alloc);

    if (args.len < 3) {
        return error.InvalidArguments;
    }

    var engine = FLEmbedder{};
    engine.run(args) catch |err| {
        std.debug.print("Error running Flutter embedder: {?}\n ", .{err});
    };
}
