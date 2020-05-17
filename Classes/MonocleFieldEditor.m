//
//  MonocleFieldEditor.m
//  Monocle
//
//  Created by Jesper on 2007-02-15.
//  Copyright 2007 waffle software. All rights reserved.
//

#import "MonocleFieldEditor.h"

@implementation MonocleFieldEditor
- (void)keyDown:(NSEvent *)theEvent {
  NSLog(@"key down (FE): %@", theEvent);

  [super keyDown:theEvent];
}
@end
