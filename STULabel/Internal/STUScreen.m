//
//  STUScreen.m
//  STULabel
//
//  Created by JH on 2024/3/6.
//  Copyright © 2024 STULabel. All rights reserved.
//

#import "STUScreen.h"
#if TARGET_OS_IPHONE
#if TARGET_OS_VISION
@interface STUScreen ()
@property (nonatomic, weak, nullable) UIWindowScene *windowScene;
@end

@implementation STUScreen

- (instancetype)initWithWindowScene:(UIWindowScene *)windowScene {
    if (self = [super init]) {
        self.windowScene = windowScene;
    }
    return self;
}

+ (instancetype)mainScreen {
    UIWindowScene *windowScene = nil;
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if ([scene isKindOfClass:[UIWindowScene class]]) {
            windowScene = (UIWindowScene *)scene;
            
        }
    }
    
    if (windowScene) {
        return [[STUScreen alloc] initWithWindowScene:windowScene];
    } else {
        return nil;
    }
}

- (id<UICoordinateSpace>)fixedCoordinateSpace {
    return self.windowScene.coordinateSpace;
}

- (CGRect)bounds {
    return self.windowScene.coordinateSpace.bounds;
}

- (CGFloat)scale {
    return 2.0;
}

- (UITraitCollection *)traitCollection {
    return self.windowScene.traitCollection;
}




@end



#endif

@implementation UIWindow (STUScreen)
- (STUScreen *)stu_screen {
#if TARGET_OS_VISION
    if (self.windowScene) {
        return [[STUScreen alloc] initWithWindowScene:self.windowScene];
    } else {
        return nil;
    }
#else
    return self.screen;
#endif
}
@end
#endif

#if TARGET_OS_OSX
@implementation NSScreen (STUScreen)

- (CGRect)bounds {
    return self.frame;
}

- (CGFloat)scale {
    return self.backingScaleFactor;
}

- (NSDisplayGamut)displayGamut {
    if ([self canRepresentDisplayGamut:NSDisplayGamutP3]) {
        return NSDisplayGamutP3;
    } else if ([self canRepresentDisplayGamut:NSDisplayGamutSRGB]) {
        return NSDisplayGamutSRGB;
    } else {
        return 0;
    }
}

@end

@implementation NSWindow (STUScreen)
- (STUScreen *)stu_screen {
    return self.screen;
}
@end

#endif
