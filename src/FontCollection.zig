const FontCollection = @This();
const std = @import("std");
const c = @import("c");

ref: *c.IDWriteFontCollection,

pub fn fromRef(ref: *c.IDWriteFontCollection) FontCollection {
    return .{ .ref = ref };
}

pub fn retain(self: FontCollection) FontCollection {
    _ = self.ref.lpVtbl.*.AddRef.?(self.ref);
    return self;
}

pub fn deinit(self: FontCollection) void {
    _ = self.ref.lpVtbl.*.Release.?(self.ref);
}
