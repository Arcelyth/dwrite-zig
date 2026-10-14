const Font = @This();
const std = @import("std");
const c = @import("c");

ref: *c.IDWriteFont,

pub fn fromRef(ref: *c.IDWriteFont) Font {
    return .{ .ref = ref };
}

pub fn retain(self: Font) Font {
    _ = self.ref.lpVtbl.*.AddRef.?(self.ref);
    return self;
}

pub fn deinit(self: Font) void {
    _ = self.ref.lpVtbl.*.Release.?(self.ref);
}
