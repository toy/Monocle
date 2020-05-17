//
//  MonocleButtonBarStuff.m
//  Monocle
//
//  Created by Jesper on 2007-12-13.
//  Copyright 2007 waffle software. All rights reserved.
//

#import "MonocleButtonBarStuff.h"
#import "CTGradient.h"

@implementation MonocleButtonBarStuff
static CTGradient *glassGradient = nil;

+ (CTGradient *)glassGradient {
  if (glassGradient == nil) {
    glassGradient = [[CTGradient alloc] init];
    glassGradient = [glassGradient addColorStop:[NSColor colorWithCalibratedWhite:((double)0xFD / (double)0xFF)
                                                                            alpha:1.0]
                                     atPosition:0.0];
    glassGradient = [glassGradient addColorStop:[NSColor colorWithCalibratedWhite:((double)0xF3 / (double)0xFF)
                                                                            alpha:1.0]
                                     atPosition:(9.99 / 21.0)];
    glassGradient = [glassGradient addColorStop:[NSColor colorWithCalibratedWhite:((double)0xE6 / (double)0xFF)
                                                                            alpha:1.0]
                                     atPosition:(10.0 / 21.0)];
    glassGradient = [glassGradient addColorStop:[NSColor colorWithCalibratedWhite:((double)0xE6 / (double)0xFF)
                                                                            alpha:1.0]
                                     atPosition:1.0];
    [glassGradient retain];
  }
  return [[glassGradient copy] autorelease];
}

+ (NSImage *)lightVersionOfImage:(NSImage *)image {
  [[NSGraphicsContext currentContext] saveGraphicsState];
  NSSize size = [image size];
  //	NSRect entire = NSMakeRect(0.0, 0.0, size.width, size.height);

  /*NSImage *light = [[NSImage alloc] initWithSize:size];
  [light lockFocus];
  [[NSColor colorWithCalibratedWhite:((double)0xF1/(double)0xFF) alpha:1.0] setFill];
  [NSBezierPath fillRect:entire];
  [light unlockFocus];*/

  //	NSImage *emptyImage = [[NSImage alloc] initWithSize:size];

  NSColor *useColor = [[NSColor whiteColor] colorWithAlphaComponent:0.98];

  NSImage *result = [[NSImage alloc] initWithSize:size];

  NSBitmapImageRep *bmp = [[NSBitmapImageRep alloc] initWithData:[image TIFFRepresentation]];
  /*
  NSBitmapImageRep *newBMP = [[NSBitmapImageRep alloc] initWithData:[emptyImage TIFFRepresentation]];
  [newBMP setSize:size];
  [newBMP setPixelsHigh:[bmp pixelsHigh]];
  [newBMP setPixelsWide:[bmp pixelsWide]];



//	[result lockFocus];
  NSColor *useColor = [[NSColor whiteColor] colorWithAlphaComponent:0.98];
  int x = 0;
  for (; x < [bmp pixelsWide]; x++) {
    int y = 0;
    for (; y < [bmp pixelsHigh]; y++) {
      NSColor *c = [bmp colorAtX:x y:y];
      if ([c alphaComponent] > 0) {
        [newBMP setColor:useColor atX:x y:y];
      }
    }
  }
//	[result unlockFocus];*/
  NSBitmapImageRep *newBMP = [bmp copy];
  [newBMP colorizeByMappingGray:0.5 toColor:useColor blackMapping:useColor whiteMapping:useColor];
  [result addRepresentation:newBMP];
  [newBMP release];
  [bmp release];

  //	NSLog(@"size: %@, %dx%d", NSStringFromSize(size), [bmp pixelsWide], [bmp pixelsHigh]);

  // NSImage *result = [image copy];
  /*
  [result lockFocus];
  [image compositeToPoint:NSMakePoint(0, 0) operation:NSCompositeSourceOver];
  [[[NSColor whiteColor] colorWithAlphaComponent:0.98] set];
  NSRectFillUsingOperation(entire, NSCompositeXOR);

  [result unlockFocus];*/

  //	[[result TIFFRepresentation] writeToFile:[@"~/Desktop/lightversion.tiff" stringByExpandingTildeInPath]
  // atomically:YES];

  [[NSGraphicsContext currentContext] restoreGraphicsState];

  return [result autorelease];
}

