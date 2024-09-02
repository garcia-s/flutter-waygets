const std = @import("std");

pub fn build(b: *std.Build) void {
    const exe = b.addExecutable(.{
        .name = "flutter_embedder",
        .root_source_file = "src/main.zig",
        .target = b.host,
    });
    b.installArtifact(exe);
}
