const LocalizedStrings = @This();
const std = @import("std");
const c = @import("c");
const hresult = @import("hresult.zig");
const utils = @import("utils.zig");

ref: *c.IDWriteLocalizedStrings,

pub fn fromRef(ref: *c.IDWriteLocalizedStrings) LocalizedStrings {
    return .{ .ref = ref };
}

pub fn retain(self: LocalizedStrings) LocalizedStrings {
    _ = self.ref.lpVtbl.*.AddRef.?(self.ref);
    return self;
}

pub fn deinit(self: LocalizedStrings) void {
    _ = self.ref.lpVtbl.*.Release.?(self.ref);
}

pub fn getCount(self: LocalizedStrings) u32 {
    return self.ref.lpVtbl.*.GetCount.?(self.ref);
}

/// The caller chooses the locale; null means there is no entry for it.
pub fn findLocaleName(self: LocalizedStrings, allocator: std.mem.Allocator, locale: []const u8) !?u32 {
    const wide = try utils.toWide(allocator, locale);
    defer allocator.free(wide);
    var index: u32 = 0;
    var exists: c.BOOL = 0;
    try hresult.check(self.ref.lpVtbl.*.FindLocaleName.?(self.ref, wide.ptr, &index, &exists));
    return if (exists != 0) index else null;
}

/// Returns owned UTF-8 bytes. Free them with allocator.free().
pub fn getString(self: LocalizedStrings, allocator: std.mem.Allocator, index: u32) ![]u8 {
    var length: u32 = 0;
    try hresult.check(self.ref.lpVtbl.*.GetStringLength.?(self.ref, index, &length));
    const capacity = std.math.add(u32, length, 1) catch return error.InputTooLong;
    const wide = try allocator.alloc(u16, capacity);
    defer allocator.free(wide);
    try hresult.check(self.ref.lpVtbl.*.GetString.?(self.ref, index, wide.ptr, capacity));
    return std.unicode.utf16LeToUtf8Alloc(allocator, wide[0..length]);
}

/// Returns an owned UTF-8 locale name, without choosing a fallback locale.
pub fn getLocaleName(self: LocalizedStrings, allocator: std.mem.Allocator, index: u32) ![]u8 {
    var length: u32 = 0;
    try hresult.check(self.ref.lpVtbl.*.GetLocaleNameLength.?(self.ref, index, &length));
    const capacity = std.math.add(u32, length, 1) catch return error.InputTooLong;
    const wide = try allocator.alloc(u16, capacity);
    defer allocator.free(wide);
    try hresult.check(self.ref.lpVtbl.*.GetLocaleName.?(self.ref, index, wide.ptr, capacity));
    return std.unicode.utf16LeToUtf8Alloc(allocator, wide[0..length]);
}

test "LocalizedStrings locale lookup and owned UTF-8 output" {
    const allocator = std.testing.allocator;
    const factory = try @import("Factory.zig").init(c.DWRITE_FACTORY_TYPE_SHARED);
    defer factory.deinit();
    const collection = try factory.getSystemFontCollection(false);
    defer collection.deinit();
    const family = try collection.getFontFamily(0);
    defer family.deinit();
    const original = try family.getFamilyNames();
    const names = original.retain();
    original.deinit();
    defer names.deinit();
    try std.testing.expect(names.getCount() > 0);
    const locale = try names.getLocaleName(allocator, 0);
    defer allocator.free(locale);
    try std.testing.expectEqual(@as(?u32, 0), try names.findLocaleName(allocator, locale));
    try std.testing.expectEqual(null, try names.findLocaleName(allocator, "zz-ZZ-missing"));
    const text = blk: {
        const owner = try family.getFamilyNames();
        defer owner.deinit();
        break :blk try owner.getString(allocator, 0);
    };
    defer allocator.free(text);
    try std.testing.expect(text.len > 0);
}
