const std = @import("std");
const embed = @import("embedder.zig");

pub fn main(args: [][]u8) void {
    if (args.len != 3) {
        return 1;
    }

    var embedder = embed.FlutterEmbedder{};

    embedder.init() catch |err| {
        std.debug.print("Failed to initialize Flutter embedder: {}\n", .{err});
        return;
    };

    embedder.run() catch {
        std.debug.print("Error running Flutter embedder\n", .{});
    };
}
