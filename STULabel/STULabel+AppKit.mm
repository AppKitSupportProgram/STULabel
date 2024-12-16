//
//  STULabel+AppKit.m
//  STULabel
//
//  Created by JH on 12/16/24.
//  Copyright © 2024 STULabel. All rights reserved.
//

#import "STULabel+AppKit.h"
#import "STULabelSwiftExtensions.h"

#import "NSAttributedString+STUDynamicTypeFontScaling.h"
#import "UIFont+STUDynamicTypeFontScaling.h"

#import "STULabelLayoutInfo-Internal.hpp"

#import "Internal/LabelParameters.hpp"
#import "Internal/LabelRendering.hpp"
#import "Internal/Localized.hpp"
#import "Internal/Once.hpp"
#import "Internal/STULabelAddToContactsViewController.h"
#import "Internal/STULabelGhostingMaskLayer.h"
#import "Internal/STULabelLinkOverlayLayer.h"
#import "Internal/STULabelSubrangeView.h"

#import <ContactsUI/ContactsUI.h>

#import <objc/runtime.h>

#include "Internal/DefineUIntOnCatalystToWorkAroundGlobalNamespacePollution.h"

#if TARGET_OS_OSX

using namespace stu;
using namespace stu_label;

// The lower-level parts of the Auto Layout API are largely private, which makes the implementation
// of some Auto-Layout-related functionality here more complicated and a bit less efficient than it
// otherwise would be.

// MARK: - STULabelContentLayoutGuide

@interface STULabelContentLayoutGuide : NSLayoutGuide
@end
@implementation STULabelContentLayoutGuide {
    NSLayoutConstraint* _leftConstraint;
    NSLayoutConstraint* _rightConstraint;
    NSLayoutConstraint* _topConstraint;
    NSLayoutConstraint* _bottomConstraint;
    NSEdgeInsets _contentInsets;
}

/// Also adds the guide to the label.
static void initContentLayoutGuide(STULabelContentLayoutGuide* self, STULabel* label) {
    [label addLayoutGuide:self];
    self->_leftConstraint   = [self.leftAnchor constraintEqualToAnchor:label.leftAnchor];
    self->_rightConstraint  = [self.rightAnchor constraintEqualToAnchor:label.rightAnchor];
    self->_topConstraint    = [self.topAnchor constraintEqualToAnchor:label.topAnchor];
    self->_bottomConstraint = [self.bottomAnchor constraintEqualToAnchor:label.bottomAnchor];
    self->_leftConstraint.identifier   = @"contentInsets.left";
    self->_rightConstraint.identifier  = @"contentInsets.right";
    self->_topConstraint.identifier    = @"contentInsets.top";
    self->_bottomConstraint.identifier = @"contentInsets.bottom";
    [NSLayoutConstraint activateConstraints:@[self->_leftConstraint, self->_rightConstraint,
                                              self->_topConstraint, self->_bottomConstraint]];
}

static void updateContentLayoutGuide(STULabelContentLayoutGuide* __unsafe_unretained self,
                                     const LabelParameters& params)
{
    const NSEdgeInsets& insets = params.edgeInsets();
    if (self->_contentInsets.left != insets.left) {
        self->_contentInsets.left = insets.left;
        self->_leftConstraint.constant = insets.left;
    }
    if (self->_contentInsets.right != insets.right) {
        self->_contentInsets.right = insets.right;
        self->_rightConstraint.constant = -insets.right;
    }
    if (self->_contentInsets.top != insets.top) {
        self->_contentInsets.top = insets.top;
        self->_topConstraint.constant = insets.top;
    }
    if (self->_contentInsets.bottom != insets.bottom) {
        self->_contentInsets.bottom = insets.bottom;
        self->_bottomConstraint.constant = -insets.bottom;
    }
}

@end

// MARK: - STULabelBaselinesLayoutGuide

@class STULabelBaselinesLayoutGuide;

static STULabelBaselinesLayoutGuide* baselinesLayoutGuide(STULabel*);

namespace stu_label {
    
    struct SpacingConstraint;
    static void removeLineHeightSpacingConstraintRef(STULabelBaselinesLayoutGuide*,
                                                     const SpacingConstraint&);
    
    struct FirstAndLastLineHeightInfo {
        Float32 firstLineHeight;
        Float32 lastLineHeight;
        Float32 firstLineHeightAboveBaseline;
        Float32 lastLineHeightBelowBaseline;
        
        FirstAndLastLineHeightInfo() = default;
        
        /* implicit */ STU_INLINE
        FirstAndLastLineHeightInfo(const LabelTextFrameInfo& info)
        : firstLineHeight{info.firstLineHeight},
        lastLineHeight{info.lastLineHeight},
        firstLineHeightAboveBaseline{info.firstLineHeightAboveBaseline},
        lastLineHeightBelowBaseline{info.lastLineHeightBelowBaseline}
        {}
        
        STU_INLINE
        friend bool operator==(const FirstAndLastLineHeightInfo& info1,
                               const FirstAndLastLineHeightInfo& info2)
        {
            return info1.firstLineHeight == info2.firstLineHeight
            && info1.lastLineHeight  == info2.lastLineHeight
            && info1.firstLineHeightAboveBaseline == info2.firstLineHeightAboveBaseline
            && info1.lastLineHeightBelowBaseline  == info2.lastLineHeightBelowBaseline;
        }
        
        STU_INLINE
        friend bool operator!=(const FirstAndLastLineHeightInfo& info1,
                               const FirstAndLastLineHeightInfo& info2)
        {
            return !(info1 == info2);
        }
    };
    
    struct alignas(8) SpacingConstraint {
        enum class Item : UInt8 {
            /// The left hand side of the constraint
            item1,
            /// The right hand side of the constraint
            item2
        };
        enum class Type : UInt8 {
            /// item1.baseline == item2.baseline
            ///                   + multiplier*max(item1.lineHeight, item2.lineHeight)
            ///                   + offset
            lineHeightSpacing = 0,
            
