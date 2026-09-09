#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The "back" asset catalog image resource.
static NSString * const ACImageNameBack AC_SWIFT_PRIVATE = @"back";

/// The "camera" asset catalog image resource.
static NSString * const ACImageNameCamera AC_SWIFT_PRIVATE = @"camera";

/// The "lau" asset catalog image resource.
static NSString * const ACImageNameLau AC_SWIFT_PRIVATE = @"lau";

/// The "login_bg" asset catalog image resource.
static NSString * const ACImageNameLoginBg AC_SWIFT_PRIVATE = @"login_bg";

/// The "tab1" asset catalog image resource.
static NSString * const ACImageNameTab1 AC_SWIFT_PRIVATE = @"tab1";

/// The "tab1_sel" asset catalog image resource.
static NSString * const ACImageNameTab1Sel AC_SWIFT_PRIVATE = @"tab1_sel";

/// The "tab2" asset catalog image resource.
static NSString * const ACImageNameTab2 AC_SWIFT_PRIVATE = @"tab2";

/// The "tab2_sel" asset catalog image resource.
static NSString * const ACImageNameTab2Sel AC_SWIFT_PRIVATE = @"tab2_sel";

/// The "tab3" asset catalog image resource.
static NSString * const ACImageNameTab3 AC_SWIFT_PRIVATE = @"tab3";

/// The "tab3_sel" asset catalog image resource.
static NSString * const ACImageNameTab3Sel AC_SWIFT_PRIVATE = @"tab3_sel";

/// The "tab4" asset catalog image resource.
static NSString * const ACImageNameTab4 AC_SWIFT_PRIVATE = @"tab4";

/// The "tab4_sel" asset catalog image resource.
static NSString * const ACImageNameTab4Sel AC_SWIFT_PRIVATE = @"tab4_sel";

/// The "tab5" asset catalog image resource.
static NSString * const ACImageNameTab5 AC_SWIFT_PRIVATE = @"tab5";

/// The "tab5_sel" asset catalog image resource.
static NSString * const ACImageNameTab5Sel AC_SWIFT_PRIVATE = @"tab5_sel";

#undef AC_SWIFT_PRIVATE
