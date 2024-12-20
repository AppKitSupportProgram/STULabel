// Copyright 2018 Stephan Tolksdorf

#import "STUCancellationFlag.h"
#import "STUImageUtils.h"
#import "STULayerWithNullDefaultActions.h"

STU_ASSUME_NONNULL_AND_STRONG_BEGIN

typedef void (^ STULabelTileDrawingBlock)(CGContextRef context, CGRect rect,
                                          const STUCancellationFlag *cancellationFlag);

/// Displays synchronously, prerenders asynchronously and uses larger tile sizes than CATiledLayer.
STU_EXPORT
@interface STULabelTiledLayer : STULayerWithNullDefaultActions

@property (nonatomic, nullable) STULabelTileDrawingBlock drawingBlock;

@property (nonatomic) STUPredefinedCGImageFormat imageFormat;

@end

STU_ASSUME_NONNULL_AND_STRONG_END
