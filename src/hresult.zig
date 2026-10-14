const std = @import("std");
const c = @import("c");

pub const Error = error{
    OutOfMemory,
    InvalidArgument,
    NoInterface,
    NotImplemented,
    AccessDenied,
    FontFileFormat,
    FontNotFound,
    FileNotFound,
    FileAccess,
    FontCollectionObsolete,
    UnexpectedResult,
    DirectWriteFailure,
};

pub fn check(result: c.HRESULT) Error!void {
    if (result >= 0) return;
    return switch (result) {
        c.E_OUTOFMEMORY => error.OutOfMemory,
        c.E_INVALIDARG => error.InvalidArgument,
        c.E_NOINTERFACE => error.NoInterface,
        c.E_NOTIMPL => error.NotImplemented,
        c.E_ACCESSDENIED => error.AccessDenied,
        c.DWRITE_E_FILEFORMAT => error.FontFileFormat,
        c.DWRITE_E_NOFONT => error.FontNotFound,
        c.DWRITE_E_FILENOTFOUND => error.FileNotFound,
        c.DWRITE_E_FILEACCESS => error.FileAccess,
        c.DWRITE_E_FONTCOLLECTIONOBSOLETE => error.FontCollectionObsolete,
        c.E_UNEXPECTED, c.DWRITE_E_UNEXPECTED => error.UnexpectedResult,
        else => error.DirectWriteFailure,
    };
}