            /// item1.baseline == item2.baseline
            ///                   + multiplier*(item1.heightAboveBaseline + item2.heightBelowBaseline)
            ///                   + offset
            defaultSpacingBelow = 1,
            
            /// item1.baseline == item2.baseline
            ///                   - multiplier*(item1.heightBelowBaseline + item2.heightAboveBaseline)
            ///                   - offset
            defaultSpacingAbove = 2
        };
        
        CGFloat spacing() const {
            if (type == Type::lineHeightSpacing) {
                return max(height1, height2)*multiplier + offset;
            } else {
                return (height1 + height2)*multiplier + offset;
            }
        }
        
        CGFloat layoutConstantForSpacing(CGFloat spacing, const DisplayScale& scale) {
            const CGFloat value = ceilToScale(spacing, scale);
            return type == Type::defaultSpacingAbove ? -value : value;
        }
        
        NSLayoutConstraint* __weak layoutConstraint;
        // If the layout constraint lives longer than a referenced STULabelBaselinesLayoutGuide,
        // STULabelBaselinesLayoutGuide's deinit will set the corresponding reference here to nil.
        STULabelBaselinesLayoutGuide* __unsafe_unretained layoutGuide1;
        STULabelBaselinesLayoutGuide* __unsafe_unretained layoutGuide2;
        Type type;
        STUFirstOrLastBaseline baseline1;
        STUFirstOrLastBaseline baseline2;
        CGFloat multiplier;
        CGFloat offset;
        Float32 height1;
        Float32 height2;
        
        ~SpacingConstraint() {
            if (layoutGuide1) {
                removeLineHeightSpacingConstraintRef(layoutGuide1, *this);
            }
            if (layoutGuide2) {
                removeLineHeightSpacingConstraintRef(layoutGuide2, *this);
            }
        }
        
        void setHeight(Item item, const FirstAndLastLineHeightInfo& info) {
            const STUFirstOrLastBaseline baseline = item == Item::item1 ? baseline1 : baseline2;
            Float32 h;
            if (type == Type::lineHeightSpacing) {
                h = baseline == STUFirstBaseline ? info.firstLineHeight : info.lastLineHeight;
            } else {
                if ((type == Type::defaultSpacingBelow) == (item == Item::item1)) {
                    h = baseline == STUFirstBaseline
                    ? info.firstLineHeightAboveBaseline
                    : info.lastLineHeight - info.lastLineHeightBelowBaseline;
                } else {
                    h = baseline == STULastBaseline
                    ? info.lastLineHeightBelowBaseline
                    : info.firstLineHeight - info.firstLineHeightAboveBaseline;
                }
            }
            if (item == Item::item1) {
                height1 = h;
            } else {
                height2 = h;
            }
        }
    };
    
} // namespace stu_label

/// Is attached to the NSLayoutConstraint instance as an associated object.
@interface STULabelSpacingConstraint : NSObject {
    @package
    stu_label::SpacingConstraint impl;
}
@end
@implementation STULabelSpacingConstraint
@end

namespace stu_label {
    
    class SpacingConstraintRef {
        stu::UInt taggedPointer_;
    public:
        SpacingConstraintRef(SpacingConstraint& constraint, SpacingConstraint::Item item)
        : taggedPointer_{reinterpret_cast<stu::UInt>(&constraint) | static_cast<stu::UInt>(item)}
        {
            static_assert(alignof(SpacingConstraint) >= 2);
        }
        
        SpacingConstraint& constraint() const {
            return *reinterpret_cast<SpacingConstraint*>(taggedPointer_ & ~stu::UInt{1});
        }
        
        SpacingConstraint::Item item() const {
            return static_cast<SpacingConstraint::Item>(taggedPointer_ & 1);
        }
    };
}

/// The topAnchor is positioned at the Y-coordinate of the first baseline, and
/// the bottomAchor is positioned at the Y-coordinate of the last baseline.
@interface STULabelBaselinesLayoutGuide : NSLayoutGuide
@end
@implementation STULabelBaselinesLayoutGuide {
    NSLayoutConstraint* _firstBaselineConstraint;
    NSLayoutConstraint* _lastBaselineConstraint;
    CGFloat _firstBaseline;
    CGFloat _lastBaseline;
    CGFloat _screenScale;
    FirstAndLastLineHeightInfo _lineHeightInfo;
    stu::Vector<SpacingConstraintRef, 3> _lineHeightConstraints;
}

- (void)dealloc {
    for (auto& constraintRef : _lineHeightConstraints) {
        auto& constraint = constraintRef.constraint();
        if (constraintRef.item() == SpacingConstraint::Item::item1) {
            constraint.layoutGuide1 = nil;
        } else {
            constraint.layoutGuide2 = nil;
        }
    }
}

static void stu_label::removeLineHeightSpacingConstraintRef(
                                                            STULabelBaselinesLayoutGuide* __unsafe_unretained self,
                                                            const SpacingConstraint& constraint)
{
    auto& constraints = self->_lineHeightConstraints;
    for (Int i = 0; i < constraints.count(); ++i) {
        if (&constraints[i].constraint() == &constraint) {
            constraints.removeRange({i, Count{1}});
            return;
        }
    }
}

static STULabel* __nullable owningSTULabel(STULabelBaselinesLayoutGuide* __unsafe_unretained self) {
    NSView* const label = self.owningView;
    STU_CHECK_MSG([label isKindOfClass:STULabel.class],
                  "STULabelBaselinesLayoutGuide must not be removed from its owning STULabel view");
    return static_cast<STULabel*>(label);
}

static
NSLayoutYAxisAnchor* firstBaselineAnchor(STULabelBaselinesLayoutGuide* __unsafe_unretained self) {
    NSLayoutYAxisAnchor* const anchor = self.topAnchor;
    if (!self->_firstBaselineConstraint) {
        STULabel* const label = owningSTULabel(self);
        self->_firstBaselineConstraint = [anchor constraintEqualToAnchor:label.topAnchor
                                                                constant:self->_firstBaseline];
        self->_firstBaselineConstraint.identifier = @"firstBaseline";
        self->_firstBaselineConstraint.active = true;
        lastBaselineAnchor(self);
    }
    return anchor;
}

