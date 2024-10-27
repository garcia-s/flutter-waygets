pub const TextInputClient = struct {
    viewId: i64,
    obscureText: bool,
    autocorrect: bool,
    smartDashesType: u32,
    smartQuotesType: u32,
    enableSuggestions: bool,
    enableInteractiveSelection: bool,
    actionLabel: ?[]u8,
    inputAction: []u8,
    textCapitalization: []u8,
    keyboardAppearance: []u8,
    enableIMEPersonalizedLearning: bool,
    contentCommitMimeTypes: [][]u8,
    enableDeltaModel: bool,
    inputType: InputType,
    EditingValue: EditingValue,
    autofill: AutoFill,
};

const InputType = struct {
    //FIXME: I don't know if this is the correct type
    signed: ?[]u8,
    decimal: ?[]u8,
    readOnly: bool,
};

pub const EditingValue = struct {
    text: []u8,
    selectionBase: i32,
    selectionExtent: i32,
    selectionAffinity: []u8,
    selectionIsDirectional: bool,
    composingBase: i32,
    composingExtent: i32,
};

const AutoFill = struct {
    uniqueIdentifier: []u8,
    hints: [][]u8,
    editingValue: EditingValue,
};
