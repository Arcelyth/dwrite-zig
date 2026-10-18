const GlyphRun = @This();
const std = @import("std");
const c = @import("c");
const FontFace = @import("FontFace.zig");
const hresult = @import("hresult.zig");
const WINAPI = std.lang.CallingConvention.winapi;

pub const Point = struct { x: f64, y: f64 };

/// An owned snapshot of a DrawGlyphRun callback. Arrays use DirectWrite's native
/// order, and text positions are UTF-16 units in the original layout.
font_face: FontFace,
font_em_size: f32,
baseline: Point,
measuring_mode: c.DWRITE_MEASURING_MODE,
is_sideways: bool,
bidi_level: u32,
text_position: u32,
glyph_indices: []u16,
glyph_advances: []f32,
glyph_offsets: []c.DWRITE_GLYPH_OFFSET,
cluster_map: []u16,

/// Copies callback data and retains its font face. All inputs are borrowed.
pub fn copy(allocator: std.mem.Allocator, baseline: Point, mode: c.DWRITE_MEASURING_MODE, run: c.DWRITE_GLYPH_RUN, description: c.DWRITE_GLYPH_RUN_DESCRIPTION) !GlyphRun {
    if (run.fontFace == null) return error.UnexpectedResult;
    if (run.glyphCount != 0 and (run.glyphIndices == null or run.glyphAdvances == null or run.glyphOffsets == null))
        return error.UnexpectedResult;
    if (description.stringLength != 0 and description.clusterMap == null) return error.UnexpectedResult;

    const indices = try allocator.dupe(u16, run.glyphIndices[0..run.glyphCount]);
    errdefer allocator.free(indices);
    const advances = try allocator.dupe(f32, run.glyphAdvances[0..run.glyphCount]);
    errdefer allocator.free(advances);
    const offsets = try allocator.dupe(c.DWRITE_GLYPH_OFFSET, run.glyphOffsets[0..run.glyphCount]);
    errdefer allocator.free(offsets);
    const clusters = try allocator.dupe(u16, description.clusterMap[0..description.stringLength]);

    return .{
        .font_face = FontFace.fromRef(run.fontFace).retain(),
        .font_em_size = run.fontEmSize,
        .baseline = baseline,
        .measuring_mode = mode,
        .is_sideways = run.isSideways != 0,
        .bidi_level = run.bidiLevel,
        .text_position = description.textPosition,
        .glyph_indices = indices,
        .glyph_advances = advances,
        .glyph_offsets = offsets,
        .cluster_map = clusters,
    };
}

pub fn deinit(self: GlyphRun, allocator: std.mem.Allocator) void {
    self.font_face.deinit();
    allocator.free(self.glyph_indices);
    allocator.free(self.glyph_advances);
    allocator.free(self.glyph_offsets);
    allocator.free(self.cluster_map);
}

pub fn isRightToLeft(self: GlyphRun) bool {
    return self.bidi_level & 1 != 0;
}

/// Owned per-glyph cluster starts, as absolute UTF-16 positions in the layout.
/// Multiple glyphs in an expanded cluster share the first character's index.
pub fn getStringIndices(self: GlyphRun, allocator: std.mem.Allocator) ![]u32 {
    const indices = try allocator.alloc(u32, self.glyph_indices.len);
    errdefer allocator.free(indices);
    @memset(indices, std.math.maxInt(u32));
    for (self.cluster_map, 0..) |glyph, i| {
        if (glyph >= indices.len) return error.InvalidStringIndex;
        const position = std.math.add(u32, self.text_position, @intCast(i)) catch return error.InvalidStringIndex;
        indices[glyph] = @min(indices[glyph], position);
    }
    var previous = self.text_position;
    for (indices) |*index| {
        if (index.* == std.math.maxInt(u32)) index.* = previous;
        previous = index.*;
    }
    return indices;
}

/// Owned horizontal glyph origins in layout DIPs (Y down), in native glyph order.
/// Sideways runs remain accessible through the raw arrays but are not positioned here.
pub fn getPositions(self: GlyphRun, allocator: std.mem.Allocator) ![]Point {
    if (self.is_sideways) return error.NotImplemented;
    const positions = try allocator.alloc(Point, self.glyph_indices.len);
    const rtl = self.isRightToLeft();

    var pen = self.baseline.x;
    for (positions, self.glyph_advances, self.glyph_offsets) |*position, advance, offset| {
        if (rtl) pen -= advance;
        position.* = .{
            .x = pen + (if (rtl) -@as(f64, offset.advanceOffset) else @as(f64, offset.advanceOffset)),
            .y = self.baseline.y - offset.ascenderOffset,
        };
        if (!rtl) pen += advance;
    }

    return positions;
}

pub fn collectLayout(layout: *c.IDWriteTextLayout, allocator: std.mem.Allocator) ![]GlyphRun {
    var collector: Collector = .{ .allocator = allocator };
    defer collector.runs.deinit(allocator);
    errdefer for (collector.runs.items) |run| run.deinit(allocator);

    const status = layout.lpVtbl.*.Draw.?(layout, null, &collector.interface, 0, 0);
    if (collector.failure) |err| return err;
    try hresult.check(status);

    return collector.runs.toOwnedSlice(allocator);
}

