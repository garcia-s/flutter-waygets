const std = @import("std");

pub fn build(b: *std.Build) void {
    // const proto_dir = "protocols";
    const include_dir = "include";
    const exe = b.addExecutable(.{
        .name = "flutter_embedder",
        .root_source_file = b.path("src/main.zig"),
        .target = b.host,
    });

    exe.linkLibC();
    exe.addIncludePath(b.path(include_dir));
    exe.addLibraryPath(b.path("../linux-x64-embedder"));
    exe.addSystemIncludePath(b.path("../linux-x64-embedder"));
    exe.linkSystemLibrary("GL");
    exe.linkSystemLibrary("egl");
    exe.linkSystemLibrary("wayland-egl");
    exe.linkSystemLibrary("wayland-client");
    exe.linkSystemLibrary("flutter_engine");
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
