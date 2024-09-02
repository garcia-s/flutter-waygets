const std = @import("std");

pub fn build(b: *std.Build) void {
    const exe = b.addExecutable(.{
        .name = "flutter_embedder",
        .root_source_file = b.path("src/main.zig"),
        .target = b.host,
    });
    exe.linkLibC();
    exe.addIncludePath(b.path("../linux-x64-embedder"));
    exe.addIncludePath(b.path("./include"));
    exe.linkSystemLibrary("wayland-client");
    exe.linkSystemLibrary("wlroots-0.18");
    b.installArtifact(exe);
    const run_exe = b.addRunArtifact(exe);
    const run_step = b.step("run", "Running the app");
    run_step.dependOn(&run_exe.step);
}
