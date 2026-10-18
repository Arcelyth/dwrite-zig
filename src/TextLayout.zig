const TextLayout = @This();
const std = @import("std");
const c = @import("c");
const hresult = @import("hresult.zig");
const GlyphRun = @import("GlyphRun.zig");

pub const ClusterMetrics = struct {
    width: f32,
    /// Number of UTF-16 units in the cluster.
    length: u16,
    can_wrap_line_after: bool,
    is_whitespace: bool,
    is_newline: bool,
    is_soft_hyphen: bool,
    is_right_to_left: bool,
};

const NativeClusterMetrics = extern struct {
    width: f32,
    length: u16,
    flags: u16,
};

ref: *c.IDWriteTextLayout,

pub fn fromRef(ref: *c.IDWriteTextLayout) TextLayout {
    return .{ .ref = ref };
}

pub fn retain(self: TextLayout) TextLayout {
    _ = self.ref.lpVtbl.*.AddRef.?(self.ref);
    return self;
}

pub fn deinit(self: TextLayout) void {
    _ = self.ref.lpVtbl.*.Release.?(self.ref);
}

pub fn getMetrics(self: TextLayout) hresult.Error!c.DWRITE_TEXT_METRICS {
    var metrics: c.DWRITE_TEXT_METRICS = undefined;
    try hresult.check(self.ref.lpVtbl.*.GetMetrics.?(self.ref, &metrics));

    return metrics;
}

pub fn getGlyphRuns(self: TextLayout, allocator: std.mem.Allocator) ![]GlyphRun {
    return GlyphRun.collectLayout(self.ref, allocator);
}

pub fn getClusterMetrics(self: TextLayout, allocator: std.mem.Allocator) ![]ClusterMetrics {
    var count: u32 = 0;
    const status = self.ref.lpVtbl.*.GetClusterMetrics.?(self.ref, null, 0, &count);
    const insufficient_buffer: c.HRESULT = @bitCast(@as(u32, 0x8007007a));
    if (status != insufficient_buffer) try hresult.check(status);
    const native = try allocator.alloc(NativeClusterMetrics, count);
    defer allocator.free(native);

    if (count != 0) {
        try hresult.check(self.ref.lpVtbl.*.GetClusterMetrics.?(self.ref, @ptrCast(native.ptr), count, &count));
        if (count > native.len) return error.UnexpectedResult;
    }

    const result = try allocator.alloc(ClusterMetrics, count);
    for (result, native[0..count]) |*cluster, value| {
        cluster.* = .{
            .width = value.width,
            .length = value.length,
            .can_wrap_line_after = value.flags & 1 != 0,
            .is_whitespace = value.flags & 2 != 0,
            .is_newline = value.flags & 4 != 0,
            .is_soft_hyphen = value.flags & 8 != 0,
            .is_right_to_left = value.flags & 16 != 0,
        };
    }

    return result;
}
