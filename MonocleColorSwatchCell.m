#import "MonocleColorSwatchCell.h"
#import "MonocleController.h"
#import "MonoclePreferenceController.h"
#import "CTGradient.h"
#import "NSColor+ContrastingLabelExtensions.h"

#import "DrawingExtras.h"

@implementation MonocleColorSwatchCell

- (void)sharedInit {
  observedObjects = [[NSMutableSet alloc] init];
  [observedObjects retain];
}

- (id)initTextCell:(NSString *)aString {
  self = [super initTextCell:aString];
  if (self != nil) {
    [self sharedInit];
  }
  return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
  self = [super initWithCoder:decoder];
  if (self != nil) {
    [self sharedInit];
  }
  return self;
}

#define MONOCLE_COLOR_SWATCH_CELL_MAGIC_BINDING_COOKIE @"MONOCLE_COLOR_SWATCH_CELL_MAGIC_BINDING_COOKIE"

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
  //	NSLog(@"observeValueForKeyPath: %@ ofObject: %@", keyPath, object);
  if (context != NULL && [(id)context isKindOfClass:[NSString class]]) {
    NSString *str = (NSString *)context;
    if ([str isEqualToString:MONOCLE_COLOR_SWATCH_CELL_MAGIC_BINDING_COOKIE]) {
      [[[MonocleController controller] prefController] markEngineChanged:object];
    } else {
      [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
  } else {
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
  }
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
  id engine = [self objectValue];
  if (![observedObjects containsObject:engine]) {
    [engine addObserver:self
             forKeyPath:@"icon"
                options:NSKeyValueObservingOptionNew
                context:MONOCLE_COLOR_SWATCH_CELL_MAGIC_BINDING_COOKIE];
    [engine addObserver:self
             forKeyPath:@"color"
                options:NSKeyValueObservingOptionNew
                context:MONOCLE_COLOR_SWATCH_CELL_MAGIC_BINDING_COOKIE];
    [engine addObserver:self
             forKeyPath:@"colorSpecified"
                options:NSKeyValueObservingOptionNew
                context:MONOCLE_COLOR_SWATCH_CELL_MAGIC_BINDING_COOKIE];
    [observedObjects addObject:engine];
  }
  // NSLog(@"self object: %@", [self objectValue]);
  NSBitmapImageRep *bmp = [[MonocleController controller] bitmapImageRepForEngine:engine];
  [bmp self];

  NSColor *engineColor = [[MonocleController controller] colorForEngine:engine isDeduced:NULL];
  //	NSLog(@"color: %@", engineColor);

  NSColor *shadowColor =
    [[([self isHighlighted] ? [NSColor selectedTextBackgroundColor]
                            : [NSColor textBackgroundColor]) shadowWithLevel:0.35] contrastingLabelColor];
  //	NSLog(@"highlighted: %@, color A: %@; contrasting: %@", ([self isHighlighted] ? @"Y" : @"N"), ([([self
  // isHighlighted] ? [NSColor selectedTextBackgroundColor] : [NSColor textBackgroundColor]) shadowWithLevel:0.35]),
  // shadowColor);

  BOOL shadowIsBlack = ([shadowColor isEqualTo:[NSColor blackColor]]);

  double iconWidth = 16.0;

  float height = NSHeight(cellFrame) * 0.4;
  float width = height;  //*2.0;
  float lowest = (width > height ? height : width);
  double padding = 3.0;

  [[NSGraphicsContext currentContext] saveGraphicsState];

  NSImage *pillImage =
    [[[NSImage alloc] initWithSize:NSMakeSize(width + padding + padding, height + padding + padding)] autorelease];

  //	NSLog(@"width: %f, height: %f, lowest: %f", width, height, lowest);

  //	NSRect r =
  // NSMakeRect(NSMinX(cellFrame)+(lowest*0.4),NSMinY(cellFrame)+(NSHeight(cellFrame)-lowest)/2.0,width,lowest);
  NSRect r = NSMakeRect(padding, padding + ([pillImage size].height - lowest) / 2.0, width, lowest);
  //	NSLog(@"rect: %@", NSStringFromRect(r));

  NSImage *im = [[[NSImage alloc] initWithSize:NSMakeSize(iconWidth, iconWidth)] autorelease];
  [im addRepresentation:bmp];
  [im setFlipped:[controlView isFlipped]];

  CTGradient *grad = [CTGradient gradientWithBeginningColor:[engineColor highlightWithLevel:0.05]
                                                endingColor:[engineColor shadowWithLevel:0.05]];

  NSShadow *noshadow = [[[NSShadow alloc] init] autorelease];

  NSShadow *sh = [[[NSShadow alloc] init] autorelease];
  [sh setShadowColor:[shadowColor colorWithAlphaComponent:(shadowIsBlack ? 0.65 : 0.8)]];
  [sh setShadowBlurRadius:(shadowIsBlack ? 3 : 2.5)];
  [sh setShadowOffset:NSMakeSize(0.5, -0.5)];

  NSBezierPath *bp = [NSBezierPath bezierPathWithOvalInRect:r];  // bezierPathWithRoundRectInRect:r radius:lowest]; //

  [sh set];
  [pillImage lockFocus];
  [engineColor setFill];
  [bp fill];

  [[NSGraphicsContext currentContext] saveGraphicsState];

  [bp addClip];

  [grad fillRect:r angle:([controlView isFlipped] ? 90.0 : 270.0)];

  [[NSGraphicsContext currentContext] restoreGraphicsState];

  if ([[engineColor contrastingLabelColor] isEqualTo:[NSColor whiteColor]]) {
    [[NSColor colorWithCalibratedWhite:1.0 alpha:0.45] setStroke];
    [bp stroke];
  }
  [pillImage unlockFocus];

  [noshadow set];
  /*
  NSImage *pillMask = [[NSImage alloc] initWithSize:[pillImage size]];
  CTGradient *whiteIntoTransp = [CTGradient gradientWithBeginningColor:engineColor endingColor:[NSColor
  colorWithCalibratedWhite:1.0 alpha:0.0]]; whiteIntoTransp = [whiteIntoTransp addColorStop:engineColor atPosition:0.7];
  whiteIntoTransp = [whiteIntoTransp addColorStop:[NSColor clearColor] atPosition:0.95];
  [pillMask lockFocus];
  [whiteIntoTransp fillRect:NSMakeRect(0, 0, ([pillImage size]).width, ([pillImage size]).height) angle:0];
  [pillMask unlockFocus];*/

  NSImage *pill = pillImage;
  /*[pill lockFocus];
  [pillMask compositeToPoint:NSMakePoint(0,0) operation:NSCompositeSourceIn];
  [pill unlockFocus];*/

  [sh set];

  [pill drawAtPoint:NSMakePoint(NSMinX(cellFrame),
                      NSMinY(cellFrame) + (NSHeight(cellFrame) - [pill size].height) / 2.0 - (padding / 2.0))
           fromRect:NSZeroRect
          operation:NSCompositeSourceOver
           fraction:1.0];

  [noshadow set];
  /*
    sh = [[NSShadow alloc] init];
    [sh setShadowColor:[shadowColor colorWithAlphaComponent:(shadowIsBlack ? 0.25 : 0.55)]];
    [sh setShadowBlurRadius:2];
    [sh setShadowOffset:NSMakeSize(0.5, -0.5)];
    [sh set];*/

  [im drawAtPoint:NSMakePoint(NSMinX(cellFrame) + NSWidth(cellFrame) - iconWidth,
                    NSMinY(cellFrame) + ((NSHeight(cellFrame) - iconWidth) / 2.0))
         fromRect:NSZeroRect
        operation:NSCompositeSourceOver
         fraction:1.0];

  [noshadow set];

  /*
  [[engineColor contrastingLabelColor] setStroke];
  [bp stroke];
   */

  /*
  NSColor *drawColor = ([self isHighlighted] ? [[NSColor alternateSelectedControlTextColor]
  colorWithAlphaComponent:0.8f] : [NSColor controlShadowColor]); [self setTextColor:drawColor];

  [super drawWithFrame:cellFrame inView:controlView];*/

  [[NSGraphicsContext currentContext] restoreGraphicsState];
}

- (NSRect)expansionFrameWithFrame:(NSRect)cellFrame inView:(NSView *)view {
  return NSZeroRect;
}

@end
