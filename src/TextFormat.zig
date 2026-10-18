const TextFormat = @This();
const c = @import("c");
const hresult = @import("hresult.zig");
const FontCollection = @import("FontCollection.zig");

pub const Options = struct {
    family_name: []const u8,
    collection: ?FontCollection = null,
    weight: c.DWRITE_FONT_WEIGHT = c.DWRITE_FONT_WEIGHT_NORMAL,
    style: c.DWRITE_FONT_STYLE = c.DWRITE_FONT_STYLE_NORMAL,
    stretch: c.DWRITE_FONT_STRETCH = c.DWRITE_FONT_STRETCH_NORMAL,
    size: f32,
    locale: []const u8,
};

ref: *c.IDWriteTextFormat,

pub fn fromRef(ref: *c.IDWriteTextFormat) TextFormat {
    return .{ .ref = ref };
}

pub fn retain(self: TextFormat) TextFormat {
    _ = self.ref.lpVtbl.*.AddRef.?(self.ref);
    return self;
}

pub fn deinit(self: TextFormat) void {
    _ = self.ref.lpVtbl.*.Release.?(self.ref);
}

pub fn setWordWrapping(self: TextFormat, wrapping: c.DWRITE_WORD_WRAPPING) hresult.Error!void {
    try hresult.check(self.ref.lpVtbl.*.SetWordWrapping.?(self.ref, wrapping));
}

pub fn setReadingDirection(self: TextFormat, direction: c.DWRITE_READING_DIRECTION) hresult.Error!void {
    try hresult.check(self.ref.lpVtbl.*.SetReadingDirection.?(self.ref, direction));
}

pub fn setTextAlignment(self: TextFormat, alignment: c.DWRITE_TEXT_ALIGNMENT) hresult.Error!void {
    try hresult.check(self.ref.lpVtbl.*.SetTextAlignment.?(self.ref, alignment));
}

test "TextFormat creation and formatting options" {
    const std = @import("std");
    const factory = try @import("Factory.zig").init(c.DWRITE_FACTORY_TYPE_SHARED);
    defer factory.deinit();
    const format = try factory.createTextFormat(std.testing.allocator, .{
        .family_name = "Segoe UI",
        .size = 16,
        .locale = "en-US",
    });
    defer format.deinit();

    try std.testing.expectEqual(@as(f32, 16), format.ref.lpVtbl.*.GetFontSize.?(format.ref));

    try format.setWordWrapping(c.DWRITE_WORD_WRAPPING_NO_WRAP);
    try std.testing.expectEqual(@as(c.DWRITE_WORD_WRAPPING, c.DWRITE_WORD_WRAPPING_NO_WRAP), format.ref.lpVtbl.*.GetWordWrapping.?(format.ref));

    try format.setReadingDirection(c.DWRITE_READING_DIRECTION_RIGHT_TO_LEFT);
    try std.testing.expectEqual(@as(c.DWRITE_READING_DIRECTION, c.DWRITE_READING_DIRECTION_RIGHT_TO_LEFT), format.ref.lpVtbl.*.GetReadingDirection.?(format.ref));

    try format.setTextAlignment(c.DWRITE_TEXT_ALIGNMENT_CENTER);
    try std.testing.expectEqual(@as(c.DWRITE_TEXT_ALIGNMENT, c.DWRITE_TEXT_ALIGNMENT_CENTER), format.ref.lpVtbl.*.GetTextAlignment.?(format.ref));
}
