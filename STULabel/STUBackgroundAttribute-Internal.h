// Copyright 2017 Stephan Tolksdorf

#import "STUBackgroundAttribute.h"

@interface STUBackgroundAttribute () {
@package
  STUColor *_color;
  bool _fillTextLineGaps;
  bool _extendTextLinesToCommonHorizontalBounds;
  CGFloat _cornerRadius;
  STUEdgeInsets _edgeInsets;
  STUColor *_borderColor;
  CGFloat _borderWidth;
}
@end
