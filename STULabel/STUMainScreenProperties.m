// Copyright 2016–2018 Stephan Tolksdorf

#import "STUMainScreenProperties.h"

#import "stu/Assert.h"

#import <pthread.h>

#import <stdatomic.h>

#import "STUScreen.h"

#if TARGET_OS_IOS
  #define STU_MAIN_SCREEN_PROPERTIES_ARE_CONSTANT 1
#else
  #define STU_MAIN_SCREEN_PROPERTIES_ARE_CONSTANT 0
#endif

#if STU_MAIN_SCREEN_PROPERTIES_ARE_CONSTANT
  #define STU_ATOMIC_IF_NOT_CONSTANT(Type) Type
#else
  #define STU_ATOMIC_IF_NOT_CONSTANT(Type) _Atomic(Type)
#endif

static STU_ATOMIC_IF_NOT_CONSTANT(CGFloat) mainScreenPortraitSizeWidth;
static STU_ATOMIC_IF_NOT_CONSTANT(CGFloat) mainScreenPortraitSizeHeight;
static STU_ATOMIC_IF_NOT_CONSTANT(CGFloat) mainScreenScale;
static STU_ATOMIC_IF_NOT_CONSTANT(STUDisplayGamut) mainScreenDisplayGamut;

static void updateMainScreenProperties(void) {
  STU_DEBUG_ASSERT(pthread_main_np() || [NSProcessInfo.processInfo.environment[@"XCODE_RUNNING_FOR_PREVIEWS"] isEqualToString:@"1"]);
  CGSize portraitSize;
  CGFloat scale;
  STUDisplayGamut displayGamut;
  STUScreen * const mainScreen = STUScreen.mainScreen;
  STU_ASSERT(mainScreen || !STU_MAIN_SCREEN_PROPERTIES_ARE_CONSTANT);
  if (mainScreen) {
#if TARGET_OS_IPHONE
      portraitSize = mainScreen.fixedCoordinateSpace.bounds.size;
      scale = mainScreen.scale;
      if (@available(iOS 10, tvOS 10, *)) {
          displayGamut = (STUDisplayGamut)mainScreen.traitCollection.displayGamut;
      } else { // We don't try to support wide colors on an old iPad Pro running iOS 9.
          displayGamut = STUDisplayGamutSRGB;
      }
#endif
#if TARGET_OS_OSX
      portraitSize = mainScreen.frame.size;
      scale = mainScreen.backingScaleFactor;
      if ([mainScreen canRepresentDisplayGamut:NSDisplayGamutP3]) {
          displayGamut = STUDisplayGamutP3;
      } else {
          displayGamut = STUDisplayGamutSRGB;
      }
      
#endif
  } else {
      portraitSize = CGSizeZero;
      scale = 1;
      displayGamut = STUDisplayGamutSRGB;
  }

#if STU_MAIN_SCREEN_PROPERTIES_ARE_CONSTANT
  #define store(var, value) var = value
#else
  #define store(var, value) atomic_store_explicit(&var, value, memory_order_relaxed)
#endif
  store(mainScreenPortraitSizeWidth, portraitSize.width);
  store(mainScreenPortraitSizeHeight, portraitSize.height);
  store(mainScreenScale, scale);
  store(mainScreenDisplayGamut, displayGamut);
#undef store
}

//#if TARGET_OS_IPHONE
@interface STUScreen (STUMainScreenProperties)
+ (void)load;
@end
@implementation STUScreen (STUMainScreenProperties)
+ (void)load {
  // We can't do this initialization lazily, because UIScreen must only be accessed on the
  // main thread. (Using `dispatch_sync(dispatch_get_main_queue(), ...)` would lead to a
  // deadlock when the main thread is waiting for the thread in which stu_mainScreen... is called
  // for the first time.)
  updateMainScreenProperties();
#if !STU_MAIN_SCREEN_PROPERTIES_ARE_CONSTANT && !TARGET_OS_VISION
  NSNotificationCenter * const notificationCenter = NSNotificationCenter.defaultCenter;
  NSOperationQueue * const mainQueue = NSOperationQueue.mainQueue;
  const __auto_type updateMainScreenPropertiesBlock = ^(NSNotification *note __unused) {
                                                         updateMainScreenProperties();
                                                       };
    
#if TARGET_OS_IPHONE
    [notificationCenter addObserverForName:UIScreenDidConnectNotification
                                    object:nil queue:mainQueue
                                usingBlock:updateMainScreenPropertiesBlock];
    [notificationCenter addObserverForName:UIScreenDidDisconnectNotification
                                    object:nil queue:mainQueue
                                usingBlock:updateMainScreenPropertiesBlock];
#endif
#if TARGET_OS_OSX
    [notificationCenter addObserverForName:NSScreenColorSpaceDidChangeNotification
                                    object:nil queue:mainQueue
                                usingBlock:updateMainScreenPropertiesBlock];
#endif
#endif
}
@end
//#endif

#if TARGET_OS_OSX
#endif

#if STU_MAIN_SCREEN_PROPERTIES_ARE_CONSTANT
  #define load(var) var
#else
  #define load(var) atomic_load_explicit(&var, memory_order_relaxed)
#endif

STU_EXPORT
CGSize stu_mainScreenPortraitSize(void) {
  return (CGSize){load(mainScreenPortraitSizeWidth), load(mainScreenPortraitSizeHeight)};
}

STU_EXPORT
CGFloat stu_mainScreenScale(void) {
  return load(mainScreenScale);
}

STU_EXPORT
STUDisplayGamut stu_mainScreenDisplayGamut(void) {
  return load(mainScreenDisplayGamut);
}

#undef load