static
NSLayoutYAxisAnchor* lastBaselineAnchor(STULabelBaselinesLayoutGuide* __unsafe_unretained self) {
    NSLayoutYAxisAnchor* const anchor = self.bottomAnchor;
    if (!self->_lastBaselineConstraint) {
        STULabel* const label = owningSTULabel(self);
        self->_lastBaselineConstraint = [anchor constraintEqualToAnchor:label.topAnchor
                                                               constant:self->_lastBaseline];
        self->_lastBaselineConstraint.identifier = @"lastBaseline";
        self->_lastBaselineConstraint.active = true;
        firstBaselineAnchor(self);
    }
    return anchor;
}

static void updateBaselinesLayoutGuide(STULabelBaselinesLayoutGuide* __unsafe_unretained self,
                                       CGFloat screenScale,
                                       const LabelTextFrameInfo& info)
{
    if (self->_firstBaselineConstraint && self->_firstBaseline != info.firstBaseline) {
        self->_firstBaselineConstraint.constant = info.firstBaseline;
    }
    if (self->_lastBaselineConstraint && self->_lastBaseline != info.lastBaseline) {
        self->_lastBaselineConstraint.constant = info.lastBaseline;
    }
    if (!self->_lineHeightConstraints.isEmpty()
        && (self->_lineHeightInfo != info || self->_screenScale != screenScale))
    {
        const DisplayScale scale = DisplayScale::createOrIfInvalidGetMainSceenScale(self->_screenScale);
        const FirstAndLastLineHeightInfo lineHeightInfo{info};
        for (SpacingConstraintRef& cr : self->_lineHeightConstraints) {
            SpacingConstraint& c = cr.constraint();
            c.setHeight(cr.item(), lineHeightInfo);
            c.layoutConstraint.constant = c.layoutConstantForSpacing(c.spacing(), scale);
        }
    }
    self->_firstBaseline = info.firstBaseline;
    self->_lastBaseline = info.lastBaseline;
    self->_screenScale = screenScale;
    self->_lineHeightInfo = info;
}

static const char* const spacingConstraintAssociatedObjectKey = "STULabelSpacingConstraint";

