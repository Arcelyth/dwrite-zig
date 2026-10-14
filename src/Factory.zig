const Factory = @This();
const std = @import("std");
const c = @import("c");
const hresult = @import("hresult.zig");
const FontCollection = @import("FontCollection.zig");

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
