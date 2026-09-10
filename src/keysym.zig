//! Layout-unabhängige Abbildung von XKB-Keysyms auf wio.Button.
//!
//! Der physische Keycode allein reicht nicht: Auf DE/CH-Layouts liegen Y/Z
//! vertauscht und "-", "+" und "/" auf anderen Tasten als auf US. Wer ein
//! Kürzel wie Ctrl+"-" bindet, meint das Zeichen, nicht die Tastenposition.
//! Deshalb übersetzt diese Tabelle das vom Layout erzeugte Keysym; nur wenn
//! sie null liefert, fällt der Aufrufer auf den Keycode zurück.

const std = @import("std");
const wio = @import("wio.zig");

/// Keysym-Konstanten aus xkbcommon-keysyms.h, soweit hier gebraucht.
const key_minus = 0x02d;
const key_plus = 0x02b;
const key_equal = 0x03d;
const key_slash = 0x02f;
const key_backslash = 0x05c;
const key_grave = 0x060;
const key_period = 0x02e;
const key_0 = 0x030;
const key_9 = 0x039;
const key_a = 0x061;
const key_z = 0x07a;
const key_upper_a = 0x041;
const key_upper_z = 0x05a;
const key_kp_multiply = 0xffaa;
const key_kp_add = 0xffab;
const key_kp_subtract = 0xffad;
const key_kp_decimal = 0xffae;
const key_kp_divide = 0xffaf;
const key_kp_0 = 0xffb0;
const key_kp_9 = 0xffb9;

pub fn toButton(sym: u32) ?wio.Button {
    return switch (sym) {
        key_a...key_z => letter(sym),
        key_upper_a...key_upper_z => letter(sym + 0x20),
        key_0...key_9 => digit(sym - key_0),
        key_minus => .minus,
        // wio kennt keine eigene Plus-Taste: "+" ist auf US Shift+"=", die
        // Kürzel-Tabelle bindet deshalb .equals.
        key_plus, key_equal => .equals,
        key_slash => .slash,
        key_backslash => .backslash,
        key_grave => .grave,
        key_period => .dot,
        key_kp_add => .kp_plus,
        key_kp_subtract => .kp_minus,
        key_kp_multiply => .kp_star,
        key_kp_divide => .kp_slash,
        key_kp_decimal => .kp_dot,
        key_kp_0...key_kp_9 => kpDigit(sym - key_kp_0),
        else => null,
    };
}

fn letter(sym: u32) wio.Button {
    const table = [_]wio.Button{ .a, .b, .c, .d, .e, .f, .g, .h, .i, .j, .k, .l, .m, .n, .o, .p, .q, .r, .s, .t, .u, .v, .w, .x, .y, .z };
    return table[sym - key_a];
}

fn digit(index: u32) wio.Button {
    const table = [_]wio.Button{ .@"0", .@"1", .@"2", .@"3", .@"4", .@"5", .@"6", .@"7", .@"8", .@"9" };
    return table[index];
}

fn kpDigit(index: u32) wio.Button {
    const table = [_]wio.Button{ .kp_0, .kp_1, .kp_2, .kp_3, .kp_4, .kp_5, .kp_6, .kp_7, .kp_8, .kp_9 };
    return table[index];
}

const testing = std.testing;

test "Buchstaben layout-unabhängig, auch mit Shift" {
    try testing.expectEqual(wio.Button.z, toButton(key_z).?);
    try testing.expectEqual(wio.Button.y, toButton(key_upper_a + ('y' - 'a')).?);
}

test "Zoom-Zeichen: -, +, = ergeben minus bzw. equals" {
    try testing.expectEqual(wio.Button.minus, toButton(key_minus).?);
    try testing.expectEqual(wio.Button.equals, toButton(key_plus).?);
    try testing.expectEqual(wio.Button.equals, toButton(key_equal).?);
}

test "Ziffernblock behält eigene Tasten" {
    try testing.expectEqual(wio.Button.kp_plus, toButton(key_kp_add).?);
    try testing.expectEqual(wio.Button.kp_minus, toButton(key_kp_subtract).?);
    try testing.expectEqual(wio.Button.kp_0, toButton(key_kp_0).?);
    try testing.expectEqual(wio.Button.kp_9, toButton(key_kp_9).?);
}

test "Ziffern und Satzzeichen" {
    try testing.expectEqual(wio.Button.@"0", toButton(key_0).?);
    try testing.expectEqual(wio.Button.@"7", toButton(key_0 + 7).?);
    try testing.expectEqual(wio.Button.slash, toButton(key_slash).?);
    try testing.expectEqual(wio.Button.grave, toButton(key_grave).?);
}

test "unbekanntes Keysym: Aufrufer fällt auf den Keycode zurück" {
    try testing.expect(toButton(0xff08) == null); // BackSpace
    try testing.expect(toButton(0) == null);
}
