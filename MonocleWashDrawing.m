//
//  MonocleWashDrawing.m
//  Monocle
//
//  Created by Jesper on 2007-02-08.
//  Copyright 2007 waffle software. All rights reserved.
//

#import "MonocleController.h"
#import "MonocleWashDrawing.h"
#import "CTGradient.h"

@interface CTGradient (CTGradientIsFlat)
- (BOOL)isFlat;
- (unsigned)numberOfElements;
@end

@implementation CTGradient (CTGradientIsFlat)
- (unsigned)numberOfElements {
  unsigned count = 0;
  CTGradientElement *currentElement = elementList;
  while (currentElement != nil) {
    count++;
    currentElement = currentElement->nextElement;
  }
  return count;
}
- (BOOL)isFlat {
  unsigned c = [self numberOfElements];
  NSColor *col = [self colorStopAtIndex:0];
  unsigned i = 0;
  for (i = 0; i < c; i++) {
    if ([col isNotEqualTo:[self colorStopAtIndex:i]]) return NO;
  }
  return YES;
}
@end

@implementation MonocleWashDrawing

+ (void)drawCurrentWashInRect:(NSRect)rect {
  CTGradient *g;
  BOOL isGlass;

  [self getPrimaryWash:&g hasSheen:&isGlass];

  [self drawBackgroundWash:g inFrame:rect sheen:isGlass];
}

#define MonocleGradientSheenAlphaFrom 0.25
#define MonocleGradientSheenAlphaTo 0.1

+ (void)drawBackgroundWash:(CTGradient *)gradient inFrame:(NSRect)rect {
  [self drawBackgroundWash:gradient inFrame:rect sheen:NO];
}

+ (void)drawBackgroundWash:(CTGradient *)gradient inFrame:(NSRect)rect sheen:(BOOL)hasSheen {
  if ([gradient isFlat]) {
    NSColor *c = [gradient colorStopAtIndex:0];
    gradient = [CTGradient gradientWithBeginningColor:[c shadowWithLevel:0.15] endingColor:[c highlightWithLevel:0.15]];
  }
  [gradient fillRect:rect angle:90.0];

  if (!hasSheen) return;

  NSRect glassRect =
    NSMakeRect(rect.origin.x, rect.origin.y + NSHeight(rect) / 2.0, NSWidth(rect), NSHeight(rect) / 2.0);
  CTGradient *sheen =
    [CTGradient gradientWithBeginningColor:[[NSColor whiteColor] colorWithAlphaComponent:MonocleGradientSheenAlphaFrom]
                               endingColor:[[NSColor whiteColor] colorWithAlphaComponent:MonocleGradientSheenAlphaTo]];
  [sheen fillRect:glassRect angle:90.0];
}

+ (void)getPrimaryWash:(CTGradient **)gradient hasSheen:(BOOL *)sheen {
  NSUserDefaultsController *udc = [NSUserDefaultsController sharedUserDefaultsController];

  BOOL isGlass = ([[udc values] valueForKey:@"SearchBarHasSheen"]
      ? [(NSNumber *)[[udc values] valueForKey:@"SearchBarHasSheen"] boolValue]
      : NO);
  NSString *str = [[udc values] valueForKey:@"SearchBarStyle"];

  //	NSLog(@"str: %@", str);

  NSArray *styles = [[MonocleController controller] statusItemStyles];

  //	NSColor *c = [[styles objectAtIndex:0] objectForKey:@"color"];
  CTGradient *g = nil;

  NSEnumerator *styleEnumerator = [styles objectEnumerator];
  NSDictionary *style;
  CTGradient *fallback = nil;
  while (style = [styleEnumerator nextObject]) {
    if ([[style objectForKey:@"title"] isEqualToString:str]) {
      if (([style objectForKey:@"no-sheen"] != nil)) {
        isGlass = NO;
      }
      if ([style objectForKey:@"color"]) {
        NSColor *c = (NSColor *)[style objectForKey:@"color"];
        g = [CTGradient gradientWithBeginningColor:c endingColor:c];
      } else
        g = (CTGradient *)[style objectForKey:@"gradient"];
      break;
    }
    if ([style objectForKey:@"fallback"] && nil == fallback) {
      if ([style objectForKey:@"color"]) {
        NSColor *c = (NSColor *)[style objectForKey:@"color"];
        fallback = [CTGradient gradientWithBeginningColor:c endingColor:c];
      } else
        fallback = (CTGradient *)[style objectForKey:@"gradient"];
    }
  }

  if (nil == g) g = fallback;

  if (gradient) {
    *gradient = g;
  }

  if (sheen) {
    *sheen = isGlass;
  }
}

+ (CTGradient *)primaryWash {
  CTGradient *g;
  [self getPrimaryWash:&g hasSheen:NULL];
  if (!g) g = nil;
  return g;
}

@end
