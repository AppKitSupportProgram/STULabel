// Copyright 2017–2018 Stephan Tolksdorf

#import "STULabel/STUTextFrame-Unsafe.h"

#import "STULabel/STUImageUtils.h"

#import "STULabel/STULabelDrawingBlock.h"
#import "STULabel/STULabelLayoutInfo-Internal.hpp"


#import "PurgeableImage.hpp"

namespace stu_label {

enum class LabelRenderMode {
  drawInCAContext,
  image,
  imageInSublayer,
  tiledSublayer
};

struct LabelTextFrameRenderInfo {
  CGRect bounds;
  LabelRenderMode mode;
  STUPredefinedCGImageFormat imageFormat;
  bool shouldDrawBackgroundColor;
  bool isOpaque;
  bool mayBeClipped;
};

LabelTextFrameRenderInfo labelTextFrameRenderInfo(const STUTextFrame*,
                                                  const LabelTextFrameInfo&,
                                                  const CGPoint&,
                                                  const LabelParameters&,
                                                  bool preferImageMode,
                                                  const STUCancellationFlag* __nullable);

void drawLabelTextFrameRange(
       const STUTextFrame* textFrame, STUTextFrameRange range, CGPoint origin,
       __nullable CGContextRef context, bool isVectorContext, CGFloat contextBaseCTM_d,
       const STUTextFrameDrawingOptions* __nullable,
       __nullable STULabelDrawingBlock, const STUCancellationFlag* __nullable);

PurgeableImage createLabelTextFrameImage(const STUTextFrame*,
                                         const LabelTextFrameRenderInfo&,
                                         const LabelParameters&,
                                         const STUCancellationFlag* __nullable);

} // namespace stu_label


