//
//  STUMultiplePlatformDefines.h
//  STULabel
//
//  Created by JH on 12/16/24.
//  Copyright © 2024 STULabel. All rights reserved.
//

#ifndef STUMultiplePlatformDefines_h
#define STUMultiplePlatformDefines_h

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



#endif

#endif /* STUMultiplePlatformDefines_h */
