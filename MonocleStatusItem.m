//
//  MonocleStatusItem.m
//  Monocle
//
//  Created by Jesper on 2007-01-21.
//  Copyright 2007 waffle software. All rights reserved.
//

#import "MonocleStatusItem.h"
#import "MonocleController.h"
#import "MonocleSearchWindow.h"

#import "CTGradient.h"
#import "MonocleGlassIconDrawing.h"

@implementation MonocleStatusItem

- (void)awakeFromNib {

	NSStatusBar *sb = [NSStatusBar systemStatusBar];
#if DEBUG_INCLUDE_SPACING_STATUS_ITEM
	debugSpacingStatusItem = [sb statusItemWithLength:NSVariableStatusItemLength];
	[debugSpacingStatusItem setTitle:@"                                             x"];
	[debugSpacingStatusItem retain];
#endif
	
	statusItem = [sb statusItemWithLength:NSSquareStatusItemLength];
	
	float thickness = [sb thickness];//*[[NSScreen mainScreen] userSpaceScaleFactor];
	
	MonocleStatusItemView *siv = [[MonocleStatusItemView alloc] initWithFrame:NSMakeRect(0.0,0.0,thickness,thickness)];
	[statusItem retain];
	[siv setContext:self];
	[statusItem setView:siv];
	[siv release];
}

- (NSStatusItem *)statusItem {
	return statusItem;
}

- (MonocleController *)monocleController {
	return monocleController;
}

- (void)bringUp {
	[(MonocleStatusItemView *)[statusItem view] bringUp];
}

- (void)bringUpOrHide {
	[(MonocleStatusItemView *)[statusItem view] bringUpOrHide];
}

- (void)hide {
//	NSLog(@"status item hide");
	[(MonocleStatusItemView *)[statusItem view] hide];	
}
@end

@implementation MonocleStatusItemView
- (void)setContext:(MonocleStatusItem *)ctx {
	context = ctx;
	static BOOL hasCreatedImages = NO;
	if (!hasCreatedImages) {
		[self createImages];
		hasCreatedImages = YES;
	}
}

//#define	MONOCLE_STATUS_ITEM_DRAW_GRADIENT	1

