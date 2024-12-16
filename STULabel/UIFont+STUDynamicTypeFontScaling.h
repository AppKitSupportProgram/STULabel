// Copyright 2017–2018 Stephan Tolksdorf

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIFont (STUDynamicTypeScaling)

- (UIFont *)stu_fontAdjustedForContentSizeCategory:(UIContentSizeCategory)category
  API_AVAILABLE(ios(10.0), tvos(10.0));

@end

NS_ASSUME_NONNULL_END
#endif

#if TARGET_OS_OSX
#endif
