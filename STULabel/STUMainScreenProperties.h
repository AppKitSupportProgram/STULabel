// Copyright 2016–2018 Stephan Tolksdorf

#import "STUDefines.h"

#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, STUDisplayGamut)  {
STU_DISABLE_CLANG_WARNING("-Wunguarded-availability")
  STUDisplayGamutUnspecified = UIDisplayGamutUnspecified,
  STUDisplayGamutSRGB = UIDisplayGamutSRGB,
  STUDisplayGamutP3 = UIDisplayGamutP3
STU_REENABLE_CLANG_WARNING
};

#endif

#if TARGET_OS_OSX
#import <AppKit/AppKit.h>

typedef NS_ENUM(NSInteger, STUDisplayGamut)  {
STU_DISABLE_CLANG_WARNING("-Wunguarded-availability")
  STUDisplayGamutUnspecified = 0,
  STUDisplayGamutSRGB = NSDisplayGamutSRGB,
  STUDisplayGamutP3 = NSDisplayGamutP3
STU_REENABLE_CLANG_WARNING
};

#endif

STU_EXTERN_C_BEGIN

/// Returns the value of @c UIScreen.main.fixedCoordinateSpace.bounds.size.
/// Thread-safe.
CGSize stu_mainScreenPortraitSize(void);

/// Returns the value of @c UIScreen.main.scale.
/// Thread-safe.
CGFloat stu_mainScreenScale(void);

/// Returns the value of @c UIScreen.main.traitCollection.displayGamut.
/// Thread-safe.
STUDisplayGamut stu_mainScreenDisplayGamut(void);

STU_EXTERN_C_END
