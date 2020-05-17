//
//  MonocleButtonBarStuff.h
//  Monocle
//
//  Created by Jesper on 2007-12-13.
//  Copyright 2007 waffle software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class CTGradient;

@interface MonocleButtonBarStuff : NSObject {
}
+ (CTGradient *)glassGradient;
+ (NSImage *)brightenBlackImage:(NSImage *)image;
+ (NSImage *)buttonImageFromImage:(NSImage *)image;
+ (void)drawButtonBackgroundInRect:(NSRect)rect image:(NSImage *)image view:(NSView *)view;
+ (NSBezierPath *)uPathForRect:(NSRect)rect;
+ (NSBezierPath *)uPathForRect:(NSRect)rect isFlipped:(BOOL)isFlipped;
+ (NSColor *)uPathColor;
@end
