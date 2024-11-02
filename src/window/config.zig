pub const WindowConfig = struct {
    name: []u8,
    width: u32,
    height: u32,
    exclusive_zone: u32,
    layer: u2,
    margin: ?[4]u16,
    anchors: WindowAnchors,
    keyboard_interactivity: u2,
};

pub const WindowAnchors = struct {
    top: bool,
    right: bool,
    bottom: bool,
    left: bool,
};
