const udev = @import("udev.zig");
const hid = @import("hid.zig");

pub fn udev_to_hid(key: i64) i64 {
    switch (key) {
        udev.KEY_ESC => return hid.KEY_ESC,
        udev.KEY_1 => return hid.KEY_1,
        udev.KEY_2 => return hid.KEY_2,
        udev.KEY_3 => return hid.KEY_3,
        udev.KEY_4 => return hid.KEY_4,
        udev.KEY_5 => return hid.KEY_5,
        udev.KEY_6 => return hid.KEY_6,
        udev.KEY_7 => return hid.KEY_7,
        udev.KEY_8 => return hid.KEY_8,
        udev.KEY_9 => return hid.KEY_9,
        udev.KEY_0 => return hid.KEY_0,
        udev.KEY_MINUS => return hid.KEY_MINUS,
        udev.KEY_EQUAL => return hid.KEY_EQUAL,
        udev.KEY_BACKSPACE => return hid.KEY_BACKSPACE,
        udev.KEY_TAB => return hid.KEY_TAB,
        udev.KEY_Q => return hid.KEY_Q,
        udev.KEY_W => return hid.KEY_W,
        udev.KEY_E => return hid.KEY_E,
        udev.KEY_R => return hid.KEY_R,
        udev.KEY_T => return hid.KEY_T,
        udev.KEY_Y => return hid.KEY_Y,
        udev.KEY_U => return hid.KEY_U,
        udev.KEY_I => return hid.KEY_I,
        udev.KEY_O => return hid.KEY_O,
        udev.KEY_P => return hid.KEY_P,
        udev.KEY_LEFTBRACE => return hid.KEY_LEFTBRACE,
        udev.KEY_RIGHTBRACE => return hid.KEY_RIGHTBRACE,
        udev.KEY_ENTER => return hid.KEY_ENTER,
        udev.KEY_LEFTCTRL => return hid.KEY_LEFTCTRL,
        udev.KEY_A => return hid.KEY_A,
        udev.KEY_S => return hid.KEY_S,
        udev.KEY_D => return hid.KEY_D,
        udev.KEY_F => return hid.KEY_F,
        udev.KEY_G => return hid.KEY_G,
        udev.KEY_H => return hid.KEY_H,
        udev.KEY_J => return hid.KEY_J,
        udev.KEY_K => return hid.KEY_K,
        udev.KEY_L => return hid.KEY_L,
        udev.KEY_SEMICOLON => return hid.KEY_SEMICOLON,
        udev.KEY_APOSTROPHE => return hid.KEY_APOSTROPHE,
        udev.KEY_GRAVE => return hid.KEY_GRAVE,
        udev.KEY_LEFTSHIFT => return hid.KEY_LEFTSHIFT,
        udev.KEY_BACKSLASH => return hid.KEY_BACKSLASH,
        udev.KEY_Z => return hid.KEY_Z,
        udev.KEY_X => return hid.KEY_X,
        udev.KEY_C => return hid.KEY_C,
        udev.KEY_V => return hid.KEY_V,
        udev.KEY_B => return hid.KEY_B,
        udev.KEY_N => return hid.KEY_N,
        udev.KEY_M => return hid.KEY_M,
        udev.KEY_COMMA => return hid.KEY_COMMA,
        udev.KEY_DOT => return hid.KEY_DOT,
        udev.KEY_SLASH => return hid.KEY_SLASH,
        udev.KEY_RIGHTSHIFT => return hid.KEY_RIGHTSHIFT,
        udev.KEY_KPASTERISK => return hid.KEY_KPASTERISK,
        udev.KEY_LEFTALT => return hid.KEY_LEFTALT,
        udev.KEY_SPACE => return hid.KEY_SPACE,
        udev.KEY_CAPSLOCK => return hid.KEY_CAPSLOCK,
        udev.KEY_F1 => return hid.KEY_F1,
        udev.KEY_F2 => return hid.KEY_F2,
        udev.KEY_F3 => return hid.KEY_F3,
        udev.KEY_F4 => return hid.KEY_F4,
        udev.KEY_F5 => return hid.KEY_F5,
        udev.KEY_F6 => return hid.KEY_F6,
        udev.KEY_F7 => return hid.KEY_F7,
        udev.KEY_F8 => return hid.KEY_F8,
        udev.KEY_F9 => return hid.KEY_F9,
        udev.KEY_F10 => return hid.KEY_F10,
        udev.KEY_NUMLOCK => return hid.KEY_NUMLOCK,
        udev.KEY_SCROLLLOCK => return hid.KEY_SCROLLLOCK,
        udev.KEY_KP7 => return hid.KEY_KP7,
        udev.KEY_KP8 => return hid.KEY_KP8,
        udev.KEY_KP9 => return hid.KEY_KP9,
        udev.KEY_KPMINUS => return hid.KEY_KPMINUS,
        udev.KEY_KP4 => return hid.KEY_KP4,
        udev.KEY_KP5 => return hid.KEY_KP5,
        udev.KEY_KP6 => return hid.KEY_KP6,
        udev.KEY_KPPLUS => return hid.KEY_KPPLUS,
        udev.KEY_KP1 => return hid.KEY_KP1,
        udev.KEY_KP2 => return hid.KEY_KP2,
        udev.KEY_KP3 => return hid.KEY_KP3,
        udev.KEY_KP0 => return hid.KEY_KP0,
        udev.KEY_KPDOT => return hid.KEY_KPDOT,
        udev.KEY_ZENKAKUHANKAKU => return hid.KEY_ZENKAKUHANKAKU,
        udev.KEY_102ND => return hid.KEY_102ND,
        udev.KEY_F11 => return hid.KEY_F11,
        udev.KEY_F12 => return hid.KEY_F12,
        udev.KEY_RO => return hid.KEY_RO,
        udev.KEY_KATAKANA => return hid.KEY_KATAKANA,
        udev.KEY_HIRAGANA => return hid.KEY_HIRAGANA,
        udev.KEY_HENKAN => return hid.KEY_HENKAN,
        udev.KEY_KATAKANAHIRAGANA => return hid.KEY_KATAKANAHIRAGANA,
        udev.KEY_MUHENKAN => return hid.KEY_MUHENKAN,
        udev.KEY_KPJPCOMMA => return hid.KEY_KPJPCOMMA,
        udev.KEY_KPENTER => return hid.KEY_KPENTER,
        udev.KEY_RIGHTCTRL => return hid.KEY_RIGHTCTRL,
        udev.KEY_KPSLASH => return hid.KEY_KPSLASH,
        udev.KEY_SYSRQ => return hid.KEY_SYSRQ,
        udev.KEY_RIGHTALT => return hid.KEY_RIGHTALT,
        // udev.KEY_LINEFEED => return hid.KEY_LINEFEED,
        udev.KEY_HOME => return hid.KEY_HOME,
        udev.KEY_UP => return hid.KEY_UP,
        udev.KEY_PAGEUP => return hid.KEY_PAGEUP,
        udev.KEY_LEFT => return hid.KEY_LEFT,
        udev.KEY_RIGHT => return hid.KEY_RIGHT,
        udev.KEY_END => return hid.KEY_END,
        udev.KEY_DOWN => return hid.KEY_DOWN,
        udev.KEY_PAGEDOWN => return hid.KEY_PAGEDOWN,
        udev.KEY_INSERT => return hid.KEY_INSERT,
        udev.KEY_DELETE => return hid.KEY_DELETE,
        // udev.KEY_MACRO => return hid.KEY_MACRO,
        udev.KEY_MUTE => return hid.KEY_MUTE,
        udev.KEY_VOLUMEDOWN => return hid.KEY_VOLUMEDOWN,
        udev.KEY_VOLUMEUP => return hid.KEY_VOLUMEUP,
        udev.KEY_POWER => return hid.KEY_POWER,
        udev.KEY_KPEQUAL => return hid.KEY_KPEQUAL,
        // udev.KEY_KPPLUSMINUS => return hid.KEY_KPPLUSMINUS,
        udev.KEY_PAUSE => return hid.KEY_PAUSE,
        // udev.KEY_SCALE => return hid.KEY_SCALE,

        udev.KEY_KPCOMMA => return hid.KEY_KPCOMMA,
        udev.KEY_HANGEUL => return hid.KEY_HANGEUL,
        // udev.KEY_HANGUEL => return hid.KEY_HANGUEL,
        udev.KEY_HANJA => return hid.KEY_HANJA,
        udev.KEY_YEN => return hid.KEY_YEN,
        udev.KEY_LEFTMETA => return hid.KEY_LEFTMETA,
        udev.KEY_RIGHTMETA => return hid.KEY_RIGHTMETA,
        udev.KEY_COMPOSE => return hid.KEY_COMPOSE,
        udev.KEY_STOP => return hid.KEY_STOP,
        udev.KEY_AGAIN => return hid.KEY_AGAIN,
        udev.KEY_PROPS => return hid.KEY_PROPS,
        udev.KEY_UNDO => return hid.KEY_UNDO,
        udev.KEY_FRONT => return hid.KEY_FRONT,
        udev.KEY_COPY => return hid.KEY_COPY,
        udev.KEY_OPEN => return hid.KEY_OPEN,
        udev.KEY_PASTE => return hid.KEY_PASTE,
        udev.KEY_FIND => return hid.KEY_FIND,
        udev.KEY_CUT => return hid.KEY_CUT,
        udev.KEY_HELP => return hid.KEY_HELP,
        // udev.KEY_MENU => return hid.KEY_MENU,
        // udev.KEY_CALC => return hid.KEY_CALC,
        // udev.KEY_SETUP => return hid.KEY_SETUP,
        // udev.KEY_SLEEP => return hid.KEY_SLEEP,
        // udev.KEY_WAKEUP => return hid.KEY_WAKEUP,
        // udev.KEY_FILE => return hid.KEY_FILE,
        // udev.KEY_SENDFILE => return hid.KEY_SENDFILE,
        // udev.KEY_DELETEFILE => return hid.KEY_DELETEFILE,
        // udev.KEY_XFER => return hid.KEY_XFER,
        // udev.KEY_PROG1 => return hid.KEY_PROG1,
        // udev.KEY_PROG2 => return hid.KEY_PROG2,
        // udev.KEY_WWW => return hid.KEY_WWW,
        // udev.KEY_MSDOS => return hid.KEY_MSDOS,
        // udev.KEY_COFFEE => return hid.KEY_COFFEE,
        // udev.KEY_SCREENLOCK => return hid.KEY_SCREENLOCK,
        // udev.KEY_ROTATE_DISPLAY => return hid.KEY_ROTATE_DISPLAY,
        // udev.KEY_DIRECTION => return hid.KEY_DIRECTION,
        // udev.KEY_CYCLEWINDOWS => return hid.KEY_CYCLEWINDOWS,
        // udev.KEY_MAIL => return hid.KEY_MAIL,
        // udev.KEY_BOOKMARKS => return hid.KEY_BOOKMARKS,
        // udev.KEY_COMPUTER => return hid.KEY_COMPUTER,
        // udev.KEY_BACK => return hid.KEY_BACK,
        // udev.KEY_FORWARD => return hid.KEY_FORWARD,
        // udev.KEY_CLOSECD => return hid.KEY_CLOSECD,
        // udev.KEY_EJECTCD => return hid.KEY_EJECTCD,
        // udev.KEY_EJECTCLOSECD => return hid.KEY_EJECTCLOSECD,
        // udev.KEY_NEXTSONG => return hid.KEY_NEXTSONG,
        // udev.KEY_PLAYPAUSE => return hid.KEY_PLAYPAUSE,
        // udev.KEY_PREVIOUSSONG => return hid.KEY_PREVIOUSSONG,
        // udev.KEY_STOPCD => return hid.KEY_STOPCD,
        // udev.KEY_RECORD => return hid.KEY_RECORD,
        // udev.KEY_REWIND => return hid.KEY_REWIND,
        // udev.KEY_PHONE => return hid.KEY_PHONE,
        // udev.KEY_ISO => return hid.KEY_ISO,
        // udev.KEY_CONFIG => return hid.KEY_CONFIG,
        // udev.KEY_HOMEPAGE => return hid.KEY_HOMEPAGE,
        // udev.KEY_REFRESH => return hid.KEY_REFRESH,
        // udev.KEY_EXIT => return hid.KEY_EXIT,
        // udev.KEY_MOVE => return hid.KEY_MOVE,
        // udev.KEY_EDIT => return hid.KEY_EDIT,
        // udev.KEY_SCROLLUP => return hid.KEY_SCROLLUP,
        // udev.KEY_SCROLLDOWN => return hid.KEY_SCROLLDOWN,
        udev.KEY_KPLEFTPAREN => return hid.KEY_KPLEFTPAREN,
        udev.KEY_KPRIGHTPAREN => return hid.KEY_KPRIGHTPAREN,
        // udev.KEY_NEW => return hid.KEY_NEW,
        // udev.KEY_REDO => return hid.KEY_REDO,
        udev.KEY_F13 => return hid.KEY_F13,
        udev.KEY_F14 => return hid.KEY_F14,
        udev.KEY_F15 => return hid.KEY_F15,
        udev.KEY_F16 => return hid.KEY_F16,
        udev.KEY_F17 => return hid.KEY_F17,
        udev.KEY_F18 => return hid.KEY_F18,
        udev.KEY_F19 => return hid.KEY_F19,
        udev.KEY_F20 => return hid.KEY_F20,
        udev.KEY_F21 => return hid.KEY_F21,
        udev.KEY_F22 => return hid.KEY_F22,
        udev.KEY_F23 => return hid.KEY_F23,
        udev.KEY_F24 => return hid.KEY_F24,
        // udev.KEY_PLAYCD => return hid.KEY_PLAYCD,
        // udev.KEY_PAUSECD => return hid.KEY_PAUSECD,
        // udev.KEY_PROG3 => return hid.KEY_PROG3,
        // udev.KEY_PROG4 => return hid.KEY_PROG4,
        // udev.KEY_ALL_APPLICATIONS => return hid.KEY_ALL_APPLICATIONS,
        // udev.KEY_DASHBOARD => return hid.KEY_DASHBOARD,
        // udev.KEY_SUSPEND => return hid.KEY_SUSPEND,
        // udev.KEY_CLOSE => return hid.KEY_CLOSE,
        // udev.KEY_PLAY => return hid.KEY_PLAY,
        // udev.KEY_FASTFORWARD => return hid.KEY_FASTFORWARD,
        // udev.KEY_BASSBOOST => return hid.KEY_BASSBOOST,
        // udev.KEY_PRINT => return hid.KEY_PRINT,
        // udev.KEY_HP => return hid.KEY_HP,
        // udev.KEY_CAMERA => return hid.KEY_CAMERA,
        // udev.KEY_SOUND => return hid.KEY_SOUND,
        // udev.KEY_QUESTION => return hid.KEY_QUESTION,
        // udev.KEY_EMAIL => return hid.KEY_EMAIL,
        // udev.KEY_CHAT => return hid.KEY_CHAT,
        // udev.KEY_SEARCH => return hid.KEY_SEARCH,
        // udev.KEY_CONNECT => return hid.KEY_CONNECT,
        // udev.KEY_FINANCE => return hid.KEY_FINANCE,
        // udev.KEY_SPORT => return hid.KEY_SPORT,
        // udev.KEY_SHOP => return hid.KEY_SHOP,
        // udev.KEY_ALTERASE => return hid.KEY_ALTERASE,
        // udev.KEY_CANCEL => return hid.KEY_CANCEL,
        // udev.KEY_BRIGHTNESSDOWN => return hid.KEY_BRIGHTNESSDOWN,
        // udev.KEY_BRIGHTNESSUP => return hid.KEY_BRIGHTNESSUP,
        // udev.KEY_MEDIA => return hid.KEY_MEDIA,
        // udev.KEY_SWITCHVIDEOMODE => return hid.KEY_SWITCHVIDEOMODE,
        // udev.KEY_KBDILLUMTOGGLE => return hid.KEY_KBDILLUMTOGGLE,
        // udev.KEY_KBDILLUMDOWN => return hid.KEY_KBDILLUMDOWN,
        // udev.KEY_KBDILLUMUP => return hid.KEY_KBDILLUMUP,
        // udev.KEY_SEND => return hid.KEY_SEND,
        // udev.KEY_REPLY => return hid.KEY_REPLY,
        // udev.KEY_FORWARDMAIL => return hid.KEY_FORWARDMAIL,
        // udev.KEY_SAVE => return hid.KEY_SAVE,
        // udev.KEY_DOCUMENTS => return hid.KEY_DOCUMENTS,
        // udev.KEY_BATTERY => return hid.KEY_BATTERY,
        // udev.KEY_BLUETOOTH => return hid.KEY_BLUETOOTH,
        // udev.KEY_WLAN => return hid.KEY_WLAN,
        // udev.KEY_UWB => return hid.KEY_UWB,
        // udev.KEY_UNKNOWN => return hid.KEY_UNKNOWN,
        // udev.KEY_VIDEO_NEXT => return hid.KEY_VIDEO_NEXT,
        // udev.KEY_VIDEO_PREV => return hid.KEY_VIDEO_PREV,
        // udev.KEY_BRIGHTNESS_CYCLE => return hid.KEY_BRIGHTNESS_CYCLE,
        // udev.KEY_BRIGHTNESS_AUTO => return hid.KEY_BRIGHTNESS_AUTO,
        // udev.KEY_BRIGHTNESS_ZERO => return hid.KEY_BRIGHTNESS_ZERO,
        // udev.KEY_DISPLAY_OFF => return hid.KEY_DISPLAY_OFF,
        // udev.KEY_WWAN => return hid.KEY_WWAN,
        // udev.KEY_WIMAX => return hid.KEY_WIMAX,
        // udev.KEY_RFKILL => return hid.KEY_RFKILL,
        // udev.KEY_MICMUTE => return hid.KEY_MICMUTE,
        else => return 0,
    }
}
