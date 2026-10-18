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
