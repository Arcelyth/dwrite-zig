const Factory = @This();
const std = @import("std");
const c = @import("c");

ref: *c.IDWriteFactory,

/// Wraps a reference without adding a reference count.
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
