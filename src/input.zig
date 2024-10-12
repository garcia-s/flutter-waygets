const c = @import("c_imports.zig").c;
const std = @import("std");

pub const InputManager = struct {
    libinput: *c.struct_libinput = undefined,

    pub fn init(self: *InputManager) !void {
        const udev = c.udev_new() orelse {
            return error.udevContextCreationFailed;
        };

        const interface = c.struct_libinput_interface{
            .open_restricted = open_restricted,
            .close_restricted = close_restricted,
        };

        self.libinput = c.libinput_udev_create_context(
            &interface,
            null,
            udev,
        ) orelse {
            return error.libInputCreationFailed;
        };
    }
};

fn open_restricted(
    path: [*c]const u8,
    flags: c_int,
    _: ?*anyopaque,
) callconv(.C) c_int {
    const open_mode = std.fs.File.OpenMode{

    };

    //
    const f = std.fs.openFileAbsolute(path, open_mode) catch {
        std.log.err("Error opening the libinput file: {s}\n", .{path});
    };
    const fd = f.handle;
    if (fd >= 0) return fd;
}
fn close_restricted(fd: c_int, _: ?*anyopaque) callconv(.C) void {
    const ret = std.os.linux.close(fd);
    if (ret >= 0) return;
    std.log.err("Error closing the libinput file descriptor: {d}\n", .{fd});
}
