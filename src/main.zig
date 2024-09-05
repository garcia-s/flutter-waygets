const std = @import("std");
const embed = @import("embedder.zig");

//Now we can start thinking about how we want to do this
//
//The easiest way to do it is to create a single flutter program for every applet
//The problem with that will be the overhead and startup time for each applet
//
//
//The other way to do it is with a daemon and we can dispatch actions to that
//daemon that open and close the different applets even tho the daemon is still running.
//
//This will be way more complex and difficult as the daemon has to be the entire flutter engine running and we'll only dispatch notifications for applets to show
//
//I think in any of these cases we'll need a way for applets to create new surfaces
//and dispatch to them from the flutter implementation since creating pop up menus will
//still need for a new surface probably on another layer.
pub fn main() anyerror!void {
    const alloc = std.heap.page_allocator;
    const args = try std.process.argsAlloc(alloc);
    defer alloc.free(args);

    if (args.len != 3) {
        return error.InvalidArguments;
    }

    const project_path = args[1];
    const icudtl_path = args[2];

    var embedder = embed.FlutterEmbedder{};

    embedder.run(project_path, icudtl_path) catch |err| {
        std.debug.print("Error running Flutter embedder: {?}\n ", .{err});
    };
}
