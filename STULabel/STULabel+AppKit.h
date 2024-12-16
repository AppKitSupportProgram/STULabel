//
//  STULabel+AppKit.h
//  STULabel
//
//  Created by JH on 12/16/24.
//  Copyright © 2024 STULabel. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSLayoutAnchor+STULabelSpacing.h"
#import "STULabelLayer.h"
#import "STULabelOverlayStyle.h"

#if TARGET_OS_OSX
#import <AppKit/AppKit.h>

@protocol STULabelDelegate;

STU_ASSUME_NONNULL_AND_STRONG_BEGIN

/// A label view with a @c STULabelLayer layer.
///
/// @note
/// @c encodeWithCoder: (@c encode(with:)) only calls the superclass method and doesn't encode
/// any of the @c STULabel properties itself. If you need to persist more state, you could e.g.
/// subclass @c STULabel and overwrite @c encodeWithCoder: and @c initWithCoder:.
STU_EXPORT
@interface STULabel : NSView <STULabelLayerDelegate>

//@property (nullable, strong) STULabelLayer *layer;

@property (nonatomic, weak, nullable) id<STULabelDelegate> delegate;

/// Default value: false
@property (nonatomic) bool displaysAsynchronously;


- (void)configureWithPrerenderer:(nonnull STULabelPrerenderer *)prerenderer;

/// The attributed string that should be displayed in the label.
///
/// Setting the @c attributedText also sets the values of the @c text, @c font, @c textColor and
/// @c textAlignment properties. The values of the @c font, @c textColor and
/// @c textAlignment properties are set to the corresponding attribute values of the first character
/// in the string.
///
/// The label uses the Core Text default font (Helvetica 12pt.) for ranges in the attributed string
/// that have no font attribute.
@property (nonatomic, copy, null_resettable) NSAttributedString *attributedText;

@property (nonatomic, copy, null_resettable) NSString *text;

@property (nonatomic, null_resettable) NSFont *font;

@property (nonatomic, null_resettable) NSColor *textColor;

@property (nonatomic) NSTextAlignment textAlignment;

/// The alignment of text paragraphs whose implicit or explicit @c NSTextAlignment is @c .natural
/// or @c .justified.
///
/// Default value: @c .leading
@property (nonatomic) STULabelDefaultTextAlignment defaultTextAlignment;

/// The @c STUShapedString instance used by the label for layout and rendering purposes.
///
/// If necessary, the label lazily constructs the @c STUShapedString from @c self.attributedText
/// (with the default base writing direction corresponding to
/// @c self.effectiveUserInterfaceLayoutDirection).
///
/// If the attributed text is null, the getter returns an empty shaped string.
///
/// Since text shaping can be a relatively expensive operation, creating the shaped string in
/// advance on a background thread, e.g. from a collection view prefetch handler, and then
/// setting the label's @c shapedText instead of the @c attributedText can be an effective
/// optimization. (If you know the layout width of the label in advance, you could alternatively
/// use a @c STULabelPrerenderer to reduce the work on the main-thread even further.)
@property (nonatomic, null_resettable) STUShapedString *shapedText;

/// Default value: @c .top
@property (nonatomic) STULabelVerticalAlignment verticalAlignment;

/// Default value: @c .zero
@property (nonatomic) NSEdgeInsets contentInsets;

/// Default value: @c .zero
@property (nonatomic) STUDirectionalEdgeInsets directionalContentInsets;

/// Default value: false
@property (nonatomic) bool clipsContentToBounds;

/// Tracks the view frame without the content insets.
@property (readonly, nonnull) NSLayoutGuide *contentLayoutGuide;

- (void)setTextFrameOptions:(nullable STUTextFrameOptions *)options;

@property (nonatomic) STUTextLayoutMode textLayoutMode;

/// The maximum number of lines.
///
/// A value of 0 means that there is no maximum.
/// Default value: 1
@property (nonatomic) NSInteger maximumNumberOfLines;

/// Default value: @c .end
@property (nonatomic) STULastLineTruncationMode lastLineTruncationMode;

/// If the label's last line is truncated, this string will be inserted into into the text at the
/// point where the truncation starts.
///
/// If this string is nil or empty, an ellipsis '…' character will be used as the truncation token.
///
/// Any string attribute that is consistent over the full excised range from the original text
/// (ignoring any trailing whitespace) will be copied to the truncation token, without overwriting
/// any attribute already present in the token.
///
/// Default value: @c nil
@property (nonatomic, copy, nullable) NSAttributedString *truncationToken;

/// Default value: @c nil
@property (nonatomic, nullable) STUTruncationRangeAdjuster truncationRangeAdjuster;

/// Default value: 1
@property (nonatomic) CGFloat minimumTextScaleFactor;

