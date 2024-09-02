const std = @import("std");
const c = @cImport({
    @cInclude("flutter_embedder.h");
    @cInclude("wayland-client.h");
    //Might need to find a better way to do this because fedora naming is weird
});

pub fn main() void {
    var stdout = std.io.getStdOut().writer();
    const display = c.wl_display_connect(null);

    if (display == null) {
        stdout.print("Unable to get the wayland display \n", .{}) catch {};
        return;
    }

    stdout.print("Getting a display \n", .{}) catch {};
}