static
NSLayoutConstraint* createSpacingConstraint(SpacingConstraint::Type type,
                                            NSLayoutYAxisAnchor* __unsafe_unretained anchor,
                                            NSLayoutRelation relation,
                                            STULabel* __unsafe_unretained label,
                                            STUFirstOrLastBaseline baseline,
                                            CGFloat multiplier, CGFloat offset)
{
    if (!label) return nil;
    STULabelBaselinesLayoutGuide* const guide = baselinesLayoutGuide(label);
    NSLayoutAnchor* const labelAnchor = baseline == STUFirstBaseline
    ? firstBaselineAnchor(guide)
    : lastBaselineAnchor(guide);
    NSLayoutConstraint* constraint = nil;
    switch (relation) {
        case NSLayoutRelationLessThanOrEqual:
            constraint = [anchor constraintLessThanOrEqualToAnchor:labelAnchor];
            break;
        case NSLayoutRelationEqual:
            constraint = [anchor constraintEqualToAnchor:labelAnchor];
            break;
        case NSLayoutRelationGreaterThanOrEqual:
            constraint = [anchor constraintGreaterThanOrEqualToAnchor:labelAnchor];
            break;
    }
    if (!constraint) return nil;
    
    auto* const object = [[STULabelSpacingConstraint alloc] init];
    objc_setAssociatedObject(constraint, spacingConstraintAssociatedObjectKey, object,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    SpacingConstraint& c = object->impl;
    
    using Item = SpacingConstraint::Item;
    
    c.layoutConstraint = constraint;
    c.multiplier = clampFloatInput(multiplier);
    c.offset = clampFloatInput(offset);
    c.layoutGuide2 = guide;
    c.type = type;
    c.baseline2 = clampFirstOrLastBaseline(baseline);
    c.setHeight(Item::item2, guide->_lineHeightInfo);
    guide->_lineHeightConstraints.append(SpacingConstraintRef(c, Item::item2));
    
    const id otherItem = constraint.firstItem;
    STU_STATIC_CONST_ONCE(Class, baselinesLayoutGuideClass, STULabelBaselinesLayoutGuide.class);
    if ([otherItem isKindOfClass:baselinesLayoutGuideClass]) {
        auto* const other = static_cast<STULabelBaselinesLayoutGuide*>(otherItem);
        const auto attribute = constraint.firstAttribute;
        if (attribute == NSLayoutAttributeTop || attribute == NSLayoutAttributeBottom) {
            c.layoutGuide1 = other;
            c.baseline1 = attribute == NSLayoutAttributeTop ? STUFirstBaseline : STULastBaseline;
            c.setHeight(Item::item1, other->_lineHeightInfo);
            other->_lineHeightConstraints.append(SpacingConstraintRef(c, Item::item1));
        }
    }
    
    if (const CGFloat spacing = c.spacing(); spacing != 0) {
        const auto scale = DisplayScale::createOrIfInvalidGetMainSceenScale(guide->_screenScale);
        constraint.constant = c.layoutConstantForSpacing(spacing, scale);
    }
    
    return constraint;
}

static STULabelSpacingConstraint* __nullable spacingConstraint(NSLayoutConstraint* constraint) {
    return objc_getAssociatedObject(constraint, spacingConstraintAssociatedObjectKey);
}

static CGFloat screenScale(const SpacingConstraint& constraint) {
    return constraint.layoutGuide2 ? constraint.layoutGuide2->_screenScale
    : constraint.layoutGuide1 ? constraint.layoutGuide1->_screenScale
    : 0;
}

@end

// MARK: -

@implementation NSLayoutYAxisAnchor (STULabelLineHeightSpacing)

- (NSLayoutConstraint *)stu_constraintWithRelation:(NSLayoutRelation)relation
                                                to:(STUFirstOrLastBaseline)baseline
                                                of:(STULabel*)label
                        plusLineHeightMultipliedBy:(CGFloat)lineHeightMultiplier
                                              plus:(CGFloat)offset
{
    return createSpacingConstraint(SpacingConstraint::Type::lineHeightSpacing,
                                   self, relation, label, baseline, lineHeightMultiplier, offset);
}

- (NSLayoutConstraint *)stu_constraintWithRelation:(NSLayoutRelation)relation
                                   toPositionAbove:(STUFirstOrLastBaseline)baseline
                                                of:(STULabel *)label
                                 spacingMultiplier:(CGFloat)spacingMultiplier
                                            offset:(CGFloat)offset
{
    return createSpacingConstraint(SpacingConstraint::Type::defaultSpacingAbove,
                                   self, relation, label, baseline, spacingMultiplier, -offset);
}

- (NSLayoutConstraint *)stu_constraintWithRelation:(NSLayoutRelation)relation
                                   toPositionBelow:(STUFirstOrLastBaseline)baseline
                                                of:(STULabel *)label
                                 spacingMultiplier:(CGFloat)spacingMultiplier
                                            offset:(CGFloat)offset
{
    return createSpacingConstraint(SpacingConstraint::Type::defaultSpacingBelow,
                                   self, relation, label, baseline, spacingMultiplier, offset);
}

@end

@implementation NSLayoutConstraint (STULabelSpacing)

- (bool)stu_isLabelSpacingConstraint {
    return spacingConstraint(self) != nil;
}

- (CGFloat)stu_labelSpacingConstraintMultiplier {
    STULabelSpacingConstraint* const object = spacingConstraint(self);
    if (!object) return 0;
    SpacingConstraint& c = object->impl;
    return c.multiplier;
}

- (void)stu_setLabelSpacingConstraintMultiplier:(CGFloat)multiplier {
    multiplier = clampFloatInput(multiplier);
    STULabelSpacingConstraint* const object = spacingConstraint(self);
    if (!object) return;
    SpacingConstraint& c = object->impl;
    c.multiplier = multiplier;
    const auto scale = DisplayScale::createOrIfInvalidGetMainSceenScale(screenScale(c));
    self.constant = c.layoutConstantForSpacing(c.spacing(), scale);
}

- (CGFloat)stu_labelSpacingConstraintOffset {
    STULabelSpacingConstraint* const object = spacingConstraint(self);
    if (!object) return 0;
    SpacingConstraint& c = object->impl;
    return c.type == SpacingConstraint::Type::defaultSpacingAbove ? -c.offset : c.offset;
}

- (void)stu_setLabelSpacingConstraintOffset:(CGFloat)offset {
    offset = clampFloatInput(offset);
    STULabelSpacingConstraint* const object = spacingConstraint(self);
    if (!object) return;
    SpacingConstraint& c = object->impl;
    c.offset = c.type == SpacingConstraint::Type::defaultSpacingAbove ? -offset : offset;
    const auto scale = DisplayScale::createOrIfInvalidGetMainSceenScale(screenScale(c));
    self.constant = c.layoutConstantForSpacing(c.spacing(), scale);
}

@end

// MARK: - STULabel

@implementation STULabel  {
    // The layer is owned by the view and stays constant, so we can safely cache a reference.
    __unsafe_unretained STULabelLayer* _layer;
    CGRect _contentBounds;
    CGSize _maxWidthIntrinsicContentSize;
    CGSize _intrinsicContentSizeKnownToAutoLayout;
    CGFloat _layoutWidthForIntrinsicContentSizeKnownToAutoLayout;
    struct STULabelBitField {
        UInt8 oldTintAdjustmentMode : 2;
        bool isSettingBounds : 1;
        bool isUpdatingConstraints : 1;
        bool intrinsicContentSizeIsKnownToAutoLayout : 1;
        bool waitingForPossibleSetBoundsCall : 1;
        bool didSetNeedsLayoutOnSuperview : 1;
        bool hasIntrinsicContentWidth : 1;
        bool maxWidthIntrinsicContentSizeIsValid : 1;
        bool adjustsFontForContentSizeCategory : 1;
        bool usesTintColorAsLinkColor : 1;
        bool hasActiveLinkOverlayLayer : 1;
        bool activeLinkOverlayIsHidden : 1;
        bool isEnabled : 1;
        bool accessibilityElementRepresentsUntruncatedText : 1;
        bool accessibilityElementSeparatesLinkElements : 1;
        bool delegateRespondsToOverlayStyleForActiveLink : 1;
        bool delegateRespondsToLinkWasTapped : 1;
        bool delegateRespondsToLinkCanBeLongPressed : 1;
        bool delegateRespondsToLinkWasLongPressed : 1;
        bool delegateRespondsToShouldDisplayAsynchronously : 1;
        bool delegateRespondsToDidDisplayText : 1;
        bool delegateRespondsDidMoveDisplayedText : 1;
        bool delegateRespondsToTextLayoutWasInvalidated : 1;
        bool delegateRespondsToLinkCanBeDragged : 1;
        bool delegateRespondsToDragItemForLink : 1;
        bool dragInteractionEnabled : 1;
    } _bits;
    STUTextFrameFlags _textFrameFlags;
    CGFloat _linkTouchAreaExtensionRadius;
    size_t _touchCount;
    size_t _accessibilityElementParagraphSeparationCharacterThreshold;
    
@private
    __weak id<STULabelDelegate> _delegate;
    NSColor* _disabledTextColor;
    NSColor* _disabledLinkColor;
    STULabelBaselinesLayoutGuide* _baselinesLayoutGuide;
    STULabelContentLayoutGuide* _contentLayoutGuide;
    //  UITouch* _currentTouch;
    //  NSPressGestureRecognizer* _pressGestureRecognizer;
    STULabelOverlayStyle* _activeLinkOverlayStyle;
    /// A STULabelLinkOverlayLayer if _bits.hasActiveLinkOverlayLayer, else a STUTextLink, or null.
    id _activeLinkOrOverlayLayer;
    CGPoint _activeLinkContentOrigin;
    STULabelGhostingMaskLayer* _ghostingMaskLayer;
}


- (CALayer *)makeBackingLayer {
    return [STULabelLayer layer];
}

- (BOOL)isFlipped {
    return YES;
}

//@dynamic layer;

// Dummy method whose presence signals to UIKit that this view uses custom drawing. This ensures
// that the contentScaleFactor (== layer.contentsScale) gets properly updated.
- (void)drawRect:(CGRect __unused)rect {}

// We override layerWillDraw with an empty method in order to prevent the default implementation
// from setting the contentsFormat of the layer.
- (void)layerWillDraw:(CALayer* __unused)layer {}

static void initCommon(STULabel* self) {
    static Class stuLabelLayerClass;
    static NSColor* disabledTextColor;
    static STULabelOverlayStyle* defaultLabelOverlayStyle;
    static bool dragInteractionIsEnabledByDefault;
    static dispatch_once_t once;
    dispatch_once_f(&once, nullptr, [](void *) {
        stuLabelLayerClass = STULabelLayer.class;
        disabledTextColor = [NSColor disabledControlTextColor];
        defaultLabelOverlayStyle = STULabelOverlayStyle.defaultStyle;
    });
    
    self->_bits.hasIntrinsicContentWidth = true;
    self->_bits.isEnabled = true;
    self->_bits.usesTintColorAsLinkColor = true;
    self->_bits.dragInteractionEnabled = dragInteractionIsEnabledByDefault;
    self->_bits.accessibilityElementRepresentsUntruncatedText = true;
    self->_linkTouchAreaExtensionRadius = 10;
    self->_accessibilityElementParagraphSeparationCharacterThreshold = 280;
    self->_disabledTextColor = disabledTextColor;
    self->_activeLinkOverlayStyle = defaultLabelOverlayStyle;
    [self setWantsLayer:YES];
    self->_layer = static_cast<STULabelLayer*>([self layer]);
    STU_CHECK([self->_layer isKindOfClass:stuLabelLayerClass]);
    self->_layer.labelLayerDelegate = self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        initCommon(self);
    }
    return self;
}

