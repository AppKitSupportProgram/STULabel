// Copyright 2017–2018 Stephan Tolksdorf

#if TARGET_OS_IPHONE

#import "NSAttributedString+STUDynamicTypeFontScaling.h"

#import "STUFont+STUDynamicTypeFontScaling.h"

@implementation NSAttributedString (STUDynamicTypeScaling)

- (NSAttributedString *)
    stu_copyWithFontsAdjustedForContentSizeCategory:(UIContentSizeCategory)category
      API_AVAILABLE(ios(10.0), tvos(10.0))
{
  __block NSUInteger start = NSNotFound;
  const NSUInteger length = self.length;
  STUFont * __unsafe_unretained __block previousFont = nil;
  [self enumerateAttribute:NSFontAttributeName inRange:NSMakeRange(0, length)
                   options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
                usingBlock:^(id __unsafe_unretained value, NSRange range, BOOL *stop)
   {
     if (!value) return;
     if (value == previousFont) return; // We use pointer equality here.
     STUFont * __unsafe_unretained const font = value;
     previousFont = font;
     if (font == [font stu_fontAdjustedForContentSizeCategory:category]) return;
     start = range.location;
     *stop = true;
   }];
  if (start == NSNotFound) return [self copy];
  NSMutableAttributedString * const string = [self mutableCopy];
  [string stu_adjustFontsInRange:NSMakeRange(start, length - start)
          forContentSizeCategory:category];
  return [string copy];
}
@end

@implementation NSMutableAttributedString (STUDynamicTypeScaling)

- (void)stu_adjustFontsInRange:(NSRange)range forContentSizeCategory:(UIContentSizeCategory)category
  API_AVAILABLE(ios(10.0), tvos(10.0))
{
  STUFont * __unsafe_unretained __block previousFont = nil;
  STUFont * __unsafe_unretained __block previousScaledFont = nil;
  [self enumerateAttribute:NSFontAttributeName inRange:range
                   options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
                usingBlock:^(id __unsafe_unretained value, NSRange attributeRange,
                             BOOL * __unused stop)
  {
    if (!value) return;
    STUFont * __unsafe_unretained const font = value;
    if (font == previousFont) { // We use pointer equality here.
      if (font != previousScaledFont) {
        [self addAttribute:NSFontAttributeName value:previousScaledFont range:attributeRange];
      }
      return;
    }
    previousFont = font;
    STUFont * const scaledFont = [font stu_fontAdjustedForContentSizeCategory:category];
    previousScaledFont = scaledFont;
    if (font != scaledFont) {
      [self addAttribute:NSFontAttributeName value:scaledFont range:attributeRange];
    }
  }];
}

@end


#endif

#if TARGET_OS_OSX
#endif
