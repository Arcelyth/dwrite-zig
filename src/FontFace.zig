const FontFace = @This();
const std = @import("std");
const c = @import("c");

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