- (nullable instancetype)initWithCoder:(NSCoder*)decoder {
    if ((self = [super initWithCoder:decoder])) {
        initCommon(self);
    }
    return self;
}


- (void)setDelegate:(nullable id<STULabelDelegate>)delegate {
    _delegate = delegate;
    
    if (!delegate) {
        _bits.delegateRespondsToOverlayStyleForActiveLink = false;
        _bits.delegateRespondsToLinkWasTapped = false;
        _bits.delegateRespondsToLinkCanBeLongPressed = false;
        _bits.delegateRespondsToLinkWasLongPressed = false;
        _bits.delegateRespondsToShouldDisplayAsynchronously = false;
        _bits.delegateRespondsToDidDisplayText = false;
        _bits.delegateRespondsDidMoveDisplayedText = false;
        _bits.delegateRespondsToTextLayoutWasInvalidated = false;
        _bits.delegateRespondsToLinkCanBeDragged = false;
        _bits.delegateRespondsToDragItemForLink = false;
    } else {
        _bits.delegateRespondsToShouldDisplayAsynchronously =
        [delegate respondsToSelector:@selector(label:shouldDisplayAsynchronouslyWithProposedValue:)];
        _bits.delegateRespondsToDidDisplayText =
        [delegate respondsToSelector:@selector(label:didDisplayTextWithFlags:inRect:)];
        _bits.delegateRespondsDidMoveDisplayedText =
        [delegate respondsToSelector:@selector(label:didMoveDisplayedTextToRect:)];
        _bits.delegateRespondsToTextLayoutWasInvalidated =
        [delegate respondsToSelector:@selector(labelTextLayoutWasInvalidated:)];
    }
}

// MARK: - Layout related

- (void)setBounds:(CGRect)bounds {
    const bool isRecursiveCall = _bits.isSettingBounds;
    _bits.isSettingBounds = true;
    _bits.waitingForPossibleSetBoundsCall = false;
    [super setBounds:bounds];
    _bits.isSettingBounds = isRecursiveCall;
    
    // Note that [super setBounds] doesn't necessarily trigger a call to
    // labelLayerTextLayoutWasInvalidated, even when the size change invalidates the intrinsic content
    // size (when setBounds is called for a multi-line label with a larger size after the initial
    // call to intrinsicContentSize).
    if (_bits.intrinsicContentSizeIsKnownToAutoLayout && widthInvalidatesIntrinsicContentSize(self)) {
        [self invalidateIntrinsicContentSize];
    }
}

static void updateLayoutGuides(STULabel* __unsafe_unretained self) {
    if (self->_contentLayoutGuide) {
        updateContentLayoutGuide(self->_contentLayoutGuide,
                                 STULabelLayerGetParams(self->_layer));
    }
    if (self->_baselinesLayoutGuide) {
        updateBaselinesLayoutGuide(self->_baselinesLayoutGuide,
                                   STULabelLayerGetScreenScale(self->_layer),
                                   STULabelLayerGetCurrentTextFrameInfo(self->_layer));
    }
}

- (void)updateConstraints {
    const bool isRecursiveCall = _bits.isUpdatingConstraints;
    _bits.isUpdatingConstraints = true;
    [super updateConstraints];
    updateLayoutGuides(self);
    _bits.isUpdatingConstraints = isRecursiveCall;
}

- (bool)hasIntrinsicContentWidth {
    return _bits.hasIntrinsicContentWidth;
}
- (void)setHasIntrinsicContentWidth:(bool)hasIntrinsicContentWidth {
    if (_bits.hasIntrinsicContentWidth == hasIntrinsicContentWidth) return;
    _bits.hasIntrinsicContentWidth = hasIntrinsicContentWidth;
    [self invalidateIntrinsicContentSize];
}

