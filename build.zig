const std = @import("std");

pub fn build(b: *std.Build) void {
    // const proto_dir = "protocols";
    const include_dir = "include";
    const exe = b.addExecutable(.{
        .name = "flutter_embedder",
        .root_source_file = b.path("src/main.zig"),
        .target = b.host,
    });

    exe.linkSystemLibrary("wayland-client");
    exe.addIncludePath(b.path(include_dir));
    exe.addIncludePath(b.path("../linux-x64-embedder"));

    exe.addCSourceFiles(.{
        .files = &.{
            "./include/xdg-shell-protocol.c",
            "./include/wlr-layer-shell-unstable-v1-protocol.c",
        },
    });
    b.installArtifact(exe);
    const run_exe = b.addRunArtifact(exe);
    const run_step = b.step("run", "Running the app");
    run_step.dependOn(&run_exe.step);
}
