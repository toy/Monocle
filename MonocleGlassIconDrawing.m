//
//  MonocleGlassIconDrawing.m
//  Monocle
//
//  Created by Jesper on 2007-02-03.
//  Copyright 2007 waffle software. All rights reserved.
//

#import "MonocleGlassIconDrawing.h"

// Thanks a ton to Peter Hosey who rewrote this.

// The default parameters to the magnifying glass drawing, as
// established at the first annual Church of Hosey International
// Magnifying Glass Drawing Conference and Expo early 2007.

// 3.2, 3.5, 4.8

#define		MonocleGlassCircleRadius	3.2
#define		MonocleGlassHandleOffset	3.5
#define		MonocleGlassHandleLength	4.8

#define		MonocleGlassYOffset			0.0
#define		MonocleGlassXOffset			0.0

#define		MonocleGlassScaleDenominator	18.0

//#define DEBUG_MONOCLE_GLASS_DRAW_BLACK_BACKGROUND	1

@implementation MonocleGlassIconDrawing
+ (NSImage *)imageForSize:(NSSize)s strokeColor:(NSColor *)strokeColor {
	NSImage *im = [[NSImage alloc] initWithSize:s];
	
	[im lockFocus];
	
#ifdef DEBUG_MONOCLE_GLASS_DRAW_BLACK_BACKGROUND
	[[NSColor blackColor] setFill];
	[NSBezierPath fillRect:NSMakeRect(0.0,0.0,s.width,s.height)];
#endif
	
	// x is the thickness of the strokes, and in Spotlight's icon it's about 7% of the height (1.5 thick in a 22 high icon).
	// Given a height of 10, where x is 1.5, these are approximate proportions
	//   __    
	//  /  \  <-- lens, fully encompassed within a 8*8 square
	//  \__/
	//      \ <-- handle, fully encompassed within a 4*4 square, joining the glass at 135° (if 0° is at the top)

	// Flip our coordinate system.
	NSAffineTransform *invertCoordinateSystem = [NSAffineTransform transform];
    [invertCoordinateSystem translateXBy:0.0 yBy:s.height];
    [invertCoordinateSystem scaleXBy:1.0 yBy:-1.0];
    [invertCoordinateSystem concat];
	
	NSAffineTransform *offsetCoordinateSystem = [NSAffineTransform transform];
	[offsetCoordinateSystem translateXBy:0.0 yBy:-0.5];
	[offsetCoordinateSystem concat];
	
	const float strokeWidth = 1.5f;
	const float circleradius = MonocleGlassCircleRadius;
	const float handleoffset = MonocleGlassHandleOffset;
	const float handlelength = MonocleGlassHandleLength;
	
	// Total size of the lens, including the width of the stroke.
	const float lensTotalSize = (circleradius * 2.0f) + strokeWidth;
	// And the origin, derived from that.
	const NSPoint lensOrigin = NSMakePoint(
        // (( 16   - ( 7            * ( 16      / 18                          ))) / 2.0 )
        // (( 16   - ( 7            *   0.8888889                              )) / 2.0 )
        // (( 16   -   6.2222223                                                ) / 2.0 )
        // (   9.7777777                                                          / 2.0 )
        //     4.8888885
		((s.width  - (lensTotalSize * (s.width  / MonocleGlassScaleDenominator))) / 2.0f) + MonocleGlassXOffset,
		((s.height - (lensTotalSize * (s.height / MonocleGlassScaleDenominator))) / 2.0f) + MonocleGlassYOffset
	);
//	NSLog(@"s: %@; lensTotalSize: %f; lensOrigin: %@", NSStringFromSize(s), lensTotalSize, NSStringFromPoint(lensOrigin));
	
	NSAffineTransform *transform = [NSAffineTransform transform];
	//The original implementation used ((s.height / 22) * 10) / 2 as the circle's origin.
	[transform translateXBy:lensOrigin.x
						yBy:lensOrigin.y];
	
	[transform scaleXBy:s.width yBy:s.height];
	[transform scaleBy:(1.0f/MonocleGlassScaleDenominator)];
	[transform concat];
	
	[((nil == strokeColor) ? [NSColor redColor] : strokeColor) setStroke];
	
	//Stroke the lens.
	NSRect circleRect;
	circleRect.origin = NSZeroPoint;
	circleRect.size = NSMakeSize(circleradius * 2.0f, circleradius * 2.0f);
	NSBezierPath *circle = [NSBezierPath bezierPathWithOvalInRect:circleRect];
	[circle setLineWidth:strokeWidth];
	[circle stroke];
	
	//The handle is a 45-degree hypotenuse.
	const float  widthMultiplier = cosf(M_PI_4);
	const float heightMultiplier = sinf(M_PI_4);
	NSBezierPath *handle = [NSBezierPath bezierPath];
	[handle moveToPoint:NSMakePoint(
		handleoffset *  widthMultiplier,
		handleoffset * heightMultiplier
	)];
	[handle relativeLineToPoint:NSMakePoint(
		handlelength *  widthMultiplier,
		handlelength * heightMultiplier
	)];
	[handle setLineWidth:strokeWidth];
	
	//Translate the handle to originate from the center of the lens.
	NSAffineTransform *moveHandleIntoPlaceTransform = [NSAffineTransform transform];
	[moveHandleIntoPlaceTransform translateXBy:NSMidX(circleRect)
										   yBy:NSMidY(circleRect)];
	[handle transformUsingAffineTransform:moveHandleIntoPlaceTransform];
	
	//Stroke the handle.
	[handle stroke];
	
	[im unlockFocus];
	return [im autorelease];
}

@end