const Collector = struct {
    interface: c.IDWriteTextRenderer = .{ .lpVtbl = @constCast(&vtable) },
    allocator: std.mem.Allocator,
    runs: std.ArrayList(GlyphRun) = .empty,
    failure: ?anyerror = null,
    references: c.ULONG = 1,

    const vtable: c.IDWriteTextRendererVtbl = .{
        .QueryInterface = queryInterface,
        .AddRef = addRef,
        .Release = release,
        .IsPixelSnappingDisabled = snappingDisabled,
        .GetCurrentTransform = currentTransform,
        .GetPixelsPerDip = pixelsPerDip,
        .DrawGlyphRun = drawGlyphRun,
        .DrawUnderline = drawUnderline,
        .DrawStrikethrough = drawStrikethrough,
        .DrawInlineObject = drawInlineObject,
    };

    fn fromInterface(ref: [*c]c.IDWriteTextRenderer) *Collector {
        return @fieldParentPtr("interface", @as(*c.IDWriteTextRenderer, @ptrCast(ref)));
    }

    fn queryInterface(ref: [*c]c.IDWriteTextRenderer, iid: [*c]const c.IID, output: [*c]?*anyopaque) callconv(WINAPI) c.HRESULT {
        if (output == null) return c.E_POINTER;
        output.* = null;
        if (iid == null) return c.E_NOINTERFACE;
        inline for (.{ c.IID_IUnknown, c.IID_IDWritePixelSnapping, c.IID_IDWriteTextRenderer }) |supported| {
            if (std.mem.eql(u8, std.mem.asBytes(&iid.*), std.mem.asBytes(&supported))) {
                output.* = ref;
                _ = addRef(ref);
                return c.S_OK;
            }
        }
        return c.E_NOINTERFACE;
    }

    // The collector is stack-owned for the duration of the synchronous Draw call.
    fn addRef(ref: [*c]c.IDWriteTextRenderer) callconv(WINAPI) c.ULONG {
        const self = fromInterface(ref);
        self.references += 1;
        return self.references;
    }

    fn release(ref: [*c]c.IDWriteTextRenderer) callconv(WINAPI) c.ULONG {
        const self = fromInterface(ref);
        self.references -= 1;
        return self.references;
    }

    fn snappingDisabled(_: [*c]c.IDWriteTextRenderer, _: ?*anyopaque, disabled: [*c]c.BOOL) callconv(WINAPI) c.HRESULT {
        disabled.* = 1;
        return c.S_OK;
    }

    fn currentTransform(_: [*c]c.IDWriteTextRenderer, _: ?*anyopaque, matrix: [*c]c.DWRITE_MATRIX) callconv(WINAPI) c.HRESULT {
        matrix.* = .{ .m11 = 1, .m12 = 0, .m21 = 0, .m22 = 1, .dx = 0, .dy = 0 };
        return c.S_OK;
    }

    fn pixelsPerDip(_: [*c]c.IDWriteTextRenderer, _: ?*anyopaque, value: [*c]f32) callconv(WINAPI) c.HRESULT {
        value.* = 1;
        return c.S_OK;
    }

    fn drawGlyphRun(
        ref: [*c]c.IDWriteTextRenderer,
        _: ?*anyopaque,
        x: f32,
        y: f32,
        mode: c.DWRITE_MEASURING_MODE,
        run: [*c]const c.DWRITE_GLYPH_RUN,
        description: [*c]const c.DWRITE_GLYPH_RUN_DESCRIPTION,
        _: [*c]c.IUnknown,
    ) callconv(WINAPI) c.HRESULT {
        const self = fromInterface(ref);
        if (self.failure != null) return c.E_FAIL;
        if (run == null or description == null) {
            self.failure = error.UnexpectedResult;
            return c.E_UNEXPECTED;
        }
        self.collect(x, y, mode, run.*, description.*) catch |err| {
            self.failure = err;
            return if (err == error.OutOfMemory) c.E_OUTOFMEMORY else c.E_FAIL;
        };
        return c.S_OK;
    }

    fn collect(
        self: *Collector,
        x: f32,
        y: f32,
        mode: c.DWRITE_MEASURING_MODE,
        run: c.DWRITE_GLYPH_RUN,
        description: c.DWRITE_GLYPH_RUN_DESCRIPTION,
    ) !void {
        const snapshot = try GlyphRun.copy(self.allocator, .{ .x = x, .y = y }, mode, run, description);
        errdefer snapshot.deinit(self.allocator);
        try self.runs.append(self.allocator, snapshot);
    }

    fn drawUnderline(
        _: [*c]c.IDWriteTextRenderer,
        _: ?*anyopaque,
        _: f32,
        _: f32,
        _: [*c]const c.DWRITE_UNDERLINE,
        _: [*c]c.IUnknown,
    ) callconv(WINAPI) c.HRESULT {
        return c.S_OK;
    }

    fn drawStrikethrough(
        _: [*c]c.IDWriteTextRenderer,
        _: ?*anyopaque,
        _: f32,
        _: f32,
        _: [*c]const c.DWRITE_STRIKETHROUGH,
        _: [*c]c.IUnknown,
    ) callconv(WINAPI) c.HRESULT {
        return c.S_OK;
    }

    fn drawInlineObject(
        _: [*c]c.IDWriteTextRenderer,
        _: ?*anyopaque,
        _: f32,
        _: f32,
        _: [*c]c.IDWriteInlineObject,
        _: c.BOOL,
        _: c.BOOL,
        _: [*c]c.IUnknown,
    ) callconv(WINAPI) c.HRESULT {
        return c.E_NOTIMPL;
    }
};
