const FontFamily = @This();
const std = @import("std");
const c = @import("c");
const hresult = @import("hresult.zig");
const Font = @import("Font.zig");
const LocalizedStrings = @import("LocalizedStrings.zig");

ref: *c.IDWriteFontFamily,

pub fn fromRef(ref: *c.IDWriteFontFamily) FontFamily {
    return .{ .ref = ref };
}

pub fn retain(self: FontFamily) FontFamily {
    _ = self.ref.lpVtbl.*.AddRef.?(self.ref);
    return self;
}

pub fn deinit(self: FontFamily) void {
    _ = self.ref.lpVtbl.*.Release.?(self.ref);
}

pub fn getFamilyNames(self: FontFamily) hresult.Error!LocalizedStrings {
    var ref: ?*c.IDWriteLocalizedStrings = null;
    try hresult.check(self.ref.lpVtbl.*.GetFamilyNames.?(self.ref, @ptrCast(&ref)));

    return .fromRef(ref orelse return error.UnexpectedResult);
}

pub fn getFontCount(self: FontFamily) u32 {
    return self.ref.lpVtbl.*.GetFontCount.?(self.ref);
}

pub fn getFont(self: FontFamily, index: u32) hresult.Error!Font {
    var ref: ?*c.IDWriteFont = null;
    try hresult.check(self.ref.lpVtbl.*.GetFont.?(self.ref, index, @ptrCast(&ref)));

    return .fromRef(ref orelse return error.UnexpectedResult);
}
