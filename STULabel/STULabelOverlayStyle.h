// Copyright 2017 Stephan Tolksdorf

#import "STUDefines.h"

#import <Foundation/Foundation.h>
#import "Internal/STUMultiplePlatformAdapter.h"
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

#if TARGET_OS_OSX
#import <AppKit/AppKit.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@class STULabelOverlayStyleBuilder;

/// An immutable set of configuration parameters for the appearance of label overlays.
STU_EXPORT
@interface STULabelOverlayStyle : NSObject <NSCopying>

@property (class, readonly) STULabelOverlayStyle *defaultStyle;

- (instancetype)initWithBuilder:(nullable STULabelOverlayStyleBuilder *)builder
  NS_SWIFT_NAME(init(_:))
  NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithBlock:(void (^ STU_NOESCAPE)(STULabelOverlayStyleBuilder *builder))block
  // NS_SWIFT_NAME(init(_:)) // https://bugs.swift.org/browse/SR-6894
  // Use Swift's trailing closure syntax when calling this initializer.
  NS_REFINED_FOR_SWIFT;

- (instancetype)copyWithUpdates:(void (^ STU_NOESCAPE)(STULabelOverlayStyleBuilder *builder))block;

@property (readonly, nullable) STUColor *color;

@property (readonly) STUEdgeInsets edgeInsets;

@property (readonly) bool extendTextLinesToCommonHorizontalBounds;

@property (readonly) CGFloat cornerRadius;

@property (readonly) CGFloat borderWidth;

@property (readonly, nullable) STUColor *borderColor;

@property (readonly) CFTimeInterval fadeInDuration;

@property (readonly) CFTimeInterval fadeOutDuration;

@property (readonly, nullable) CAMediaTimingFunction *fadeInTimingFunction;

@property (readonly, nullable) CAMediaTimingFunction *fadeOutTimingFunction;

@end

STU_EXPORT
@interface STULabelOverlayStyleBuilder : NSObject

- (instancetype)initWithStyle:(nullable STULabelOverlayStyle *)style
  NS_SWIFT_NAME(init(_:))
  NS_DESIGNATED_INITIALIZER;

@property (nonatomic, nullable) STUColor *color;

@property (nonatomic) STUEdgeInsets edgeInsets;

@property (nonatomic) bool extendTextLinesToCommonHorizontalBounds;

@property (nonatomic) CGFloat cornerRadius;

@property (nonatomic) CGFloat borderWidth;

@property (nonatomic, nullable) STUColor *borderColor;

@property (nonatomic) CFTimeInterval fadeInDuration;

@property (nonatomic) CFTimeInterval fadeOutDuration;

@property (nonatomic, nullable) CAMediaTimingFunction *fadeInTimingFunction;

@property (nonatomic, nullable) CAMediaTimingFunction *fadeOutTimingFunction;

@end

NS_ASSUME_NONNULL_END