- (CGSize)intrinsicContentSize {
    CGFloat layoutWidth = STULabelLayerGetSize(_layer).width;
    const bool useMaxLayoutWidth = STULabelLayerGetMaximumNumberOfLines(_layer) == 1
    || !(layoutWidth > 0); // Optimization for newly created label views.
    if (!_bits.maxWidthIntrinsicContentSizeIsValid
        && (useMaxLayoutWidth || _bits.hasIntrinsicContentWidth))
    {
        // We can't use an arbitrarily large width here, because paragraphs may be right-aligned and
        // the spacing between floating-point numbers increases with their magnitude.
        _maxWidthIntrinsicContentSize = [_layer sizeThatFits:CGSize{max(CGFloat(1 << 14), layoutWidth),
            maxValue<CGFloat>}];
        _bits.maxWidthIntrinsicContentSizeIsValid = true;
    }
    CGSize size;
    if (useMaxLayoutWidth || (_bits.maxWidthIntrinsicContentSizeIsValid
                              && layoutWidth >= _maxWidthIntrinsicContentSize.width))
    {
        // If maximumNumberOfLines == 1 and layoutWidth < _maxWidthIntrinsicContentSize.width, the text
        // truncation could increase the typographic height if the truncation token has a line height
        // larger than the main text, but supporting such odd formatting doesn't seem worth the slow
        // down of intrinsicContentSize for single line labels.
        // Similarly, if the final layout width actually is 0 and the label is not empty, the intrinsic
        // height calculated here likely isn't large enough, but in that case the layout is broken
        // anyway.
        layoutWidth = _maxWidthIntrinsicContentSize.width;
        size = _maxWidthIntrinsicContentSize;
    } else {
        size = [_layer sizeThatFits:CGSize{layoutWidth, maxValue<CGFloat>}];
        if (_bits.hasIntrinsicContentWidth) {
            STU_DEBUG_ASSERT(_bits.maxWidthIntrinsicContentSizeIsValid);
            size.height = max(size.height, _maxWidthIntrinsicContentSize.height);
            size.width = _maxWidthIntrinsicContentSize.width;
        }
    }
    if (_bits.isUpdatingConstraints) {
        _bits.intrinsicContentSizeIsKnownToAutoLayout = true;
        _layoutWidthForIntrinsicContentSizeKnownToAutoLayout = layoutWidth;
        if (size.height == _intrinsicContentSizeKnownToAutoLayout.height
            && (!_bits.hasIntrinsicContentWidth
                || size.width == _intrinsicContentSizeKnownToAutoLayout.width))
        {
            _bits.waitingForPossibleSetBoundsCall = false;
        }
        _intrinsicContentSizeKnownToAutoLayout = size;
    }
    if (!_bits.hasIntrinsicContentWidth) {
        size.width = NSViewNoIntrinsicMetric;
    }
    return size;
}

/// @pre intrinsicContentSizeIsKnownToAutoLayout
static bool widthInvalidatesIntrinsicContentSize(STULabel* __unsafe_unretained self) {
    STU_DEBUG_ASSERT(self->_bits.intrinsicContentSizeIsKnownToAutoLayout);
    if (STULabelLayerGetMaximumNumberOfLines(self->_layer) == 1) return false;
    const CGFloat width = STULabelLayerGetSize(self->_layer).width;
    return width > self->_layoutWidthForIntrinsicContentSizeKnownToAutoLayout
    || width < min(self->_layoutWidthForIntrinsicContentSizeKnownToAutoLayout,
                   self->_intrinsicContentSizeKnownToAutoLayout.width);
}

- (void)invalidateIntrinsicContentSize {
    if (_bits.intrinsicContentSizeIsKnownToAutoLayout) {
        _bits.intrinsicContentSizeIsKnownToAutoLayout = false;
        _bits.waitingForPossibleSetBoundsCall = true; // See the comment in layoutSubviews.
    }
    [super invalidateIntrinsicContentSize];
}

- (void)layout {
    updateLayoutGuides(self);
    [super layout];
    // UIKit sometimes doesn't properly update the layout after a call to
    // invalidateIntrinsicContentSize. Sometimes it just forgets to query the updated intrinsic
    // content size (rdar://34422006) and sometimes it simply doesn't update the layout after changes
    // in the constraints. To workaround these issue we track Auto-Layout-initiated intrinsic content
    // size invalidations and the subsequent setBounds calls. Any setBounds call should have happened
    // by now, so if none has, we request a relayout of the superview, which seems to reliably flush
    // any pending layout updates.
    if (_bits.waitingForPossibleSetBoundsCall && !_bits.didSetNeedsLayoutOnSuperview) {
        _bits.didSetNeedsLayoutOnSuperview = true;
        [self.superview setNeedsLayout:YES];
    } else {
        _bits.didSetNeedsLayoutOnSuperview = false;
    }
    _bits.waitingForPossibleSetBoundsCall = false;
}

- (void)labelLayerTextLayoutWasInvalidated:(STULabelLayer* __unused)labelLayer {
    if (!_bits.isSettingBounds) {
        _bits.maxWidthIntrinsicContentSizeIsValid = false;
    }
    if (_bits.intrinsicContentSizeIsKnownToAutoLayout && !_bits.isSettingBounds) {
        [self invalidateIntrinsicContentSize];
    }
    if (_bits.delegateRespondsToTextLayoutWasInvalidated) {
        [_delegate labelTextLayoutWasInvalidated:self];
    }
}

- (NSLayoutGuide*)contentLayoutGuide {
    if (!_contentLayoutGuide) {
        _contentLayoutGuide = [[STULabelContentLayoutGuide alloc] init];
        initContentLayoutGuide(_contentLayoutGuide, self);
        [self setNeedsUpdateConstraints:YES];
    }
    return _contentLayoutGuide;
}

static STULabelBaselinesLayoutGuide* baselinesLayoutGuide(STULabel* __unsafe_unretained self) {
    if (!self->_baselinesLayoutGuide) {
        self->_baselinesLayoutGuide = [[STULabelBaselinesLayoutGuide alloc] init];
        [self addLayoutGuide:self->_baselinesLayoutGuide];
        [self setNeedsUpdateConstraints:YES];
    }
    return self->_baselinesLayoutGuide;
}

- (NSLayoutYAxisAnchor*)firstBaselineAnchor {
    return firstBaselineAnchor(baselinesLayoutGuide(self));
}

