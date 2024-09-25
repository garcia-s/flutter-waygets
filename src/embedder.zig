const WLManager = @import("wl_manager.zig").WLManager;
const WLEgl = @import("wl_egl.zig").WLEgl;

pub const FLEmbedder = struct {
    wl: *WLManager = undefined,
    egl: *WLEgl = undefined,

    pub fn run(self: *FLEmbedder, _: *const []*const u8) !void {
        //Init wayland stuff
        self.wl.init();
        //Init egl stuff
        self.egl.init(self.wl.display);
    }
};
