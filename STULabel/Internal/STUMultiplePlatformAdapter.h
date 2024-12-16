//
//  STUMultiplePlatformAdapter.h
//  STULabel
//
//  Created by JH on 2024/12/16.
//  Copyright © 2024 STULabel. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <STULabel/STUMultiplePlatformDefines.h>

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

#if TARGET_OS_OSX
#import <AppKit/AppKit.h>
#endif


#if TARGET_OS_OSX
@interface NSImage (STUMultiplePlatformAdapter_AppKit)
@property (nonatomic, readonly, nullable) CGImageRef CGImage;
@property (nonatomic, readonly, nullable) CIImage *CIImage;
@end
@interface NSView (STUMultiplePlatformAdapter_AppKit)
@property (nonatomic, readonly, class) CGFloat inheritedAnimationDuration;
@end

@interface NSCoder (STUMultiplePlatformAdapter_AppKit)
- (void)encodeCGPoint:(CGPoint)point forKey:(NSString *)key;
- (void)encodeCGSize:(CGSize)size forKey:(NSString *)key;
- (void)encodeCGRect:(CGRect)rect forKey:(NSString *)key;
- (CGPoint)decodeCGPointForKey:(NSString *)key;
- (CGSize)decodeCGSizeForKey:(NSString *)key;
- (CGRect)decodeCGRectForKey:(NSString *)key;
@end
#endif

FOUNDATION_EXTERN BOOL STUEdgeInsetsEqualToEdgeInsets(STUEdgeInsets a, STUEdgeInsets b);
FOUNDATION_EXTERN CGContextRef _Nullable STUGraphicsGetCurrentContext(void);
FOUNDATION_EXTERN void STUGraphicsPushContext(CGContextRef context);
FOUNDATION_EXTERN void STUGraphicsPopContext(void);


@interface NSCoder (STUMultiplePlatformAdapter)
- (void)encodeSTUEdgeInsets:(STUEdgeInsets)edgeInsets forKey:(NSString *)key;
- (STUEdgeInsets)decodeSTUEdgeInsetsForKey:(NSString *)key;
@end
