//
//  MonocleSearchField.m
//  Monocle
//
//  Created by Jesper on 2006-07-26.
//  Copyright 2006 waffle software. All rights reserved.
//

#import "MonocleSearchField.h"

@implementation MonocleSearchField

- (void)keyDown:(NSEvent *)theEvent {
  NSLog(@"key down (SF): %@", theEvent);

  [super keyDown:theEvent];
}

@end
