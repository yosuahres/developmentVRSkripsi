#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The "glyph" asset catalog image resource.
static NSString * const ACImageNameGlyph AC_SWIFT_PRIVATE = @"glyph";

#undef AC_SWIFT_PRIVATE