- (NSLayoutYAxisAnchor*)lastBaselineAnchor {
    return lastBaselineAnchor(baselinesLayoutGuide(self));
}

// MARK: - STULabelLayerDelegate methods (except labelLayerTextLayoutWasInvalidated)

- (bool)labelLayer:(STULabelLayer* __unused)labelLayer
shouldDisplayAsynchronouslyWithProposedValue:(bool)value
{
    value &= _touchCount == 0;
    if (_bits.delegateRespondsToShouldDisplayAsynchronously) {
        // This is also an event notification, so we do the call even if we don't need the return value.
        value = [_delegate label:self shouldDisplayAsynchronouslyWithProposedValue:value];
    }
    // Synchronous drawing seems preferable for interactive usage and simplifies keeping the
    // the overlays in sync with the displayed content.
    if (_ghostingMaskLayer) {
        return false;
    }
    return value;
}

- (void)labelLayer:(STULabelLayer* __unused)labelLayer
didDisplayTextWithFlags:(STUTextFrameFlags)textFrameFlags inRect:(CGRect)contentBounds
{
    _contentBounds = contentBounds;
    _textFrameFlags = textFrameFlags;
    updateLayoutGuides(self);
    
    if (_bits.delegateRespondsToDidDisplayText) {
        [_delegate label:self didDisplayTextWithFlags:textFrameFlags inRect:contentBounds];
    }
}

- (void)labelLayer:(STULabelLayer* __unused)labelLayer
didMoveDisplayedTextToRect:(CGRect)contentBounds
{
    _contentBounds.origin = contentBounds.origin;
    updateLayoutGuides(self);
    if (_ghostingMaskLayer) {
        CALayer* const contentLayer = _layer.stu_contentSublayer;
        if (contentLayer.frame.size == _ghostingMaskLayer.frame.size) {
            _ghostingMaskLayer.position = contentLayer.position;
        } else {
            [_ghostingMaskLayer setMaskedLayerFrame:contentLayer.frame links:_layer.links];
        }
    }
    if (_bits.delegateRespondsDidMoveDisplayedText) {
        [_delegate label:self didMoveDisplayedTextToRect:contentBounds];
    }
}

// MARK: - STULabelLayer forwarder methods

- (STULabelDrawingBlock)drawingBlock {
    return _layer.drawingBlock;
}
- (void)setDrawingBlock:(STULabelDrawingBlock)drawingBlock {
    _layer.drawingBlock = drawingBlock;
}

- (STULabelDrawingBlockColorOptions)drawingBlockColorOptions {
    return _layer.drawingBlockColorOptions;
}
- (void)setDrawingBlockColorOptions:(STULabelDrawingBlockColorOptions)colorOptions {
    _layer.drawingBlockColorOptions = colorOptions;
}

- (STULabelDrawingBounds)drawingBlockImageBounds {
    return _layer.drawingBlockImageBounds;
}
- (void)setDrawingBlockImageBounds:(STULabelDrawingBounds)drawingBounds {
    _layer.drawingBlockImageBounds = drawingBounds;
}

- (bool)displaysAsynchronously {
    return _layer.displaysAsynchronously;
}
- (void)setDisplaysAsynchronously:(bool)displaysAsynchronously {
    _layer.displaysAsynchronously = displaysAsynchronously;
}

- (STULabelVerticalAlignment)verticalAlignment {
    return _layer.verticalAlignment;
}
- (void)setVerticalAlignment:(STULabelVerticalAlignment)verticalAlignment  {
    _layer.verticalAlignment = verticalAlignment;
}

- (NSEdgeInsets)contentInsets {
    return _layer.contentInsets;
}
- (void)setContentInsets:(NSEdgeInsets)contentInsets {
    _layer.contentInsets = contentInsets;
}

- (STUDirectionalEdgeInsets)directionalContentInsets {
    return _layer.directionalContentInsets;
}
- (void)setDirectionalContentInsets:(STUDirectionalEdgeInsets)contentInsets {
    _layer.directionalContentInsets = contentInsets;
}

- (NSColor*)backgroundColor {
    return [NSColor colorWithCGColor:_layer.displayedBackgroundColor];
}
- (void)setBackgroundColor:(NSColor*)backgroundColor {
    _layer.displayedBackgroundColor = backgroundColor.CGColor;
}

- (NSString*)text {
    return _layer.text;
}
- (void)setText:(NSString*)text {
    _layer.text = text;
}

- (NSFont*)font {
    return _layer.font;
}
- (void)setFont:(NSFont*)font {
    _layer.font = font;
}

- (NSColor*)textColor {
    return _layer.textColor;
}
- (void)setTextColor:(NSColor*)textColor {
    _layer.textColor = textColor;
}

- (NSTextAlignment)textAlignment {
    return _layer.textAlignment;
}
- (void)setTextAlignment:(NSTextAlignment)textAlignment {
    _layer.textAlignment = textAlignment;
}

- (STULabelDefaultTextAlignment)defaultTextAlignment {
    return _layer.defaultTextAlignment;
}
- (void)setDefaultTextAlignment:(STULabelDefaultTextAlignment)defaultTextAlignment {
    _layer.defaultTextAlignment = defaultTextAlignment;
}

- (NSAttributedString*)attributedText {
    return _layer.attributedText;
}
- (void)setAttributedText:(NSAttributedString*)attributedText {
    _layer.attributedText = attributedText;
}

- (STUShapedString*)shapedText {
    return _layer.shapedText;
}
- (void)setShapedText:(STUShapedString*)shapedText {
    _layer.shapedText = shapedText;
}

- (void)setTextFrameOptions:(nullable STUTextFrameOptions*)options {
    [_layer setTextFrameOptions:options];
}

- (STUTextLayoutMode)textLayoutMode {
    return _layer.textLayoutMode;
}
- (void)setTextLayoutMode:(STUTextLayoutMode)textLayoutMode {
    _layer.textLayoutMode = textLayoutMode;
}

