const FontFace = @This();
const std = @import("std");
const c = @import("c");
const hresult = @import("hresult.zig");
const FontTable = @import("FontTable.zig");

ref: *c.IDWriteFontFace,

pub fn fromRef(ref: *c.IDWriteFontFace) FontFace {
    return .{ .ref = ref };
}

pub fn retain(self: FontFace) FontFace {
    _ = self.ref.lpVtbl.*.AddRef.?(self.ref);
    return self;
}

pub fn deinit(self: FontFace) void {
    _ = self.ref.lpVtbl.*.Release.?(self.ref);
}

pub fn getType(self: FontFace) c.DWRITE_FONT_FACE_TYPE {
    return self.ref.lpVtbl.*.GetType.?(self.ref);
}

pub fn getIndex(self: FontFace) u32 {
    return self.ref.lpVtbl.*.GetIndex.?(self.ref);
}

pub fn getGlyphCount(self: FontFace) u16 {
    return self.ref.lpVtbl.*.GetGlyphCount.?(self.ref);
}

pub fn getMetrics(self: FontFace) c.DWRITE_FONT_METRICS {
    var metrics: c.DWRITE_FONT_METRICS = undefined;
    self.ref.lpVtbl.*.GetMetrics.?(self.ref, &metrics);

    return metrics;
}

pub fn getGlyphIndices(self: FontFace, allocator: std.mem.Allocator, codepoints: []const u32) ![]u16 {
    const count = std.math.cast(u32, codepoints.len) orelse return error.InputTooLong;
    const glyphs = try allocator.alloc(u16, codepoints.len);
    errdefer allocator.free(glyphs);

    if (count != 0) try hresult.check(self.ref.lpVtbl.*.GetGlyphIndices.?(
        self.ref,
        codepoints.ptr,
        count,
        glyphs.ptr,
    ));
    return glyphs;
}

pub fn getDesignGlyphMetrics(
    self: FontFace,
    allocator: std.mem.Allocator,
    glyphs: []const u16,
    sideways: bool,
) ![]c.DWRITE_GLYPH_METRICS {
    const count = std.math.cast(u32, glyphs.len) orelse return error.InputTooLong;
    const metrics = try allocator.alloc(c.DWRITE_GLYPH_METRICS, glyphs.len);
    errdefer allocator.free(metrics);

    if (count != 0) try hresult.check(self.ref.lpVtbl.*.GetDesignGlyphMetrics.?(
        self.ref,
        glyphs.ptr,
        count,
        metrics.ptr,
        @intFromBool(sideways),
    ));
    return metrics;
}

/// Uses a native DWRITE_MAKE_OPENTYPE_TAG value. The returned table owns its lease.
pub fn tryGetFontTable(self: FontFace, tag: u32) hresult.Error!?FontTable {
    var data: ?*const anyopaque = null;
    var size: u32 = 0;
    var context: ?*anyopaque = null;
    var exists: c.BOOL = 0;
    try hresult.check(self.ref.lpVtbl.*.TryGetFontTable.?(
        self.ref,
        tag,
        &data,
        &size,
        &context,
        &exists,
    ));

    if (exists == 0) return null;
    errdefer self.ref.lpVtbl.*.ReleaseFontTable.?(self.ref, context);
    const bytes: []const u8 = if (size == 0)
        &.{}
    else
        @as([*]const u8, @ptrCast(data orelse return error.UnexpectedResult))[0..size];
    return .{
        .bytes = bytes,
        .face = self.retain(),
        .context = context,
    };
}
