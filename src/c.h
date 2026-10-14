#define CINTERFACE
#define COBJMACROS
#include <windows.h>
// GDI's A/W macro must not rename the DirectWrite vtable member.
#undef GetGlyphIndices
#include <initguid.h>
#include <dwrite.h>