- (void)createImages {
	NSSize size = [self frame].size;
//	NSLog(@"size: %@", NSStringFromSize(size));
	
	NSImage *off = [[NSImage alloc] initWithSize:size];
	
	NSRect rect = NSMakeRect(0, 0, size.width, size.height);
	/*
	NSRect circleRect = NSInsetRect(rect, 3, 3);
	circleRect.size.height -= 1;
	circleRect.size.width -= 1;
	circleRect.origin.y += 1;
	
		NSBezierPath *circle = [NSBezierPath bezierPathWithOvalInRect:NSOffsetRect(circleRect, 0, -1)];
	[[NSColor colorWithCalibratedWhite:1.0 alpha:0.5] setFill];
	[circle fill];
	
	circle = [NSBezierPath bezierPathWithOvalInRect:circleRect];
	NSColor *c = [NSColor colorWithCalibratedWhite:0.2 alpha:1.0];
#ifdef MONOCLE_STATUS_ITEM_DRAW_GRADIENT
	[[NSGraphicsContext currentContext] saveGraphicsState]; {
		CTGradient *gradient = [CTGradient gradientWithBeginningColor:[c shadowWithLevel:0.4] endingColor:[c highlightWithLevel:0.4]];
		[circle addClip];
		[gradient fillRect:circleRect angle:90];
	} [[NSGraphicsContext currentContext] restoreGraphicsState];
#else
	[c setFill];
	[circle fill];
#endif
	 */
	
#define MonocleUndocumentedInvertMenuIconColorsKey	@"MonocleUndocumentedInvertMenuIconColorsKey"
	
	NSColor *offGlassColor = [NSColor colorWithCalibratedWhite:0.2 alpha:1.0];
	NSColor *onGlassColor = [NSColor whiteColor];
	if ([[NSUserDefaults standardUserDefaults] boolForKey:MonocleUndocumentedInvertMenuIconColorsKey]) {
		NSColor *swap = offGlassColor;
		offGlassColor = onGlassColor;
		onGlassColor = swap;
	}
	
	NSImage *offGrooveGlass = [MonocleGlassIconDrawing imageForSize:size strokeColor:[NSColor colorWithCalibratedWhite:1.0 alpha:0.45]];
	
	NSImage *offGlass = [MonocleGlassIconDrawing imageForSize:size strokeColor:offGlassColor];
	NSPoint startPoint = NSMakePoint((size.width-rect.size.width)/2, (size.height-rect.size.height)/2);
	NSPoint offsetPoint = startPoint;
	offsetPoint.y -= 0.75;
	[off lockFocus];
	[offGrooveGlass dissolveToPoint:offsetPoint fraction:1.0];
	[offGlass dissolveToPoint:startPoint fraction:1.0];
	[off unlockFocus];
	
//	[[off TIFFRepresentation] writeToFile:[@"~/Desktop/offglass.tiff" stringByExpandingTildeInPath] atomically:YES];
	
	icon = off;
	
	NSImage *onGlass = [MonocleGlassIconDrawing imageForSize:size strokeColor:onGlassColor];
	
	NSImage *on = [[NSImage alloc] initWithSize:size];
	[on lockFocus];
	[onGlass dissolveToPoint:startPoint fraction:1.0];
	[on unlockFocus];
	
//	[[on TIFFRepresentation] writeToFile:[@"~/Desktop/onglass.tiff" stringByExpandingTildeInPath] atomically:YES];
	
	selectedIcon = on;
	
#define MonocleUndocumentedUseImagesForMenuKey	@"MonocleUndocumentedUseImagesForMenuKey"
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey:MonocleUndocumentedUseImagesForMenuKey]) {
		NSString *appSupp = [[[NSHomeDirectory() stringByAppendingPathComponent:@"Library"]
							   stringByAppendingPathComponent:@"Application Support"]
							  stringByAppendingPathComponent:@"Monocle"];

		BOOL isDir;
		
		NSString *onImagePath = [appSupp stringByAppendingPathComponent:@"selected.png"];

		if ([[NSFileManager defaultManager] fileExistsAtPath:onImagePath
												 isDirectory:&isDir] && !isDir) {
			NSImage *onImage = [[NSImage alloc] initWithContentsOfFile:onImagePath];
			if (onImage != nil)
				selectedIcon = [onImage copy];
			[onImage release];
		}
		
		NSString *offImagePath = [appSupp stringByAppendingPathComponent:@"notselected.png"];
		if ([[NSFileManager defaultManager] fileExistsAtPath:onImagePath
												 isDirectory:&isDir] && !isDir) {
			NSImage *offImage = [[NSImage alloc] initWithContentsOfFile:offImagePath];
			if (offImage != nil)
				icon = [offImage copy];
			[offImage release];
		}
	}
	

}

- (void)bringUp {
	if (isClicked) return;
//	NSLog(@"bring up");
	[self mouseDown:nil];
}

- (void)bringUpOrHide {
	[self mouseDown:nil];
}

- (void)hide {
//	NSLog(@"status item hide, view");
	if (!isClicked) return;
//	NSLog(@"status item hide, view 2");
//	NSLog(@"hide");
	[self mouseDown:nil];
}


