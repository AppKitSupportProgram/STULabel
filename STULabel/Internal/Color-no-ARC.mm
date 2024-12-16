
// Copyright 2017–2018 Stephan Tolksdorf

#if __has_feature(objc_arc)
  #error This file must be compiled with -fno-objc-arc
#endif

#import "STULabel/STUDefines.h"
#import "STUMultiplePlatformAdapter.h"
#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

#if TARGET_OS_OSX
#import <AppKit/AppKit.h>
#endif

namespace stu_label {

// We don't want to include the header since this is a no-objc-arc file.
STU_DISABLE_CLANG_WARNING("-Wmissing-prototypes")


CGColor* cgColor(STUColor*  color) {
  return color.CGColor;
}


STU_REENABLE_CLANG_WARNING

} // namespace stu_label
