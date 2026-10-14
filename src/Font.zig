const Font = @This();
const std = @import("std");
const c = @import("c");
const hresult = @import("hresult.zig");
const FontFamily = @import("FontFamily.zig");
const FontFace = @import("FontFace.zig");
const LocalizedStrings = @import("LocalizedStrings.zig");

ref: *c.IDWriteFont,

pub fn fromRef(ref: *c.IDWriteFont) Font {
    return .{ .ref = ref };
}

pub fn retain(self: Font) Font {
    _ = self.ref.lpVtbl.*.AddRef.?(self.ref);
    return self;
}

pub fn deinit(self: Font) void {
    _ = self.ref.lpVtbl.*.Release.?(self.ref);
}

pub fn getFontFamily(self: Font) hresult.Error!FontFamily {
    var ref: ?*c.IDWriteFontFamily = null;
    try hresult.check(self.ref.lpVtbl.*.GetFontFamily.?(self.ref, @ptrCast(&ref)));

    return .fromRef(ref orelse return error.UnexpectedResult);
}

pub fn getFaceNames(self: Font) hresult.Error!LocalizedStrings {
    var ref: ?*c.IDWriteLocalizedStrings = null;
    try hresult.check(self.ref.lpVtbl.*.GetFaceNames.?(self.ref, @ptrCast(&ref)));

    return .fromRef(ref orelse return error.UnexpectedResult);
}

pub fn getInformationalStrings(self: Font, id: c.DWRITE_INFORMATIONAL_STRING_ID) hresult.Error!?LocalizedStrings {
    var ref: ?*c.IDWriteLocalizedStrings = null;
    var exists: c.BOOL = 0;
    try hresult.check(self.ref.lpVtbl.*.GetInformationalStrings.?(self.ref, id, @ptrCast(&ref), &exists));
    if (exists == 0) return null;

    return .fromRef(ref orelse return error.UnexpectedResult);
}

pub fn getWeight(self: Font) c.DWRITE_FONT_WEIGHT {
    return self.ref.lpVtbl.*.GetWeight.?(self.ref);
}

pub fn getStretch(self: Font) c.DWRITE_FONT_STRETCH {
    return self.ref.lpVtbl.*.GetStretch.?(self.ref);
}

pub fn getStyle(self: Font) c.DWRITE_FONT_STYLE {
    return self.ref.lpVtbl.*.GetStyle.?(self.ref);
}

pub fn getSimulations(self: Font) c.DWRITE_FONT_SIMULATIONS {
    return self.ref.lpVtbl.*.GetSimulations.?(self.ref);
}

pub fn getMetrics(self: Font) c.DWRITE_FONT_METRICS {
    var metrics: c.DWRITE_FONT_METRICS = undefined;
    self.ref.lpVtbl.*.GetMetrics.?(self.ref, &metrics);

    return metrics;
}

pub fn hasCharacter(self: Font, codepoint: u21) hresult.Error!bool {
    var exists: c.BOOL = 0;
    try hresult.check(self.ref.lpVtbl.*.HasCharacter.?(self.ref, codepoint, &exists));

    return exists != 0;
}

pub fn createFontFace(self: Font) hresult.Error!FontFace {
    var ref: ?*c.IDWriteFontFace = null;
    try hresult.check(self.ref.lpVtbl.*.CreateFontFace.?(self.ref, @ptrCast(&ref)));

    return .fromRef(ref orelse return error.UnexpectedResult);
}
