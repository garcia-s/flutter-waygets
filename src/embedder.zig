
const WLManager = @import("wl_manager.zig").WLManager;
pub const FLEmbedder = struct {
    wl: *WLManager = undefined,
    egl: *WLEgl = undefined,

    pub fn run(_: *FLEmbedder, path: *[]*const u8) !void {
        //Init wayland stuff
        //Init egl stuff
    }
};