+ (NSImage *)brightenBlackImage:(NSImage *)image {
  NSImage *whiteVersion = [self lightVersionOfImage:image];

  NSSize size = [image size];
  NSImage *result = [[NSImage alloc] initWithSize:size];
  [result lockFocus];
  [image drawAtPoint:NSZeroPoint fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
  [whiteVersion drawAtPoint:NSZeroPoint fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:0.3];
  [result unlockFocus];

  return [result autorelease];
}

+ (void)drawButtonBackgroundInRect:(NSRect)rect image:(NSImage *)image view:(NSView *)view {
  NSSize size = rect.size;
  NSRect entire = rect;
  NSSize imsize = [image size];
  CTGradient *g = [self glassGradient];

  [[NSGraphicsContext currentContext] saveGraphicsState];

  BOOL isFlipped = [view isFlipped];
  [g fillRect:entire angle:(isFlipped ? 90.0 : 270.0)];

  NSPoint midPoint = NSMakePoint(size.width / 2.0, size.height / 2.0);
  NSPoint startPoint = NSMakePoint(midPoint.x - (imsize.width / 2.0), midPoint.y - (imsize.height / 2.0));

  NSRect wrapPoint = NSMakeRect(startPoint.x, startPoint.y, 1.0, 1.0);
  wrapPoint = NSIntegralRect(wrapPoint);
  startPoint = wrapPoint.origin;

  BOOL isEnabled = YES;
  if ([view isKindOfClass:[NSControl class]]) {
    NSControl *c = (NSControl *)view;
    isEnabled = [c isEnabled];
  }

  double fraction = (isEnabled ? 1.0 : 0.45);

  double lighterResolutionDependentOffset = 1.0;  // 1.0 / [[NSScreen mainScreen] userSpaceScaleFactor];

  NSImage *lighter = [self lightVersionOfImage:image];

  [lighter
    drawAtPoint:NSMakePoint(startPoint.x, startPoint.y + ((isFlipped ? 1.0 : -1.0) * lighterResolutionDependentOffset))
       fromRect:NSZeroRect
      operation:NSCompositeSourceOver
       fraction:fraction];
  [image drawAtPoint:startPoint fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:fraction];

  [[self uPathColor] setStroke];

  NSRect urect = entire;

  //	NSLog(@"rect: %@", NSStringFromRect(urect));

  [[self uPathForRect:urect isFlipped:isFlipped] stroke];

  [[NSGraphicsContext currentContext] restoreGraphicsState];
}

+ (NSImage *)buttonImageFromImage:(NSImage *)image {
  NSSize size = NSMakeSize(26, 25);
  NSRect entire = NSMakeRect(0.0, 0.0, size.width, size.height);
  NSSize imsize = [image size];
  NSImage *im = [[NSImage alloc] initWithSize:size];
  CTGradient *g = [self glassGradient];

  [[NSGraphicsContext currentContext] saveGraphicsState];

  [im lockFocus];

  [g fillRect:entire angle:270.0];

  NSPoint midPoint = NSMakePoint(size.width / 2.0, size.height / 2.0);
  NSPoint startPoint = NSMakePoint(midPoint.x - (imsize.width / 2.0), midPoint.y - (imsize.height / 2.0));

  NSShadow *noShadow = [[NSShadow alloc] init];

  /*
  NSShadow *paleGroove = [[NSShadow alloc] init];
  [paleGroove setShadowColor:[NSColor colorWithCalibratedWhite:((double)0xF1/(double)0xFF) alpha:1.0]];
  [paleGroove setShadowBlurRadius:1.0];
  [paleGroove setShadowOffset:NSMakeSize(0.0, 1.0)];

  [paleGroove set];*/

  NSRect wrapPoint = NSMakeRect(startPoint.x, startPoint.y, 1.0, 1.0);
  wrapPoint = NSIntegralRect(wrapPoint);
  startPoint = wrapPoint.origin;

  NSImage *lighter = [self lightVersionOfImage:image];

  [lighter drawAtPoint:NSMakePoint(startPoint.x, startPoint.y - 1.0)
              fromRect:NSZeroRect
             operation:NSCompositeSourceOver
              fraction:1.0];
  [image drawAtPoint:startPoint fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];

  [noShadow set];

  [[self uPathColor] setStroke];

  [[self uPathForRect:entire] stroke];

  [im unlockFocus];

  [[NSGraphicsContext currentContext] restoreGraphicsState];

  // NSData *tiff = [im TIFFRepresentation];
  //[tiff writeToURL:[NSURL fileURLWithPath:[[NSString stringWithFormat:@"~/Desktop/m_%@.tiff", @"add"]
  // stringByExpandingTildeInPath]] atomically:YES];

  [noShadow release];
  [im release];

  return im;
}

+ (NSBezierPath *)uPathForRect:(NSRect)rect {
  return [self uPathForRect:rect isFlipped:NO];
}

+ (NSBezierPath *)uPathForRect:(NSRect)rect isFlipped:(BOOL)isFlipped {
  NSBezierPath *bp = [NSBezierPath bezierPath];
  double bottomY = (isFlipped ? NSMaxY(rect) : NSMinY(rect));
  double topY = (isFlipped ? NSMinY(rect) + 0.5 : NSMaxY(rect) - 0.5);
  [bp moveToPoint:NSMakePoint(NSMinX(rect) + 0.5, topY)];
  [bp lineToPoint:NSMakePoint(NSMinX(rect) + 0.5, bottomY + 0.5)];
  [bp lineToPoint:NSMakePoint(NSMaxX(rect) - 0.5, bottomY + 0.5)];
  [bp lineToPoint:NSMakePoint(NSMaxX(rect) - 0.5, topY)];
  [bp lineToPoint:NSMakePoint(NSMinX(rect) + 0.5, topY)];
  [bp setLineWidth:1.0];

  return bp;
}
+ (NSColor *)uPathColor {
  return [NSColor headerColor];
}

@end
