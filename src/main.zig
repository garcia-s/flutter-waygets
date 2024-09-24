const std = @import("std");
const YaraEngine = @import("daemon/engine.zig").YaraEngine;

pub fn main() anyerror!void {
    const alloc = std.heap.page_allocator;
    const args = try std.process.argsAlloc(alloc);
    std.debug.print("hello\n", .{});
    if (args.len < 2) {
        return error.InvalidArguments;
    }

    var engine = YaraEngine{};
    engine.run(args) catch |err| {
        std.debug.print("Error running Flutter embedder: {?}\n ", .{err});
    };
}