/// Default value: 1/128.0 (May change in the future.)
@property (nonatomic) CGFloat textScaleFactorStepSize;

/// Default value: @c .alignFirstBaseline
@property (nonatomic) STUBaselineAdjustment textScalingBaselineAdjustment;

/// Default value: @c nil
@property (nonatomic, nullable) STULastHyphenationLocationInRangeFinder
                                  lastHyphenationLocationInRangeFinder;


/// Default value: true
@property (nonatomic) bool usesTintColorAsLinkColor;


@property (nonatomic, getter=isHighlighted) BOOL highlighted;

@property (nonatomic, nullable) STUTextHighlightStyle *highlightStyle;

@property (nonatomic) STUTextRange highlightRange;

- (void)setHighlightRange:(NSRange)range type:(STUTextRangeType)rangeType;


@property (nonatomic, getter=isEnabled) BOOL enabled;

/// Default value: `UIColor(white: 0.56, alpha: 1)`
@property (nonatomic, nullable) NSColor *disabledTextColor;

/// Default value: @c nil
@property (nonatomic, nullable) NSColor *disabledLinkColor;

@property (nonatomic, nullable) STULabelDrawingBlock drawingBlock;

@property (nonatomic) STULabelDrawingBlockColorOptions drawingBlockColorOptions;

/// Default value: @c .textLayoutBoundsPlusInsets
@property (nonatomic) STULabelDrawingBounds drawingBlockImageBounds;

/// Default value: false
@property (nonatomic) bool neverUsesGrayscaleBitmapFormat;

/// Default value: false
@property (nonatomic) bool neverUsesExtendedRGBBitmapFormat;

/// Default value: false
@property (nonatomic) bool releasesShapedStringAfterRendering;

/// Default value: false
@property (nonatomic) bool releasesTextFrameAfterRendering;

- (CGSize)sizeThatFits:(CGSize)size;

@property (nonatomic, readonly) STULabelLayoutInfo layoutInfo;

@property (nonatomic, readonly) CGSize intrinsicContentSize;

/// Indicates whether the label has an intrinsic content width.
///
/// The default value is true.
///
/// When this property is false, the label returns @c UIViewNoIntrinsicMetric as the
/// @c width value of the @c intrinsicContentSize.
///
/// You can set this property to false when the view's width is entirely determined by external
/// constraints, e.g. when the label's sides are pinned to the edges of a
/// @c UITableViewCell.contentView. This will improve the performance of @c intrinsicContentSize
/// for multi-line labels.
@property (nonatomic) bool hasIntrinsicContentWidth;

@property (nonatomic, readonly) NSLayoutYAxisAnchor *firstBaselineAnchor;

@property (nonatomic, readonly) NSLayoutYAxisAnchor *lastBaselineAnchor;


@property (nonatomic, readonly) STUTextFrame *textFrame NS_REFINED_FOR_SWIFT;
// var textFrame: STUTextFrameWithOrigin

@property (nonatomic, readonly) CGPoint textFrameOrigin NS_REFINED_FOR_SWIFT;

@end

STU_ASSUME_NONNULL_AND_STRONG_END

@protocol STULabelDelegate <NSObject>
@optional

/// Asks the delegate whether the label should be displayed asynchronously.
///
/// The proposed value is usually the current value of @c label.displaysAsynchronously,
/// but it may be @c false even when @c label.displaysAsynchronously is @c true if the
/// label implementation has determined that synchronous drawing may on this occasion be preferable
/// to avoid visible flickering.
- (bool)label:(STULabel *)label shouldDisplayAsynchronouslyWithProposedValue:(bool)proposedValued;

/// Tell the delegate that the label displayed text in the specified bounds.
/// @param label The label view.
/// @param flags Flags indicating various properties of the displayed text.
/// @param contentBounds
///  The bounds of the displayed text in the local coordinate system of the label view.
- (void)label:(STULabel *)label didDisplayTextWithFlags:(STUTextFrameFlags)flags
       inRect:(CGRect)contentBounds
  NS_SWIFT_NAME(label(_:didDisplayTextWithFlags:in:));

/// Tells the delegate that the displayed text moved to the specified bounds.
///
/// This delegate method is only called when the label's bounds change in a way that doesn't
/// invalidate the text layout except for the relative position of the text within the label
/// and only when the label was already displaying the text before the change.
/// @param label The label view.
/// @param contentBounds
///  The new bounds of the displayed text in the local coordinate system of the label view.
- (void)label:(STULabel *)label didMoveDisplayedTextToRect:(CGRect)contentBounds;

/// Tells the delegate that the text layout was invalidated.
- (void)labelTextLayoutWasInvalidated:(STULabel *)label;

@end

#endif
