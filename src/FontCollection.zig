const FontCollection = @This();
const std = @import("std");
const c = @import("c");
const hresult = @import("hresult.zig");
const utils = @import("utils.zig");
const FontFamily = @import("FontFamily.zig");
const Font = @import("Font.zig");
const FontFace = @import("FontFace.zig");

ref: *c.IDWriteFontCollection,

pub fn fromRef(ref: *c.IDWriteFontCollection) FontCollection {
    return .{ .ref = ref };
}

pub fn retain(self: FontCollection) FontCollection {
    _ = self.ref.lpVtbl.*.AddRef.?(self.ref);
    return self;
}

pub fn deinit(self: FontCollection) void {
    _ = self.ref.lpVtbl.*.Release.?(self.ref);
}

pub fn getFontFamilyCount(self: FontCollection) u32 {
    return self.ref.lpVtbl.*.GetFontFamilyCount.?(self.ref);
}

pub fn getFontFamily(self: FontCollection, index: u32) hresult.Error!FontFamily {
    var ref: ?*c.IDWriteFontFamily = null;
    try hresult.check(self.ref.lpVtbl.*.GetFontFamily.?(self.ref, index, @ptrCast(&ref)));

    return .fromRef(ref orelse return error.UnexpectedResult);
}

/// Looks up a UTF-8 family name. Null means absent.
pub fn findFamilyName(self: FontCollection, allocator: std.mem.Allocator, name: []const u8) !?u32 {
    const wide = try utils.toWide(allocator, name);
    defer allocator.free(wide);
    var index: u32 = 0;
    var exists: c.BOOL = 0;
    try hresult.check(self.ref.lpVtbl.*.FindFamilyName.?(self.ref, wide.ptr, &index, &exists));

    return if (exists != 0) index else null;
}

pub fn getFontFromFontFace(self: FontCollection, face: FontFace) hresult.Error!Font {
    var ref: ?*c.IDWriteFont = null;
    try hresult.check(self.ref.lpVtbl.*.GetFontFromFontFace.?(self.ref, face.ref, @ptrCast(&ref)));

    return .fromRef(ref orelse return error.UnexpectedResult);
}

/// Exact ASCII case-insensitive lookup. 
pub fn findFontByPostScriptName(self: FontCollection, allocator: std.mem.Allocator, name: []const u8) !?Font {
    if (!std.unicode.utf8ValidateSlice(name)) return error.InvalidUtf8;
    if (std.mem.indexOfScalar(u8, name, 0) != null) return error.EmbeddedNull;
    for (0..self.getFontFamilyCount()) |i| {
        const family = try self.getFontFamily(@intCast(i));
        defer family.deinit();
        if (try findFamilyFont(allocator, family, name)) |font| return font;
    }

    return null;
}

fn findFamilyFont(allocator: std.mem.Allocator, family: FontFamily, name: []const u8) !?Font {
    for (0..family.getFontCount()) |i| {
        const font = try family.getFont(@intCast(i));
        defer font.deinit();
        if (try hasPostScriptName(allocator, font, name)) return font.retain();
    }

    return null;
}

fn hasPostScriptName(allocator: std.mem.Allocator, font: Font, name: []const u8) !bool {
    const names = try font.getInformationalStrings(c.DWRITE_INFORMATIONAL_STRING_POSTSCRIPT_NAME) orelse return false;
    defer names.deinit();
    for (0..names.getCount()) |i| {
        const candidate = try names.getString(allocator, @intCast(i));
        defer allocator.free(candidate);
        if (std.ascii.eqlIgnoreCase(name, candidate)) return true;
    }

    return false;
}
