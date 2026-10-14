const FontTable = @This();
const FontFace = @import("FontFace.zig");

bytes: []const u8,
face: FontFace,
context: ?*anyopaque,

pub fn deinit(self: FontTable) void {
    self.face.ref.lpVtbl.*.ReleaseFontTable.?(self.face.ref, self.context);
    self.face.deinit();
}
