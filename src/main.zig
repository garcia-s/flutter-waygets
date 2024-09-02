const std = @import("std");
const FlutterEmbedder = @import("embedder.zig").FlutterEmbedder;

pub fn main() void {
    var embedder = FlutterEmbedder{};

    embedder.init() catch |err| {
        std.debug.print("Failed to initialize Flutter embedder: {}\n", .{err});
        return;
    };

    embedder.run() catch {
        std.debug.print("Error running Flutter embedder\n", .{});
    };
}
