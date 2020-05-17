//
//  CocoaAdditions.m
//  Monocle
//
//  Created by Jesper on 2008-01-05.
//  Copyright 2008 waffle software. All rights reserved.
//

#import "CocoaAdditions.h"

@implementation NSString (EscapeHTMLEntitiesExtension)
- (NSString *)stringByHTMLEntityEscaping {
  int i;
  NSString *esca = @"";
  for (i = 0; i < [self length]; i++) {
    unichar ch = [self characterAtIndex:i];
    if (ch > 128) {
      esca = [esca stringByAppendingFormat:@"&#x%X;", (unsigned long)ch];
    } else {
      esca = [esca stringByAppendingString:[NSString stringWithCharacters:&ch length:1]];
    }
  }
  return esca;
}
@end
