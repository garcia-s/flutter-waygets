const c = @import("../c_imports.zig").c;

pub const XKBState = struct {
    fd: i32 = 0,
    size: u32 = 0,
    compose: ?*c.struct_xkb_compose_state = null,
    context: ?*c.struct_xkb_context = null,
    state: ?*c.struct_xkb_state = null,
};
