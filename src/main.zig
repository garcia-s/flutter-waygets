const std = @import("std");
const FLEmbedder = @import("embedder.zig").FLEmbedder;

pub fn main() anyerror!void {
    const alloc = std.heap.page_allocator;
    const args = try std.process.argsAlloc(alloc);

    if (args.len < 2) {
        return error.InvalidArguments;
    }

    var embedder = FLEmbedder{};
    try embedder.init(&args[1]);

    embedder.run() catch |err| {
        std.debug.print("Error running Flutter embedder: {?}\n ", .{err});
    };
}