- (void)drawRect:(NSRect)rect {

	[[context statusItem] drawStatusBarBackgroundInRect:rect withHighlight:isClicked];
	
	NSRect insetRect = rect;
	insetRect.origin.x = ((NSWidth(rect) - NSHeight(insetRect)) / 2.0);
	insetRect.size.width = NSHeight(insetRect);
	NSImage *im = (isClicked ? selectedIcon : icon);//[NSImage imageNamed:@"NSApplicationIcon"];
	NSSize imSize = [im size];
	[[NSGraphicsContext currentContext] saveGraphicsState];
	[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
	[im drawInRect:insetRect 
		  fromRect:NSMakeRect(0.0,0.0,imSize.width,imSize.height) operation:NSCompositeSourceOver fraction:1.0];
	[[NSGraphicsContext currentContext] restoreGraphicsState];
		
}

- (void)mouseDown:(NSEvent *)theEvent {
//	NSLog(@"mousedown");
	if (!isClicked) {
		isClicked = YES;
		[self showSheet];
	} else {
		isClicked = NO;
		[self hideSheet];
	}
		
	[self setNeedsDisplay:YES];
}

- (void)mouseUp:(NSEvent *)theEvent {
	[self setNeedsDisplay:YES];
}

- (void)getOnScreenRect:(NSRect *)on offScreenRect:(NSRect *)off {
	MonocleSearchWindow *w = [[context monocleController] searchWindow];
	
	float width = NSWidth([w frame]);
	
	NSPoint p = [[self window] convertBaseToScreen:[self convertPoint:NSMakePoint(NSMidX([self frame]),0.0) toView:nil]];
	NSRect sc = [[NSScreen mainScreen] frame];
	
	if (p.x+(width/2.0) > NSWidth(sc)) {
		p.x = NSWidth(sc)-(width/2.0);
	}
	
	NSRect sh = NSMakeRect(p.x-(width/2.0),p.y,width,1.0);
	
	NSRect t = [w frame];
	
	// WORKAROUND: Height slowly increases by 1 in some cases (such as rapid showing-closing),
	// so we cache the initial panel height here and assign it, and use that in our calculations.
	// Hot damn can I not wait until Core Animation.
	
	if (!hasCachedPanelHeight) {
		panelHeight = NSHeight([w frame]);
		hasCachedPanelHeight = YES;
	}	
	
	t.origin.y = sh.origin.y - panelHeight;
	t.origin.x = sh.origin.x;
	
//	NSLog(@"t.origin.y: %f", t.origin.y);
	
	NSRect f = t;
	
	f.origin.y += (panelHeight * 2.0);
	
	f.size.height = panelHeight;
	t.size.height = panelHeight;
	
	*on = t;
	*off = f;
}

- (void)hideSheet {
	[self animateSheet:NO];
}

- (void)showSheet {
	[self animateSheet:YES];
}

- (void)animateSheet:(BOOL)showing {
//	NSLog((showing ? @"SHOWING SHEET" : @"hiding sheet"));
	
	if (showing)
		[[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
	
	MonocleSearchWindow *w = [[context monocleController] searchWindow];
	
	NSRect f; NSRect t;
	
	if (animation) {
		[animation stopAnimation];
		animation = nil;
	}
	
	if (showing)
		[self getOnScreenRect:&t offScreenRect:&f];	
	else
		[self getOnScreenRect:&f offScreenRect:&t];	
	
	t.origin.y += .01;
	//	t.size.height += 0.1;
	f.origin.y += .01;
	//	f.size.height += 0.1;
	
//	NSLog(@"from: %@, to: %@", NSStringFromRect(f), NSStringFromRect(t));
	
	if (showing) {
//		NSLog(@"A");
		[[context monocleController] tellSearchViewToBringUp];
//		NSLog(@"B");
		[w setFrame:f display:NO];
		[w setAlphaValue:0.0];
	} else {
//		NSLog(@"C");
		[[context monocleController] tellSearchViewToHide];
//		NSLog(@"D");
	}
	
	animationDirectionIsShowing = showing;
	
	animation = [[NSViewAnimation alloc] initWithViewAnimations:
		[NSArray arrayWithObject:
			[NSDictionary dictionaryWithObjectsAndKeys:
				w, NSViewAnimationTargetKey,
				[NSValue valueWithRect:f], NSViewAnimationStartFrameKey,
				[NSValue valueWithRect:t], NSViewAnimationEndFrameKey,
				(showing ? NSViewAnimationFadeInEffect : NSViewAnimationFadeOutEffect), NSViewAnimationEffectKey,
				nil]]];
	[animation setDuration:0.2];
	[animation setDelegate:self];
	[animation startAnimation];
}

- (void)animationDidEnd:(NSAnimation *)animation {
	if (!animationDirectionIsShowing) {
		//	NSLog(@"ordering out window");
		[[[context monocleController] searchWindow] orderOut:self];
	} else {
		[[context monocleController] ready];
	}
}

@end