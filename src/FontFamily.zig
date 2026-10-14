const FontFamily = @This();
const std = @import("std");
const c = @import("c");

ref: *c.IDWriteFontFamily,

pub fn fromRef(ref: *c.IDWriteFontFamily) FontFamily {
    return .{ .ref = ref };
}

pub fn retain(self: FontFamily) FontFamily {
    _ = self.ref.lpVtbl.*.AddRef.?(self.ref);
    return self;
}

pub fn deinit(self: FontFamily) void {
    _ = self.ref.lpVtbl.*.Release.?(self.ref);
}
