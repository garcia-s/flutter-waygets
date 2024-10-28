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
    selectionBase: u32,
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

// {
//     "viewId": 1,
//     "inputType": {
//         "name": "TextInputType.text",
//         "signed": null,
//         "decimal": null
//     },
//     "readOnly": false,
//     "obscureText": false,
//     "autocorrect": true,
//     "smartDashesType": "1",
//     "smartQuotesType": "1",
//     "enableSuggestions": true,
//     "enableInteractiveSelection": true,
//     "actionLabel": null,
//     "inputAction": "TextInputAction.done",
//     "textCapitalization": "TextCapitalization.none",
//     "keyboardAppearance": "Brightness.light",
//     "enableIMEPersonalizedLearning": true,
//     "contentCommitMimeTypes": [],
//     "autofill": {
//         "uniqueIdentifier": "EditableText-575586381",
//         "hints": [],
//         "editingValue": {
//             "text": "",
//             "selectionBase": -1,
//             "selectionExtent": -1,
//             "selectionAffinity": "TextAffinity.downstream",
//             "selectionIsDirectional": false,
//             "composingBase": -1,
//             "composingExtent": -1
//         }
//     },
//     "enableDeltaModel": false
// }
