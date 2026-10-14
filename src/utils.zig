const std = @import("std");

pub fn toWide(allocator: std.mem.Allocator, text: []const u8) ![:0]u16 {
    if (std.mem.indexOfScalar(u8, text, 0) != null)
        return error.EmbeddedNull;
    return std.unicode.utf8ToUtf16LeAllocZ(allocator, text);
}
