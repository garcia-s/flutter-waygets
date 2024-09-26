const std = @import("std");
const FLEmbedder = @import("embedder.zig").FLEmbedder;
const FLView = @import("fl_view.zig").FLView;

pub fn main() anyerror!void {
    const alloc = std.heap.page_allocator;
    const args = try std.process.argsAlloc(alloc);

    if (args.len < 2) {
        return error.InvalidArguments;
    }

    var embedder = FLEmbedder{};

    try embedder.init(
        &args[1],
        &FLView{
            .auto_initialize = true,
            .width = 1920,
            .height = 80,
            .exclusive_zone = 80,
            .layer = 2,
            .keyboard_interactivity = 0,
            .margin = .{ 0, 0, 0, 0 },
            .anchors = .{
                .top = true,
                .left = false,
                .bottom = false,
                .right = false,
            },
        },
    );
    embedder.run() catch |err| {
        std.debug.print("Error running Flutter embedder: {?}\n ", .{err});
    };
}
