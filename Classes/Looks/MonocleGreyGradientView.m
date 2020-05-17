//
//  MonocleGreyGradientView.m
//  Monocle
//
//  Created by Jesper on 2007-12-12.
//  Copyright 2007 waffle software. All rights reserved.
//

#import "MonocleGreyGradientView.h"
#import "MonocleButtonBarStuff.h"
#import "CTGradient.h"

@implementation MonocleGreyGradientView

- (void)sharedInitStuff {
  //	NSLog(@"glass gradient initing...");
  glassGradient = [[MonocleButtonBarStuff glassGradient] retain];
}

- (id)initWithFrame:(NSRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self sharedInitStuff];
  }
  return self;
}

- (id)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    [self sharedInitStuff];
  }
  return self;
}

- (BOOL)isOpaque {
  return YES;
}

- (void)drawRect:(NSRect)rect {
  //	NSSize whole = NSIntegralRect([self visibleRect]).size;
  //	NSSize asked = NSIntegralRect(rect).size;
  //	NSLog(@"grey gradient view asked to draw %@", NSStringFromRect(rect));
  //	NSLog(@"whole: %@, asked: %@", NSStringFromSize(whole), NSStringFromSize(asked));
  //	if (!NSEqualSizes(whole, asked)) { [self display]; return; }
  NSSize whole = [self visibleRect].size;
  NSSize asked = rect.size;
  if (asked.width < whole.width || asked.height < whole.height) {
    [self display];
    return;
  }

  unsigned x = 4;
  unsigned i = 0;
  for (; i < x; i++) {
    //		NSLog(@"gradient element %d: %@", i, [glassGradient colorStopAtIndex:i]);
  }

  //	NSLog(@"grey gradient view drawing!");

  BOOL isFlipped = [self isFlipped];

  [glassGradient fillRect:NSOffsetRect(rect, 0, 1) angle:90.0 + (isFlipped ? 0.0 : 180.0)];

  [[MonocleButtonBarStuff uPathColor] setStroke];
  [[MonocleButtonBarStuff uPathForRect:rect] stroke];
}

@end
