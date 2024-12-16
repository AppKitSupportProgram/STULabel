//
//  STUMultiplePlatformAdapter.m
//  STULabel
//
//  Created by JH on 2024/12/16.
//  Copyright © 2024 STULabel. All rights reserved.
//

#import "STUMultiplePlatformAdapter.h"

CGContextRef _Nullable STUGraphicsGetCurrentContext(void) {
#if TARGET_OS_IPHONE
    return UIGraphicsGetCurrentContext();
#endif
    
#if TARGET_OS_OSX
    return NSGraphicsContext.currentContext.CGContext;
#endif
}

BOOL STUEdgeInsetsEqualToEdgeInsets(STUEdgeInsets a, STUEdgeInsets b) {
#if TARGET_OS_IPHONE
    return UIEdgeInsetsEqualToEdgeInsets(a, b);
#endif
    
#if TARGET_OS_OSX
#endif
}
void STUGraphicsPushContext(CGContextRef context) {
#if TARGET_OS_IPHONE
    UIGraphicsPushContext(context);
#endif
    
#if TARGET_OS_OSX
#endif
}
void STUGraphicsPopContext(void) {
#if TARGET_OS_IPHONE
    UIGraphicsPopContext();
#endif
    
#if TARGET_OS_OSX
#endif
}


@implementation STUMultiplePlatformAdapter

@end
