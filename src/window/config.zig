pub const WindowConfig = struct {
    name: [:0]u8,
    width: u32,
    height: u32,
    exclusive_zone: i16,
    layer: u8,
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
