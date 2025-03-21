// Copyright 2017–2018 Stephan Tolksdorf

#import "STULabel/STULabel.h"

#import "STULabel/STULabelTiledLayer.h"

typedef void (^ STULabelSubrangeDrawingBlock)(CGContextRef, CGRect,
                                              const STUCancellationFlag * __nullable);

@interface STULabelSubrangeView : STUView
@property (nonatomic, nullable) STULabelSubrangeDrawingBlock drawingBlock;
@end

@interface STULabelTiledSubrangeView : STULabelSubrangeView
@end
