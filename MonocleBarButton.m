//
//  MonocleBarButton.m
//  Monocle
//
//  Created by Jesper on 2007-12-14.
//  Copyright 2007 waffle software. All rights reserved.
//

#import "MonocleBarButton.h"
#import "MonocleBarButtonCell.h"

@implementation MonocleBarButton
+ (Class)cellClass {
  return [MonocleBarButtonCell class];
}

- (void)awakeFromNib {
  MonocleBarButtonCell *newCell = nil;
  NSButtonCell *oldCell = (NSButtonCell *)[self cell];

  // first, encode NSButtonCell
  NSMutableData *data = [NSMutableData data];
  NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
  [archiver encodeObject:oldCell forKey:@"cell"];
  [archiver finishEncoding];
  [archiver release];

  // then, decode the cell, but as our kind of cell instead
  NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
  [unarchiver setClass:[MonocleBarButtonCell class] forClassName:NSStringFromClass([NSButtonCell class])];
  newCell = [unarchiver decodeObjectForKey:@"cell"];

  [newCell setImage:[oldCell image]];
  [newCell setBezeled:NO];
  [newCell setBordered:NO];
  [newCell setHighlightsBy:NSContentsCellMask];
  [self setCell:newCell];
  [unarchiver release];
}
@end