- (NSInteger)maximumNumberOfLines {
    return _layer.maximumNumberOfLines;
}
- (void)setMaximumNumberOfLines:(NSInteger)maximumNumberOfLines {
    _layer.maximumNumberOfLines = maximumNumberOfLines;
}

- (STULastLineTruncationMode)lastLineTruncationMode {
    return _layer.lastLineTruncationMode;
}
- (void)setLastLineTruncationMode:(STULastLineTruncationMode)lastLineTruncationMode {
    _layer.lastLineTruncationMode = lastLineTruncationMode;
}

- (NSAttributedString*)truncationToken {
    return _layer.truncationToken;
}
- (void)setTruncationToken:(NSAttributedString*)truncationToken {
    _layer.truncationToken = truncationToken;
}

- (STUTruncationRangeAdjuster)truncationRangeAdjuster {
    return _layer.truncationRangeAdjuster;
}
- (void)setTruncationRangeAdjuster:(STUTruncationRangeAdjuster)truncationRangeAdjuster {
    _layer.truncationRangeAdjuster = truncationRangeAdjuster;
}

- (CGFloat)minimumTextScaleFactor {
    return _layer.minimumTextScaleFactor;
}
- (void)setMinimumTextScaleFactor:(CGFloat)minimumTextScaleFactor {
    _layer.minimumTextScaleFactor = minimumTextScaleFactor;
}

- (CGFloat)textScaleFactorStepSize {
    return _layer.textScaleFactorStepSize;
}
- (void)setTextScaleFactorStepSize:(CGFloat)textScaleFactorStepSize {
    _layer.textScaleFactorStepSize = textScaleFactorStepSize;
}

- (STUBaselineAdjustment)textScalingBaselineAdjustment {
    return _layer.textScalingBaselineAdjustment;
}
- (void)setTextScalingBaselineAdjustment:(STUBaselineAdjustment)textScalingBaselineAdjustment {
    _layer.textScalingBaselineAdjustment = textScalingBaselineAdjustment;
}

- (STULastHyphenationLocationInRangeFinder)lastHyphenationLocationInRangeFinder {
    return _layer.lastHyphenationLocationInRangeFinder;
}
- (void)setLastHyphenationLocationInRangeFinder:(STULastHyphenationLocationInRangeFinder)finder {
    _layer.lastHyphenationLocationInRangeFinder = finder;
}

- (CGSize)sizeThatFits:(CGSize)size {
    return [_layer sizeThatFits:size];
}

- (BOOL)isHighlighted {
    return _layer.highlighted;
}
- (void)setHighlighted:(BOOL)highlighted {
    _layer.highlighted = highlighted;
}

- (nullable STUTextHighlightStyle*)highlightStyle {
    return _layer.highlightStyle;
}
- (void)setHighlightStyle:(nullable  STUTextHighlightStyle*)highlightStyle {
    _layer.highlightStyle = highlightStyle;
}

- (STUTextRange)highlightRange {
    return _layer.highlightRange;
}
- (void)setHighlightRange:(STUTextRange)highlightRange {
    _layer.highlightRange = highlightRange;
}
- (void)setHighlightRange:(NSRange)range type:(STUTextRangeType)rangeType {
    [_layer setHighlightRange:range type:rangeType];
}

- (STULabelLayoutInfo)layoutInfo {
    return _layer.layoutInfo;
}

- (nonnull STUTextLinkArray*)links {
    return _layer.links;
}

- (void)configureWithPrerenderer:(nonnull STULabelPrerenderer*)prerenderer {
    const LabelParameters& params = STULabelLayerGetParams(_layer);
    NSColor* const overrideTextColor = params.overrideTextColor().unretained;
    NSColor* const overrideLinkColor = params.overrideLinkColor().unretained;
    [_layer configureWithPrerenderer:prerenderer];
    if (!equal(params.overrideTextColor().unretained, overrideTextColor)) {
        _layer.overrideTextColor = overrideTextColor;
    }
    if (!equal(params.overrideLinkColor().unretained, overrideLinkColor)) {
        _layer.overrideLinkColor = overrideLinkColor;
    }
}

- (bool)clipsContentToBounds {
    return _layer.clipsContentToBounds;
}
- (void)setClipsContentToBounds:(bool)clipsContentToBounds {
    _layer.clipsContentToBounds = clipsContentToBounds;
}

- (bool)neverUsesGrayscaleBitmapFormat {
    return _layer.neverUsesGrayscaleBitmapFormat;
}
- (void)setNeverUsesGrayscaleBitmapFormat:(bool)neverUsesGrayscaleBitmapFormat {
    _layer.neverUsesGrayscaleBitmapFormat = neverUsesGrayscaleBitmapFormat;
}

- (bool)neverUsesExtendedRGBBitmapFormat {
    return _layer.neverUsesExtendedRGBBitmapFormat;
}
- (void)setNeverUsesExtendedRGBBitmapFormat:(bool)neverUsesExtendedRGBBitmapFormat {
    _layer.neverUsesExtendedRGBBitmapFormat = neverUsesExtendedRGBBitmapFormat;
}

- (bool)releasesShapedStringAfterRendering {
    return _layer.releasesShapedStringAfterRendering;
}
- (void)setReleasesShapedStringAfterRendering:(bool)releasesShapedStringAfterRendering  {
    _layer.releasesShapedStringAfterRendering = releasesShapedStringAfterRendering;
}

- (bool)releasesTextFrameAfterRendering {
    return _layer.releasesTextFrameAfterRendering;
}
- (void)setReleasesTextFrameAfterRendering:(bool)releasesTextFrameAfterRendering {
    _layer.releasesTextFrameAfterRendering = releasesTextFrameAfterRendering;
}

- (STUTextFrame*)textFrame {
    return _layer.textFrame;
}

- (CGPoint)textFrameOrigin {
    return _layer.textFrameOrigin;
}

STU_EXPORT
STUTextFrameWithOrigin STULabelGetTextFrameWithOrigin(STULabel* self) {
    return STULabelLayerGetTextFrameWithOrigin(self->_layer);
};

@end


#endif
