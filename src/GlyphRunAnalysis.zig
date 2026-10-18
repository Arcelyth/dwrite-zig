const GlyphRunAnalysis = @This();
const std = @import("std");
const c = @import("c");
const hresult = @import("hresult.zig");

pub const Options = struct {
    pixels_per_dip: f32 = 1,
    transform: ?*const c.DWRITE_MATRIX = null,
    /// Must be a raster rendering mode, neither DEFAULT nor OUTLINE.
    rendering_mode: c.DWRITE_RENDERING_MODE,
    measuring_mode: c.DWRITE_MEASURING_MODE = c.DWRITE_MEASURING_MODE_NATURAL,
    /// Baseline origin in DIPs.
    baseline_origin_x: f32 = 0,
    baseline_origin_y: f32 = 0,
};

ref: *c.IDWriteGlyphRunAnalysis,

pub fn fromRef(ref: *c.IDWriteGlyphRunAnalysis) GlyphRunAnalysis {
    return .{ .ref = ref };
}

pub fn retain(self: GlyphRunAnalysis) GlyphRunAnalysis {
    _ = self.ref.lpVtbl.*.AddRef.?(self.ref);
    return self;
}

pub fn deinit(self: GlyphRunAnalysis) void {
    _ = self.ref.lpVtbl.*.Release.?(self.ref);
}

/// Physical pixel bounds, empty when no glyphs match the requested texture type.
pub fn getAlphaTextureBounds(self: GlyphRunAnalysis, texture_type: c.DWRITE_TEXTURE_TYPE) hresult.Error!c.RECT {
    var bounds: c.RECT = undefined;
    try hresult.check(self.ref.lpVtbl.*.GetAlphaTextureBounds.?(self.ref, texture_type, &bounds));

    return bounds;
}

/// Writes tightly packed rows into caller-owned storage. Bounds may clip the run.
/// ALIASED_1x1 uses one byte (0 or 255) per pixel, CLEARTYPE_3x1 uses three.
/// DirectWrite validates bounds, texture type, and minimum buffer size.
pub fn createAlphaTexture(
    self: GlyphRunAnalysis,
    texture_type: c.DWRITE_TEXTURE_TYPE,
    bounds: c.RECT,
    alpha_values: []u8,
) !void {
    const size = std.math.cast(u32, alpha_values.len) orelse return error.InputTooLong;
    try hresult.check(self.ref.lpVtbl.*.CreateAlphaTexture.?(
        self.ref,
        texture_type,
        &bounds,
        alpha_values.ptr,
        size,
    ));
}
