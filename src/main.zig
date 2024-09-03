const std = @import("std");
const embed = @import("embedder.zig");

pub fn main() void {
    var embedder = embed.FlutterEmbedder{};

    embedder.init() catch |err| {
        std.debug.print("Failed to initialize Flutter embedder: {}\n", .{err});
        return;
    };

    embedder.run() catch {
        std.debug.print("Error running Flutter embedder\n", .{});
    };
}
