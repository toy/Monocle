//
//  MonocleSearchView.h
//  Monocle
//
//  Created by Jesper on 2006-06-17.
//  Copyright 2006 waffle software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/Webkit.h>

@class MonocleController, MonocleSearchField;
@interface MonocleSearchView : NSView {
	
	NSObject *currentSearchText_writerLock;
	NSString *currentSearchText;
	
	MonocleController *controller;
	IBOutlet MonocleSearchField *textField;
	IBOutlet NSImageView *iconView;
	IBOutlet NSPopUpButton *appMenuPopup;
	IBOutlet NSArrayController *controlledEngines;
	IBOutlet NSObjectController *selectedEngine;
	
	IBOutlet WebView *searchHelpWebView;
	
	NSWindow *borderlessSearchHelpWindow;
	
	unsigned int engineIndex;
	NSString *engineName;
	
	BOOL isSearchViewShown;
	
	BOOL isUpdatingSearchhelp;
	BOOL isDisplayingSearchhelp;
	BOOL wantsToUpdateSearchhelp;
	
	BOOL anySearchHelp;
	
	NSViewAnimation *va;
	NSPoint referencePoint;
	
	NSArray *referenceSelectedRanges;
	
	NSPopUpButtonCell *enginePopUpCell;
	NSPopUpButtonCell *appPopUpCell;
	
	NSString *currentSearchhelpIsForString;
	NSArray *currentSearchhelpResults;
	NSMutableDictionary *draftSearchhelpResults;
	NSString *draftSearchhelpIsForString;
	NSArray *currentSearchhelpSuggestions;
	unsigned int currentSearchhelpJob;
	
	NSDictionary *selectedSearchHelp;
	
	NSArray *displaySearchhelp;
	
	NSTimer *searchhelpTimer;
	
	NSColor *searchhelpTableGridColor;
	
	IBOutlet NSMenu *appMenu;
	
	BOOL callwordCacheNeedsRedoing;
	BOOL hasSetSpacesBehavior;
	
	BOOL hideSearchHelpUntilBecomesActive;
	
}
- (MonocleController *)controller;
- (void)setController:(MonocleController *)aController;

- (NSString *)searchText;
- (void)setSearchText:(NSString *)st;

- (IBAction)doSearch:(id)sender;
- (void)performSearch;

- (void)bringUp;
- (void)whenHiding;
- (void)hide;

- (void)whenSelectedEngineChanges;
- (void)nilOutSearchHelp;

- (void)ready;

- (void)nudge;
- (void)searchLaunched;
- (void)appBecameActive;

- (void)showOrHideSearchHelp;

- (BOOL)showsSearchHelp;

- (void)moveSelectionUp;
- (void)moveSelectionDown;
- (void)selectEngineWithIndex:(int)idx;

- (void)moveSearchHelpSelectionUp;
- (void)moveSearchHelpSelectionDown;
- (BOOL)fillInSearchHelp;
- (BOOL)hasNonEmptySearchHelpSelected;

- (void)makeSureSelectedIsNotIncapacitatedAdjustingUp:(BOOL)up;

- (void)upArrowKey;
- (void)downArrowKey;

- (BOOL)rightArrowKey;

- (void)showNextPrev;
- (void)hideNextPrev;

- (void)dirtyCallwordCache;

- (void)popUpEnginesAtTopOrBottom:(BOOL)atTop;

- (void)doPopUpEngines;
- (void)doPopUpMenu;

- (id)selectedEngine;
- (void)reselectBasedOnName;

- (void)hideSearchHelp;
- (void)updateSearchHelp;
- (BOOL)updateSearchHelp:(NSString *)string;
- (void)updateSearchHelpDisplayInfo:(NSNotification *)notificationPerhaps;

- (NSTimeInterval)accordionResizeTime;

- (NSRect)rectByScalingRect:(NSRect)rect toResolutionForScreen:(NSScreen *)screen;
- (NSPoint)pointByScalingPoint:(NSPoint)point toResolutionForScreen:(NSScreen *)screen;
- (NSSize)sizeByScalingSize:(NSSize)size toResolutionForScreen:(NSScreen *)screen;
- (float)floatByScalingFloat:(float)fl toResolutionForScreen:(NSScreen *)screen;
@end
