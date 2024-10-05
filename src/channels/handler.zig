const c = @import("../c_imports.zig").c;
const FLEmbedder = @import("../embedder.zig").FLEmbedder;

pub const MessageHandler = *const fn (
    []const u8,
    *FLEmbedder,
    ?*const c.FlutterPlatformMessageResponseHandle,
) anyerror!void;
