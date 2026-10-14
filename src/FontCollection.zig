const FontCollection = @This();
const std = @import("std");
const c = @import("c");
const hresult = @import("hresult.zig");
const utils = @import("utils.zig");
const FontFamily = @import("FontFamily.zig");

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

/// Looks up a UTF-8 family name. Null means absent, without font substitution.
pub fn findFamilyName(self: FontCollection, allocator: std.mem.Allocator, name: []const u8) !?u32 {
    const wide = try utils.toWide(allocator, name);
    defer allocator.free(wide);
    var index: u32 = 0;
    var exists: c.BOOL = 0;
    try hresult.check(self.ref.lpVtbl.*.FindFamilyName.?(self.ref, wide.ptr, &index, &exists));

    return if (exists != 0) index else null;
}
