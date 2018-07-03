// Copyright 2017–2018 Stephan Tolksdorf

#import "STULabelDrawingBlock.h"

STU_EXTERN_C_BEGIN
NS_ASSUME_NONNULL_BEGIN

STULabelDrawingBlockParameters *
  STULabelDrawingBlockParametersCreate(
    STUTextFrame *textFrame, STUTextFrameRange range, CGPoint textFrameOrigin,
    CGContextRef context, bool isVectorContext, CGFloat contextBaseCTM_d,
    STUTextFrameDrawingOptions * __nullable options,
    const STUCancellationFlag * __nullable cancellationFlag)
  NS_RETURNS_RETAINED;

NS_ASSUME_NONNULL_END
STU_EXTERN_C_END
