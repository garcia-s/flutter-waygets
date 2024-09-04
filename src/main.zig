const std = @import("std");
const embed = @import("embedder.zig");

pub fn main() anyerror!void {
    const alloc = std.heap.page_allocator;
    const args = try std.process.argsAlloc(alloc);
    defer alloc.free(args);

    if (args.len != 3) {
        return error.InvalidArguments;
    }

    const project_path = args[1];
    const icudtl_path = args[2];

    var embedder = embed.FlutterEmbedder{};

    _ = try embedder.init();

    embedder.run(&project_path, &icudtl_path) catch {
        std.debug.print("Error running Flutter embedder\n", .{});
    };
}
