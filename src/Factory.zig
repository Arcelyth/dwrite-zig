const Factory = @This();
const std = @import("std");
const c = @import("c");
const hresult = @import("hresult.zig");
const FontCollection = @import("FontCollection.zig");
const TextFormat = @import("TextFormat.zig");
const TextLayout = @import("TextLayout.zig");
const GlyphRunAnalysis = @import("GlyphRunAnalysis.zig");
const utils = @import("utils.zig");

ref: *c.IDWriteFactory,

pub fn fromRef(ref: *c.IDWriteFactory) Factory {
    return .{ .ref = ref };
}

pub fn retain(self: Factory) Factory {
    _ = self.ref.lpVtbl.*.AddRef.?(self.ref);
    return self;
}

pub fn deinit(self: Factory) void {
    _ = self.ref.lpVtbl.*.Release.?(self.ref);
}

pub fn init(factory_type: c.DWRITE_FACTORY_TYPE) hresult.Error!Factory {
    var ref: ?*c.IDWriteFactory = null;
    try hresult.check(c.DWriteCreateFactory(factory_type, &c.IID_IDWriteFactory, @ptrCast(&ref)));

    return .fromRef(ref orelse return error.UnexpectedResult);
}

pub fn getSystemFontCollection(self: Factory, update: bool) hresult.Error!FontCollection {
    var ref: ?*c.IDWriteFontCollection = null;
    try hresult.check(self.ref.lpVtbl.*.GetSystemFontCollection.?(self.ref, @ptrCast(&ref), @intFromBool(update)));

    return .fromRef(ref orelse return error.UnexpectedResult);
}

/// Borrows the native run and options for this call. The returned analysis is owned.
pub fn createGlyphRunAnalysis(
    self: Factory,
    run: *const c.DWRITE_GLYPH_RUN,
    options: GlyphRunAnalysis.Options,
) hresult.Error!GlyphRunAnalysis {
    var ref: ?*c.IDWriteGlyphRunAnalysis = null;
    try hresult.check(self.ref.lpVtbl.*.CreateGlyphRunAnalysis.?(
        self.ref,
        run,
        options.pixels_per_dip,
        options.transform,
        options.rendering_mode,
        options.measuring_mode,
        options.baseline_origin_x,
        options.baseline_origin_y,
        @ptrCast(&ref),
    ));

    return .fromRef(ref orelse return error.UnexpectedResult);
}

pub fn createTextFormat(self: Factory, allocator: std.mem.Allocator, options: TextFormat.Options) !TextFormat {
    const family = try utils.toWide(allocator, options.family_name);
    defer allocator.free(family);
    const locale = try utils.toWide(allocator, options.locale);
    defer allocator.free(locale);
    var ref: ?*c.IDWriteTextFormat = null;
    try hresult.check(self.ref.lpVtbl.*.CreateTextFormat.?(
        self.ref,
        family.ptr,
        if (options.collection) |collection| collection.ref else null,
        options.weight,
        options.style,
        options.stretch,
        options.size,
        locale.ptr,
        @ptrCast(&ref),
    ));

    return .fromRef(ref orelse return error.UnexpectedResult);
}

pub fn createTextLayout(
    self: Factory,
    allocator: std.mem.Allocator,
    text: []const u8,
    format: TextFormat,
    width: f32,
    height: f32,
) !TextLayout {
    const wide = try std.unicode.utf8ToUtf16LeAlloc(allocator, text);
    defer allocator.free(wide);

    return self.createTextLayoutUtf16(wide, format, width, height);
}

/// Copies UTF-16 input and the caller retains ownership of text and format.
pub fn createTextLayoutUtf16(
    self: Factory,
    text: []const u16,
    format: TextFormat,
    width: f32,
    height: f32,
) !TextLayout {
    const length = std.math.cast(u32, text.len) orelse return error.InputTooLong;
    var ref: ?*c.IDWriteTextLayout = null;
    try hresult.check(self.ref.lpVtbl.*.CreateTextLayout.?(
        self.ref,
        text.ptr,
        length,
        format.ref,
        width,
        height,
        @ptrCast(&ref),
    ));

    return .fromRef(ref orelse return error.UnexpectedResult);
}
