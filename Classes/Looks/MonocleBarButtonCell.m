//
//  MonocleBarButtonCell.m
//  Monocle
//
//  Created by Jesper on 2007-12-13.
//  Copyright 2007 waffle software. All rights reserved.
//

#import "MonocleBarButtonCell.h"

#import "MonocleButtonBarStuff.h"
#import "CTGradient.h"

@implementation MonocleBarButtonCell
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
  [MonocleButtonBarStuff drawButtonBackgroundInRect:cellFrame image:[self image] view:controlView];
  if ([self isHighlighted]) {
    [[NSColor colorWithCalibratedWhite:0 alpha:0.3] set];
    [NSBezierPath fillRect:cellFrame];
  }
  //	[super drawWithFrame:cellFrame inView:controlView];
}

- (void)correctImage {
  isInnerImageSetting = YES;
  [self setImage:[MonocleButtonBarStuff brightenBlackImage:[self image]]];
  isInnerImageSetting = NO;
}

- (void)setImage:(NSImage *)image {
  if (isInnerImageSetting) {
    [super setImage:image];
  } else {
    [super setImage:image];
    [self correctImage];
  }
}

@end
