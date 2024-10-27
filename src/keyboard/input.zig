const TextInputClient = @import("../channels/textinput.zig").TextInputClient;
const EditingValue = @import("../channels/textinput.zig").EditingValue;

pub const TextInputManager = struct {
    current_client: ?TextInputClient = null,
    edit_state: ?EditingValue = null,
};
