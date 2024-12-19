//
//  STUMultiplePlatformAdapter.m
//  STULabel
//
//  Created by JH on 2024/12/16.
//  Copyright © 2024 STULabel. All rights reserved.
//

#import "STUMultiplePlatformAdapter.h"

#if TARGET_OS_OSX
@interface NSGraphicsContext ()
+ (void)_pushGraphicsContext:(NSGraphicsContext *)context;
+ (void)_popGraphicsContext;
@end
#endif

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
    return NSEdgeInsetsEqual(a, b);
#endif
}
void STUGraphicsPushContext(CGContextRef context) {
#if TARGET_OS_IPHONE
    UIGraphicsPushContext(context);
#endif
    
#if TARGET_OS_OSX
    [NSGraphicsContext _pushGraphicsContext:[NSGraphicsContext graphicsContextWithCGContext:context flipped:YES]];
#endif
}
void STUGraphicsPopContext(void) {
#if TARGET_OS_IPHONE
    UIGraphicsPopContext();
#endif
    
#if TARGET_OS_OSX
    [NSGraphicsContext _popGraphicsContext];
#endif
}



#if TARGET_OS_OSX
@implementation NSImage (STUMultiplePlatformAdapter_AppKit)
- (CGImageRef)CGImage {
    return [self CGImageForProposedRect:nil context:nil hints:nil];
}
- (CIImage *)CIImage {
    CGImageRef cgImage = self.CGImage;
    if (!cgImage) {
        return nil;
    }
    return [CIImage imageWithCGImage:cgImage];
}
@end
@implementation NSView (STUMultiplePlatformAdapter_AppKit)
+ (CGFloat)inheritedAnimationDuration {
    return 0;
}
@end

@implementation NSCoder (STUMultiplePlatformAdapter_AppKit)
- (void)encodeCGPoint:(CGPoint)point forKey:(NSString *)key {
    [self encodeObject:[NSValue valueWithPoint:point] forKey:key];
}
- (void)encodeCGSize:(CGSize)size forKey:(NSString *)key {
    [self encodeObject:[NSValue valueWithSize:size] forKey:key];
}
- (void)encodeCGRect:(CGRect)rect forKey:(NSString *)key {
    [self encodeObject:[NSValue valueWithRect:rect] forKey:key];
}
- (CGPoint)decodeCGPointForKey:(NSString *)key {
    return [[self decodeObjectOfClass:[NSValue class] forKey:key] pointValue];
}
- (CGSize)decodeCGSizeForKey:(NSString *)key {
    return [[self decodeObjectOfClass:[NSValue class] forKey:key] sizeValue];
}
- (CGRect)decodeCGRectForKey:(NSString *)key {
    return [[self decodeObjectOfClass:[NSValue class] forKey:key] rectValue];
}
@end
#endif

#if TARGET_OS_IPHONE

#endif
@implementation NSCoder (STUMultiplePlatformAdapter)
- (void)encodeSTUEdgeInsets:(STUEdgeInsets)edgeInsets forKey:(NSString *)key {
#if TARGET_OS_IPHONE
    [self encodeUIEdgeInsets:edgeInsets forKey:key];
#endif
    
#if TARGET_OS_OSX
    [self encodeObject:[NSValue valueWithEdgeInsets:edgeInsets] forKey:key];
#endif
}

- (STUEdgeInsets)decodeSTUEdgeInsetsForKey:(NSString *)key {
#if TARGET_OS_IPHONE
    return [self decodeUIEdgeInsetsForKey:key];
#endif
    
#if TARGET_OS_OSX
    return [[self decodeObjectOfClass:[NSValue class] forKey:key] edgeInsets];
#endif
}
@end
