// Copyright 2017–2018 Stephan Tolksdorf

#import "STULabelSubrangeView.h"

#import "LabelRendering.hpp"

using namespace stu;
using namespace stu_label;

@implementation STULabelSubrangeView

- (instancetype)init {
  self = [super init];
#if TARGET_OS_IPHONE
    self.opaque = false;
#endif
    

  return self;
}

#if TARGET_OS_OSX
- (BOOL)isOpaque {
    return NO;
}
#endif

- (void)drawRect:(CGRect)rect {
  if (_drawingBlock) {
    _drawingBlock(STUGraphicsGetCurrentContext(), rect, nullptr);
  }
}

#if TARGET_OS_IPHONE
- (void)setContentScaleFactor:(CGFloat)contentScaleFactor {
  // When the view of a UITargetedDragPreview instance is inserted into the view hierarchy, its
  // contentScaleFactor is reset to the screen's scale. Since we don't do the insertion ourselves
  // and we don't want the view to appear pixelated when when it's the subview of a zoomed-in label,
  // we clamp the scale here.
  [super setContentScaleFactor:max(contentScaleFactor, self.superview.contentScaleFactor)];
}
#endif

#if TARGET_OS_OSX
#endif

@end

@implementation STULabelTiledSubrangeView

+ (Class)layerClass {
  return STULabelTiledLayer.class;
}

- (void)setDrawingBlock:(STULabelSubrangeDrawingBlock)drawingBlock {
  [super setDrawingBlock:drawingBlock];
  [((STULabelTiledLayer*)self.layer) setDrawingBlock: drawingBlock];
}

@end
