pub const WindowConfig = struct {
    auto_initialize: bool,
    width: u32,
    height: u32,
    exclusive_zone: u32,
    layer: u2,
    anchors: WindowAnchors,
    margin: ?[4]u16,
};

pub const WindowAnchors = struct {
    top: bool,
    right: bool,
    bottom: bool,
    left: bool,
};
