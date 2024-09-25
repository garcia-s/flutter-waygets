const std = @import("std");
const FLEmbedder = @import("embedder.zig").FLEmbedder;

pub fn main() anyerror!void {
    const alloc = std.heap.page_allocator;
    const args = try std.process.argsAlloc(alloc);

    if (args.len < 2) {
        return error.InvalidArguments;
    }

    const embedder = FLEmbedder{};
    embedder.run(args[1]) catch |err| {
        std.debug.print("Error running Flutter embedder: {?}\n ", .{err});
    };
}
