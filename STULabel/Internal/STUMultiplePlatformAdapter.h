//
//  STUMultiplePlatformAdapter.h
//  STULabel
//
//  Created by JH on 2024/12/16.
//  Copyright © 2024 STULabel. All rights reserved.
//

#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
// typedef UIColor                         STUColor;
// typedef UIImage                         STUImage;
// typedef UIFont                             STUFont;
// typedef UIView                             STUView;
// typedef UIEdgeInsets                     STUEdgeInsets;
// typedef UIUserInterfaceLayoutDirection     STUUserInterfaceLayoutDirection;
// typedef UIWindow                         STUWindow;
// typedef UILayoutGuide                     STULayoutGuide;

#define STUColor UIColor
#define STUImage UIImage
#define STUFont UIFont
#define STUView UIView
#define STUEdgeInsets UIEdgeInsets
#define STUUserInterfaceLayoutDirection UIUserInterfaceLayoutDirection
#define STUWindow UIWindow
#define STULayoutGuide UILayoutGuide
#define STUAccessibilityElement UIAccessibilityElement
#define STUEdgeInsetsZero UIEdgeInsetsZero
#define STUScrollView UIScrollView
#endif

#if TARGET_OS_OSX
#import <AppKit/AppKit.h>

// typedef NSColor                         STUColor;
// typedef NSImage                         STUImage;
// typedef NSFont                          STUFont;
// typedef NSView                          STUView;
// typedef NSEdgeInsets                    STUEdgeInsets;
// typedef NSUserInterfaceLayoutDirection  STUUserInterfaceLayoutDirection;
// typedef NSLayoutGuide                   STULayoutGuide;

#define STUColor NSColor
#define STUImage NSImage
#define STUFont NSFont
#define STUView NSView
#define STUEdgeInsets NSEdgeInsets
#define STUUserInterfaceLayoutDirection NSUserInterfaceLayoutDirection
#define STULayoutGuide NSLayoutGuide
#define STUWindow NSWindow
#define STUAccessibilityElement NSAccessibilityElement
#define STUEdgeInsetsZero NSEdgeInsetsZero
#define STUScrollView NSScrollView

@interface NSImage (STUMultiplePlatformAdapter)
@property (nonatomic, readonly, nullable) CGImageRef CGImage;
@property (nonatomic, readonly, nullable) CIImage *CIImage;
@end
@interface NSView (STUMultiplePlatformAdapter)
@property (nonatomic, readonly) CGFloat inheritedAnimationDuration;
@end
#endif


NS_ASSUME_NONNULL_BEGIN


FOUNDATION_EXTERN BOOL STUEdgeInsetsEqualToEdgeInsets(STUEdgeInsets a, STUEdgeInsets b);
FOUNDATION_EXTERN CGContextRef _Nullable STUGraphicsGetCurrentContext(void);
FOUNDATION_EXTERN void STUGraphicsPushContext(CGContextRef context);
FOUNDATION_EXTERN void STUGraphicsPopContext(void);

@interface STUMultiplePlatformAdapter : NSObject

@end



NS_ASSUME_NONNULL_END
