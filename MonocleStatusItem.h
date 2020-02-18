//
//  MonocleStatusItem.h
//  Monocle
//
//  Created by Jesper on 2007-01-21.
//  Copyright 2007 waffle software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MonocleController;

@interface MonocleStatusItem : NSObject {
	NSStatusItem *statusItem;
	NSStatusItem *debugSpacingStatusItem;
	IBOutlet MonocleController *monocleController;
}
- (NSStatusItem *)statusItem;
- (void)bringUp;
- (void)hide;
- (void)bringUpOrHide;
@end

@interface MonocleStatusItemView : NSView {
	MonocleStatusItem *context;
	BOOL isClicked;
	NSWindow *shim;
	NSViewAnimation *animation;
	BOOL animationDirectionIsShowing;
	
	BOOL hasCachedPanelHeight;
	float panelHeight;
	
	NSImage *icon;
	NSImage *selectedIcon;
}
- (void)setContext:(MonocleStatusItem *)ctx;
- (void)bringUp;
- (void)createImages;
- (void)hide;
- (void)bringUpOrHide;

- (void)getOnScreenRect:(NSRect *)on offScreenRect:(NSRect *)off;
- (void)animateSheet:(BOOL)showing;
- (void)hideSheet;
- (void)showSheet;
@end