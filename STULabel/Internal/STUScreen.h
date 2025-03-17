//
//  STUScreen.h
//  STULabel
//
//  Created by JH on 2024/3/6.
//  Copyright © 2024 STULabel. All rights reserved.
//

#import <Foundation/Foundation.h>
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#if TARGET_OS_VISION

NS_ASSUME_NONNULL_BEGIN

@interface STUScreen : NSObject
+ (nullable instancetype)mainScreen;
- (CGRect)bounds;
- (CGFloat)scale;
@property (nonatomic, readonly) UITraitCollection *traitCollection;
@property (readonly) id <UICoordinateSpace> fixedCoordinateSpace;
- (instancetype)initWithWindowScene:(UIWindowScene *)windowScene;

@end

@interface UIWindowScene (STUScreen)

@end


NS_ASSUME_NONNULL_END

#else

#define STUScreen UIScreen

#endif

@interface UIWindow (STUScreen)
@property(nonatomic, readonly, nullable) STUScreen *stu_screen;
@end
#endif

#if TARGET_OS_OSX
#import <AppKit/AppKit.h>
#define STUScreen NSScreen

@interface NSScreen (STUScreen)
@property (nonatomic, readonly) CGRect bounds;
@property (nonatomic, readonly) CGFloat scale;
@property (nonatomic, readonly) NSDisplayGamut displayGamut;
@end
@interface NSWindow (STUScreen)
@property (nonatomic, readonly, nullable) STUScreen *stu_screen;
@end
#endif


