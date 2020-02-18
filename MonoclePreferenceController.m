//
//  MonoclePreferenceController.m
//  Monocle
//
//  Created by Jesper on 2006-07-15.
//  Copyright 2006 waffle software. All rights reserved.
//

#import "MonoclePreferenceController.h"
#import "MonocleReorderableArrayController.h"
#import "MonocleEngineArrayController.h"
#import "MonocleController.h"
#import "SRRecorderControl.h"
#import "MonoclePreferences.h"
#import "LoadController.h"

#import "MonocleSuggestionProviding.h"

#import "MonocleGlassIconDrawing.h"

#import "MonocleButtonBarStuff.h"

#define	MonoclePreferenceEngines	@"Engines"
#define	MonoclePreferenceSearching	@"Searching"
#define	MonoclePreferenceAppearance	@"Appearance"

#define	MonoclePreferenceHelpButton	@"Help"

#define	MonoclePreferenceSelectedToolbarPanelDefaultKey	@"Selected toolbar panel"
#define	MonoclePreferenceSelectedToolbarPanelDefault	MonoclePreferenceEngines

@implementation DragToReorderTableView

- (void)setReorderableController:(MonocleReorderableArrayController *)controller {
	reorderController = controller;
}

- (void)resetCursorRects {
	if (![reorderController canDrag]) return;
	NSArray *tableColumns = [self tableColumns];
	NSEnumerator *colEnumerator = [tableColumns objectEnumerator];
	NSTableColumn *col;
	int i = 0;
	
	NSCursor *hand = [NSCursor openHandCursor];
	while (col = [colEnumerator nextObject]) {
		if (![[col dataCell] isKindOfClass:[NSButtonCell class]]) {
			[self addCursorRect:[self rectOfColumn:i] cursor:hand];
		}
		i++;
	}
}

- (void)updateCursor {
	if (![reorderController canDrag]) return;
	NSCursor *closed = [NSCursor closedHandCursor];
	if (mouseIsDown) {
		if (![[NSCursor currentCursor] isEqualTo:closed]) {
			[closed push];
		}
	} else {
		if ([[NSCursor currentCursor] isEqualTo:closed]) {
			[closed pop];
		}
	}
}

- (void)draggingStopped {
//	NSLog(@"mouse free (dragging stopped)");
	mouseIsDown = NO;
	[self updateCursor];	
}

- (void)mouseDown:(NSEvent *)theEvent {
//	NSLog(@"mouse pressed");
	mouseIsDown = YES;
	[self updateCursor];
//	[[self window] invalidateCursorRectsForView:self];
	[super mouseDown:theEvent];
}

- (void)mouseUp:(NSEvent *)theEvent {
//	NSLog(@"mouse free");
	mouseIsDown = NO;
	[self updateCursor];
//	[[self window] invalidateCursorRectsForView:self];
	[super mouseUp:theEvent];
}

- (void)mouseEntered:(NSEvent *)theEvent {
	[self resetCursorRects];
	[super mouseEntered:theEvent];
}

- (void)mouseDragged:(NSEvent *)theEvent {
//	NSLog(@"mouse free (dragged)");
	mouseIsDown = NO;
	[self updateCursor];
//	[[self window] invalidateCursorRectsForView:self];
	[super mouseDragged:theEvent];
}

- (void)reorderableLineupDidReorder:(NSArrayController *)lineup {
	mouseIsDown = NO;
	[[[MonocleController controller] prefController] setSearchHelpProvidersManually:lineup];
	[self updateCursor];
}

@end


@interface MonocleCheckBoxToShouldBodgeValueTransformer : NSValueTransformer
+ (Class)transformedValueClass;
+ (BOOL)allowsReverseTransformation;
- (id)transformedValue:(id)value;
@end

@implementation MonocleCheckBoxToShouldBodgeValueTransformer
+ (Class)transformedValueClass {
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation {
    return YES;   
}

- (id)reverseTransformedValue:(id)value {
	if ([value isEqualTo:[NSNumber numberWithBool:YES]])
		return @"underscore";
	else
		return @"percent";
}

- (id)transformedValue:(id)value {
	if ([value isEqualTo:@"underscore"])
		return [NSNumber numberWithBool:YES];
	else
		return [NSNumber numberWithBool:NO];
}

@end

@interface MonocleShouldShowCountryPopUpValueTransformer : NSValueTransformer
+ (Class)transformedValueClass;
+ (BOOL)allowsReverseTransformation;
- (id)transformedValue:(id)value;
@end

@implementation MonocleShouldShowCountryPopUpValueTransformer
+ (Class)transformedValueClass {
    return [NSNumber class];
}

+ (BOOL)allowsReverseTransformation {
    return NO;   
}

- (id)transformedValue:(id)value {
	
//    NSLog(@"google: %@ yahoo: %@", [value valueForKeyPath:@"suggestFromGoogle"], [value valueForKeyPath:@"suggestFromYahoo"]);
    
	
    return [NSNumber numberWithBool:NO];
}
@end

@interface MonocleIsPOSTEngineTransformer : NSValueTransformer
+ (Class)transformedValueClass;
+ (BOOL)allowsReverseTransformation;
- (id)transformedValue:(id)value;
@end

@implementation MonocleIsPOSTEngineTransformer
+ (Class)transformedValueClass {
    return [NSNumber class];
}

+ (BOOL)allowsReverseTransformation {
    return NO;   
}

- (id)transformedValue:(id)value {
	
	BOOL isPOST = NO;
	
	id type = [value valueForKey:@"type"];
	if (type)
		isPOST = ([type isEqualToString:@"POST"]);
	
    return [NSNumber numberWithBool:isPOST];
}
@end


@implementation MonoclePreferenceController
float ToolbarHeightForWindow(NSWindow *window) {
    NSToolbar *toolbar;
    float toolbarHeight = 0.0;
    NSRect windowFrame;
    toolbar = [window toolbar];
    if(toolbar && [toolbar isVisible])
    {
        windowFrame = [NSWindow contentRectForFrameRect:[window frame]
											  styleMask:[window styleMask]];
        toolbarHeight = NSHeight(windowFrame)
			- NSHeight([[window contentView] frame]);
    }
    return toolbarHeight;
}

+ (void)initialize {
	MonocleShouldShowCountryPopUpValueTransformer *trans;
    
	// create an autoreleased instance of our value transformer
	trans = [[[MonocleShouldShowCountryPopUpValueTransformer alloc] init]
		autorelease];
	
	MonocleIsPOSTEngineTransformer *trans2;
	
	trans2 = [[[MonocleIsPOSTEngineTransformer alloc] init] autorelease];
	
	// register it with the name that we refer to it with
	[NSValueTransformer setValueTransformer:trans
									forName:@"MonocleShouldShowCountryPopUp"];	
	
	[NSValueTransformer setValueTransformer:trans2 forName:@"MonocleIsPOSTEngine"];
	
	[NSValueTransformer setValueTransformer:[[[MonocleCheckBoxToShouldBodgeValueTransformer alloc] init] autorelease] forName:@"MonocleCheckBoxToShouldBodge"];
}

- (void)markEngineChanged:(id)engine {
	NSIndexSet *is = [self indexSetForEngine:engine];
	[udc willChange:NSKeyValueChangeSetting valuesAtIndexes:is forKey:@"engines"];
	[udc didChange:NSKeyValueChangeSetting valuesAtIndexes:is forKey:@"engines"];
}

- (NSIndexSet *)indexSetForEngine:(id)engine {
	NSArray *arrangedObjects = [engineController arrangedObjects];
	unsigned int index = [arrangedObjects indexOfObject:engine];
	if (index == NSNotFound) return [NSIndexSet indexSet];
	return [NSIndexSet indexSetWithIndex:index];
}

- (IBAction)showEngineSpecificSearchHelpSheet:(id)sender {
	[self willChangeValueForKey:@"engineSpecificSearchHelpProviders"];
	engineSpecificSearchHelpers = [[self constructSearchHelpersForEngine:[engineController selection]] retain];
	[self didChangeValueForKey:@"engineSpecificSearchHelpProviders"];	
	
	[self useSpecificSetupChanged:nil];
	
	[NSApp beginSheet:searchHelpSheet
	   modalForWindow:mainWindow
		modalDelegate:self
	   didEndSelector:@selector(didEndSheet:returnCode:contextInfo:)
		  contextInfo:nil];
}
- (IBAction)closeEngineSpecificSearchHelpSheet:(id)sender {
	[NSApp endSheet:searchHelpSheet];
}

- (void) awakeFromNib {
	
	[self willChangeValueForKey:@"searchHelpProviders"];
	searchHelpers = [[self constructSearchHelpers] retain];
	[self didChangeValueForKey:@"searchHelpProviders"];
	
	[self willChangeValueForKey:@"engineSpecificSearchHelpProviders"];
	engineSpecificSearchHelpers = [NSMutableArray array];
	[self didChangeValueForKey:@"engineSpecificSearchHelpProviders"];
	
	[udc addObserver:self
				   forKeyPath:@"values.suggestFromGoogle"
					  options:0
					  context:NULL];
	
	[udc addObserver:self
				   forKeyPath:@"values.suggestFromYahoo"
					  options:0
					  context:NULL];
	
	[callwordFormatField setTokenizingCharacterSet:[[NSCharacterSet characterSetWithCharactersInString:@""] invertedSet]];
	
	[searchHelperController setCanSelectRow:NO];
	[engineSpecificSearchHelperController setCanSelectRow:NO];
	[searchHelpersTable selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
	
	[searchHelperController setPostDragDelegate:searchHelpersTable];
	[engineSpecificSearchHelperController setPostDragDelegate:engineSpecificSearchHelpersTable];
	
	[addSheetEditingPlaceholder addSubview:editingView];
	
	[self setupToolbar];
	
	[hotKeyRecorder setDelegate:self];
	
	[self buildStyleMenu];
	
	NSSize intercellSpacing = [enginesTable intercellSpacing];
	intercellSpacing.height = 0;
	intercellSpacing.width--;
	[enginesTable setIntercellSpacing:intercellSpacing];
	
/*	NSImage *addBtn = [MonocleButtonBarStuff buttonImageFromImage:[addEngineButton image]];
	[addEngineButton setImage:addBtn];
	NSImage *removeBtn = [MonocleButtonBarStuff buttonImageFromImage:[removeEngineButton image]];
	[removeEngineButton setImage:removeBtn];*/
	
/*	[removeEngineButton setAction:@selector(removeEngineAfterAsking:)];
	[removeEngineButton setTarget:self];*/
	
    [engineController registerTableViewToReceiveDrags:enginesTable];
    [searchHelperController registerTableViewToReceiveDrags:searchHelpersTable];
	[engineSpecificSearchHelperController registerTableViewToReceiveDrags:engineSpecificSearchHelpersTable];
	
	[mainWindow makeKeyAndOrderFront:self];
}

- (IBAction)removeEngineAfterAsking:(id)sender {
	NSAlert *al = [NSAlert alertWithMessageText:[NSString stringWithFormat:@"Do you want to remove the \"%@\" engine?", [engineController valueForKeyPath:@"selection.name"]] defaultButton:@"Delete engine" alternateButton:@"Cancel" otherButton:nil informativeTextWithFormat:@"This can't be undone."];
	[al beginSheetModalForWindow:mainWindow modalDelegate:self didEndSelector:@selector(removeEngineAfterAskingAlertDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (void)removeEngineAfterAskingAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	if (returnCode == NSAlertDefaultReturn) {
		NSIndexSet *idxs = [engineController selectionIndexes];
		unsigned int idxOfSel = [[self indexSetForEngine:[monocleController selectedEngine]] firstIndex];
		[engineController removeObjectsAtArrangedObjectIndexes:[engineController selectionIndexes]];
		[engineController rearrangeObjects];
		if ([idxs containsIndex:idxOfSel]) {
			if (idxOfSel == 0) {
				[monocleController selectEngineWithIndex:0];
			} else {
				[monocleController selectEngineWithIndex:idxOfSel-1];
			}
		}
	}
}

- (NSArray *)callwordSequence {
	return ([callwordFormatField objectValue] == nil ? [NSArray arrayWithObjects:@":", @"#callword#", @" ", nil] : [callwordFormatField objectValue]);
}

- (void)setCallwordSequence:(NSArray *)s {
	[callwordFormatField setObjectValue:s];
	return;
//	[NSArray arrayWithObjects:@":", @"#callword#", @" "];
}

- (NSString *)tokenField:(NSTokenField *)tokenField displayStringForRepresentedObject:(id)representedObject {
//	NSLog(@"display string for represented object: %@", representedObject);
	return [representedObject description];
}

- (NSString *)tokenField:(NSTokenField *)tokenField editingStringForRepresentedObject:(id)representedObject {
//	NSLog(@"editing string for represented object: %@", representedObject);
	return [representedObject description];
}

- (NSArray *)tokenField:(NSTokenField *)tokenField shouldAddObjects:(NSArray *)tokens atIndex:(unsigned)index {
//	NSLog(@"should add objects: %@ at index: %i", tokens, index);
	return tokens;
}

- (id)tokenField:(NSTokenField *)tokenField representedObjectForEditingString:(NSString *)editingString {
//	NSLog(@"represented object for editing string: %@", editingString);
	return editingString;
}

- (void)shortcutRecorder:(SRRecorderControl *)aRecorder keyComboDidChange:(KeyCombo)newKeyCombo {
	if (aRecorder == hotKeyRecorder)
	{
//		NSLog(@"key combo did change! (%@)", SRStringForCocoaModifierFlagsAndKeyCode(newKeyCombo.flags,newKeyCombo.code));
		[monocleController fixGlobalHotKey:aRecorder];
	}
}

- (void)setupPostDragDelegate:(id)del {
	[engineController setPostDragDelegate:del];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
//	NSLog(@"google or yahoo did change");
	[self willChangeValueForKey:@"labelForSuggestFromCountry"];
	[self didChangeValueForKey:@"labelForSuggestFromCountry"];
	[self willChangeValueForKey:@"suggestFromCountryIsEnabled"];
	[self didChangeValueForKey:@"suggestFromCountryIsEnabled"];
}

- (void) setupToolbar {
//	NSLog(@"set up toolbar");
	
	NSImage *appIcon = [NSImage imageNamed:@"NSApplicationIcon"];
	
	NSImage *enginesIcon = [[[NSImage alloc] initByReferencingFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"engines-icon" ofType:@"png"]] autorelease];
	NSImage *generalIcon = [[[NSImage alloc] initByReferencingFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"general" ofType:@"tiff"]] autorelease];
	
	NSDictionary *choices = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSDictionary dictionaryWithObjectsAndKeys:
			MonoclePreferenceEngines, @"label",
			enginesIcon, @"image",
			enginesView, @"view",
			nil], MonoclePreferenceEngines,
		[NSDictionary dictionaryWithObjectsAndKeys:
			@"General", @"label",
			generalIcon, @"image",
			appearanceView, @"view",
			nil], MonoclePreferenceAppearance,
		[NSDictionary dictionaryWithObjectsAndKeys:
			MonoclePreferenceSearching, @"label",
			appIcon, @"image",
			searchingView, @"view",
			nil], MonoclePreferenceSearching,
		nil];
	
//	toolbarChoices = [[NSArray arrayWithObjects:MonoclePreferenceEngines, MonoclePreferenceAppearance, NSToolbarFlexibleSpaceItemIdentifier, MonoclePreferenceHelpButton, nil] retain];
	toolbarChoices = [[NSArray arrayWithObjects:MonoclePreferenceEngines, MonoclePreferenceAppearance, MonoclePreferenceSearching, nil] retain];
	
	NSMutableDictionary *viewForToolbarChoiceM = [NSMutableDictionary dictionary];
	NSMutableDictionary *labelForToolbarChoiceM = [NSMutableDictionary dictionary];
	NSMutableDictionary *iconForToolbarChoiceM = [NSMutableDictionary dictionary];
	NSMutableDictionary *viewHeightsM = [NSMutableDictionary dictionary];
	
	[labelForToolbarChoiceM setObject:@"Help" forKey:MonoclePreferenceHelpButton];
	
	NSEnumerator *choiceEnumerator = [choices keyEnumerator];
	NSString *key;
	while (key = [choiceEnumerator nextObject]) {
		NSDictionary *engineDict = (NSDictionary *)[choices objectForKey:key];
		[viewForToolbarChoiceM setObject:[engineDict objectForKey:@"view"] forKey:key];
		[labelForToolbarChoiceM setObject:[engineDict objectForKey:@"label"] forKey:key];
		[iconForToolbarChoiceM setObject:[engineDict objectForKey:@"image"] forKey:key];
		[viewHeightsM setObject:[NSNumber numberWithFloat:[[engineDict objectForKey:@"view"] frame].size.height] forKey:key];
	} 
	
    [viewForToolbarChoice release];
	viewForToolbarChoice = [viewForToolbarChoiceM copy];
    [labelForToolbarChoice release];
	labelForToolbarChoice = [labelForToolbarChoiceM copy];
    [iconForToolbarChoice release];
	iconForToolbarChoice = [iconForToolbarChoiceM copy];
    [viewHeights release];
	viewHeights = [viewHeightsM copy];
	
	/*
	
	
	viewForToolbarChoice = [[NSDictionary dictionaryWithObjectsAndKeys:enginesView, MonoclePreferenceEngines, searchingView, MonoclePreferenceSearching, appearanceView, MonoclePreferenceAppearance, nil] retain];
	labelForToolbarChoice = [[NSDictionary dictionaryWithObjectsAndKeys:MonoclePreferenceEngines, MonoclePreferenceEngines, MonoclePreferenceSearching, MonoclePreferenceSearching, MonoclePreferenceAppearance, MonoclePreferenceAppearance, nil] retain];
	
	NSImage *enginesImage = [NSImage imageNamed:@"NSApplicationIcon"]; //[[[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"PrefsEngineIcon" ofType:@"tiff"]] retain];
	[enginesImage setName:@"EnginesIcon"];
	NSImage *searchingImage = [NSImage imageNamed:@"NSApplicationIcon"];
	[searchingImage setName:@"SearchingIcon"];
	NSImage *appearanceImage = [NSImage imageNamed:@"NSApplicationIcon"];
	[appearanceImage setName:@"AppearanceIcon"];
	
	iconForToolbarChoice = [[NSDictionary dictionaryWithObjectsAndKeys:enginesImage, MonoclePreferenceEngines, 
		searchingImage, MonoclePreferenceSearching, appearanceImage, MonoclePreferenceAppearance, nil] retain];*/
	toolbar = [[NSToolbar alloc] initWithIdentifier:@"MonoclePreferenceToolbar"];
	[toolbar setDelegate:self];
	/*viewHeights = [[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:[enginesView frame].size.height], MonoclePreferenceEngines,
		[NSNumber numberWithFloat:[searchingView frame].size.height], MonoclePreferenceSearching,
		[NSNumber numberWithFloat:[appearanceView frame].size.height], MonoclePreferenceAppearance,
		nil] retain];*/
	
	NSString *selectedIdentifier;
	if (!(selectedIdentifier = [[NSUserDefaults standardUserDefaults] objectForKey:MonoclePreferenceSelectedToolbarPanelDefaultKey])) {
		selectedIdentifier = MonoclePreferenceSelectedToolbarPanelDefault;
	}
	[toolbar setSelectedItemIdentifier:selectedIdentifier];
	currentView = [viewForToolbarChoice objectForKey:[toolbar selectedItemIdentifier]];
	[mainWindow setTitle:[labelForToolbarChoice objectForKey:[toolbar selectedItemIdentifier]]];
	
	[mainWindow setContentSize:[currentView frame].size];
	NSEnumerator *viewEnu = [viewForToolbarChoice keyEnumerator];
	NSView *enumeratedView;
	while(key = [viewEnu nextObject]) {
		if (enumeratedView = [viewForToolbarChoice objectForKey:key]) {
			[[mainWindow contentView] addSubview:enumeratedView];
			[enumeratedView setHidden:[key isNotEqualTo:[toolbar selectedItemIdentifier]]];
		}
	}
	[mainWindow setToolbar:toolbar];
//	NSLog(@"done setting up toolbar");
}

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) aToolbar {
    return toolbarChoices;
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) aToolbar {
	return [self toolbarDefaultItemIdentifiers:aToolbar];
}

- (NSArray *)toolbarSelectableItemIdentifiers: (NSToolbar *)aToolbar {
	NSMutableArray *arr = [[self toolbarDefaultItemIdentifiers:aToolbar] mutableCopy];
	[arr removeObject:MonoclePreferenceHelpButton];
	[arr removeObject:NSToolbarFlexibleSpaceItemIdentifier];
	return [arr autorelease];
}


- (NSToolbarItem *) toolbar:(NSToolbar *)aToolbar
      itemForItemIdentifier:(NSString *)itemIdentifier
  willBeInsertedIntoToolbar:(BOOL)flag
{
    NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdentifier] autorelease];
	if ([itemIdentifier isEqualTo:MonoclePreferenceHelpButton]) {
		[toolbarItem setLabel:[labelForToolbarChoice objectForKey:itemIdentifier]];
		[toolbarItem setPaletteLabel:[labelForToolbarChoice objectForKey:itemIdentifier]];
		[toolbarItem setView:helpButtonView];
		[toolbarItem setMinSize:[helpButtonView frame].size];
		[toolbarItem setMaxSize:[helpButtonView frame].size];
		NSMenuItem *menuRep = [[NSMenuItem alloc] initWithTitle:[labelForToolbarChoice objectForKey:itemIdentifier]
														 action:[helpButton action]
												  keyEquivalent:@""];
		[menuRep setTarget:[helpButton target]];
		[toolbarItem setMenuFormRepresentation:[menuRep autorelease]];
	} else if ([toolbarChoices containsObject:itemIdentifier]) {
		[toolbarItem setLabel:[labelForToolbarChoice objectForKey:itemIdentifier]];
		[toolbarItem setPaletteLabel:[labelForToolbarChoice objectForKey:itemIdentifier]];
		[toolbarItem setImage:[iconForToolbarChoice objectForKey:itemIdentifier]];
		[toolbarItem setTarget:self];
		[toolbarItem setAction:@selector(changePanel:)];
	} else {
		toolbarItem = nil;
	}
    return toolbarItem;
}

#define MONOCLE_HIDPI	1

- (void) changePanel:(id)sender {
#if MONOCLE_HIDPI
	//	HULog(@"change");
	if (nil != sender) {
		//		[tableView selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
		NSToolbarItem *tbi = (NSToolbarItem *)sender;
		
		/** Why do we do this? Because if we tab to a toolbar button and hit it with space, it won't be selected otherwise. */
		[toolbar setSelectedItemIdentifier:[tbi itemIdentifier]];
		[mainWindow setTitle:[labelForToolbarChoice objectForKey:[toolbar selectedItemIdentifier]]];
		
		NSView *toBeView = [viewForToolbarChoice objectForKey:[tbi itemIdentifier]];
		NSSize sizeOfToBeView = ([toBeView frame]).size;
		
		NSPoint basePoint = [mainWindow convertScreenToBase:[mainWindow frame].origin];
		NSRect contentRect = NSMakeRect(basePoint.x, basePoint.y, sizeOfToBeView.width, sizeOfToBeView.height); /* SCREEN COORDS */
		
		NSRect mainWindowOldScreenFrame = [mainWindow frame];
		NSRect contentRectScaledToScreen = contentRect;
		
		NSRect mainWindowNewScreenFrame = [mainWindow frameRectForContentRect:contentRectScaledToScreen];
		double heightDelta = NSHeight(mainWindowNewScreenFrame) - NSHeight(mainWindowOldScreenFrame);
		mainWindowNewScreenFrame.origin.x = mainWindowOldScreenFrame.origin.x;
		mainWindowNewScreenFrame.origin.y = mainWindowOldScreenFrame.origin.y - heightDelta;

		oldView = currentView;
		currentView = [viewForToolbarChoice objectForKey:[tbi itemIdentifier]];
		if(oldView != currentView) {
			
			contentRect.origin.x = 0.0;
			contentRect.origin.y = 0.0;
			
			contentRect.size = [[viewForToolbarChoice objectForKey:[tbi itemIdentifier]] frame].size;
			
			
			
			// The following information is from Apple's Sample Code project "iSpend":
			// WORKAROUND: There is a bug in NSViewAnimation where the window frame will not be set to its final value.  We could fix this by adjusting the window frame in -animationDidEnd:, but that would result in a bumpy animation where the view and window would get out of sync.  Instead, we do a little trick here, where we set the window frame to a non-integral value knowing this will defeat the problematic check in NSViewAnimation.  Because NSViewAnimation always adjust the window frame to an integral value, this trick will be harmless.
			mainWindowNewScreenFrame.origin.x += 0.001;
//			NSLog(@"width: %f", mainWindowNewScreenFrame.size.width);
			mainWindowNewScreenFrame.size.width = [mainWindow frame].size.width-0.001;
//			NSLog(@"new width: %f", mainWindowNewScreenFrame.size.width);
			
			/*2008-01-11 18:27:37.398 Monocle[7467:10b] mainWindowNewScreenFrame: {{164.01, 304}, {516.99, 474}}, contentRect: {{0, 0}, {517, 396}} */
/*			NSLog(@"mainWindowNewScreenFrame: %@, contentRect: %@",
				  NSStringFromRect(mainWindowNewScreenFrame), NSStringFromRect(contentRect));*/
			
			animation = [[NSViewAnimation alloc]
						 initWithViewAnimations:[NSArray arrayWithObjects:
												 [NSDictionary dictionaryWithObjectsAndKeys:
												  mainWindow,									NSViewAnimationTargetKey,
												  [NSValue valueWithRect:mainWindowNewScreenFrame],				NSViewAnimationEndFrameKey,
												  nil],
												 [NSDictionary dictionaryWithObjectsAndKeys:
												  oldView,									NSViewAnimationTargetKey,
												  NSViewAnimationFadeOutEffect,				NSViewAnimationEffectKey,
												  [NSValue valueWithRect:[oldView frame]],	NSViewAnimationEndFrameKey,
												  nil],
												 [NSDictionary dictionaryWithObjectsAndKeys:
												  currentView,								NSViewAnimationTargetKey,
												  NSViewAnimationFadeInEffect,				NSViewAnimationEffectKey,
												  [NSValue valueWithRect:contentRect],		NSViewAnimationEndFrameKey,
												  nil],
												 nil]
						 ];
			NSTimeInterval dur = [mainWindow animationResizeTime:mainWindowNewScreenFrame];
			if (([[[NSApplication sharedApplication] currentEvent] modifierFlags] & NSShiftKeyMask))
				dur *= 5.0;
			[animation setDuration:dur];
			[animation setDelegate:self];
			[currentView setHidden:YES];
			
			[animation startAnimation];
			[[NSUserDefaults standardUserDefaults] setObject:[toolbar selectedItemIdentifier] forKey:MonoclePreferenceSelectedToolbarPanelDefaultKey];
		}
	}
#else	
	
	//	HULog(@"change");
	if (nil != sender) {
		//		[tableView selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
		NSToolbarItem *tbi = (NSToolbarItem *)sender;
		
		/** Why do we do this? Because if we tab to a toolbar button and hit it with space, it won't be selected otherwise. */
		[toolbar setSelectedItemIdentifier:[tbi itemIdentifier]];
		[mainWindow setTitle:[labelForToolbarChoice objectForKey:[toolbar selectedItemIdentifier]]];
		NSRect rect = [mainWindow frame];
		NSRect rect2 = rect;
		rect.size.height = [[viewForToolbarChoice objectForKey:[tbi itemIdentifier]] frame].size.height;
		NSRect rect3 = rect;
		rect.size.height += ToolbarHeightForWindow(mainWindow); // tack on height of toolbar
		rect = [NSWindow frameRectForContentRect:rect styleMask:NSTitledWindowMask]; // add height of window chrome
		rect.origin.y += (rect2.size.height - rect.size.height); // adjust y position so that window doesn't 'sink'
		oldView = currentView;
		currentView = [viewForToolbarChoice objectForKey:[tbi itemIdentifier]];
		if(oldView != currentView) {
			NSRect contentRect = rect3;
			
			contentRect.origin.x = 0.0;
			contentRect.origin.y = 0.0;
			
			// The following information is from Apple's Sample Code project "iSpend":
			// WORKAROUND: There is a bug in NSViewAnimation where the window frame will not be set to its final value.  We could fix this by adjusting the window frame in -animationDidEnd:, but that would result in a bumpy animation where the view and window would get out of sync.  Instead, we do a little trick here, where we set the window frame to a non-integral value knowing this will defeat the problematic check in NSViewAnimation.  Because NSViewAnimation always adjust the window frame to an integral value, this trick will be harmless.
			rect.origin.x += .01;
			rect.size.width = [mainWindow frame].size.width-0.01;
			
			animation = [[NSViewAnimation alloc]
					initWithViewAnimations:[NSArray arrayWithObjects:
						[NSDictionary dictionaryWithObjectsAndKeys:
							mainWindow,									NSViewAnimationTargetKey,
							[NSValue valueWithRect:rect],				NSViewAnimationEndFrameKey,
							nil],
						[NSDictionary dictionaryWithObjectsAndKeys:
							oldView,									NSViewAnimationTargetKey,
							NSViewAnimationFadeOutEffect,				NSViewAnimationEffectKey,
							[NSValue valueWithRect:[oldView frame]],	NSViewAnimationEndFrameKey,
							nil],
						[NSDictionary dictionaryWithObjectsAndKeys:
							currentView,								NSViewAnimationTargetKey,
							NSViewAnimationFadeInEffect,				NSViewAnimationEffectKey,
							[NSValue valueWithRect:contentRect],		NSViewAnimationEndFrameKey,
							nil],
						nil]
				];
			NSTimeInterval dur = [mainWindow animationResizeTime:rect];
			if (([[[NSApplication sharedApplication] currentEvent] modifierFlags] & NSShiftKeyMask))
				dur *= 5.0;
			[animation setDuration:dur];
			[animation setDelegate:self];
			[currentView setHidden:YES];
			
			[animation startAnimation];
			[[NSUserDefaults standardUserDefaults] setObject:[toolbar selectedItemIdentifier] forKey:MonoclePreferenceSelectedToolbarPanelDefaultKey];
		}
	}
#endif
}

- (void)animationDidEnd:(NSAnimation*)anim {
	[currentView display];
}

- (NSString *)labelForSuggestFromCountry {
/*	NSNumber *google = [[udc values] valueForKeyPath:@"suggestFromGoogle"];
	NSNumber *yahoo = [[udc values] valueForKeyPath:@"suggestFromYahoo"];
	if ([google boolValue] && ![yahoo boolValue])
		return @"Fetch from Google in:";
	else if (![google boolValue] && [yahoo boolValue])
		return @"Fetch from Yahoo! in:";
	else*/
		return @"Fetch from Google/Yahoo! in:";
}

- (BOOL)suggestFromCountryIsEnabled {
	NSNumber *google = [[udc values] valueForKeyPath:@"suggestFromGoogle"];
	NSNumber *yahoo = [[udc values] valueForKeyPath:@"suggestFromYahoo"];
	return ([google boolValue] || [yahoo boolValue]);
}

- (void)setMonocleController:(MonocleController *)mc {
	monocleController = mc;
}

- (MonocleController *)monocleController {
	return monocleController;
}

- (BOOL)hasAddableSpecialEngines {
//	NSLog(@"has addable special engines called");
	NSArray *a = [monocleController valueForKeyPath:@"addableSpecialEngines"];
//	NSLog(@"result: %@", a);
	return !(a && [a count] > 0);
}

- (NSArray *)addableSpecialEngines {
//	NSLog(@"addable special engines called");
	NSArray *a = [monocleController valueForKeyPath:@"addableSpecialEngines"];
//	NSLog(@"result: %@", a);
	if (a && [a count] > 0) {
		NSMutableArray *ma = [a mutableCopy];
		[ma insertObject:@"Add special engine" atIndex:0];
		return [ma autorelease];
	}
	return nil;
}

- (IBAction)showEditSheet:(id)sender {
//	id sel = [[engineController selectedObjects] objectAtIndex:0];
//	NSLog(@"selected engine: %@, class: %@", sel, [sel className]);
	[editSheetEditingPlaceholder addSubview:editingView];
	[NSApp beginSheet:editSheet
	   modalForWindow:mainWindow
		modalDelegate:self
	   didEndSelector:@selector(didEndSheet:returnCode:contextInfo:)
		  contextInfo:nil];
}

- (IBAction)closeEditSheet:(id)sender {
	[editSheet makeFirstResponder:nil];
	[NSApp endSheet:editSheet];
}

#define MonocleAddEngineDefaultName		@"New engine"
#define MonocleAddEngineDefaultURL		@"http://example.com/?%@"


- (IBAction)showAddSheet:(id)sender {
	[addSheetEditingPlaceholder addSubview:editingView];
	
	NSMutableDictionary *toPrefs = [[NSDictionary dictionary] mutableCopy];
	
	NSImage *icon = [MonocleGlassIconDrawing imageForSize:NSMakeSize(16.0, 16.0) strokeColor:[NSColor blackColor]];
	NSValueTransformer *vt = [NSValueTransformer valueTransformerForName:NSUnarchiveFromDataTransformerName];
	[toPrefs setObject:[vt reverseTransformedValue:icon] forKey:@"icon"];
	
	[toPrefs setObject:MonocleAddEngineDefaultName forKey:@"name"];
	[toPrefs setObject:MonocleAddEngineDefaultURL forKey:@"get_URL"];
//	[toPrefs setObject:[icon TIFFRepresentation] forKey:@"icon"];
	[toPrefs setObject:@"GET" forKey:@"type"];
	[toPrefs setObject:[NSArray array] forKey:@"post_data"];
	[toPrefs setObject:[NSNumber numberWithBool:YES] forKey:@"toBeAdded"];
	
//	NSLog(@"add object: %@", toPrefs);
	
	[engineController addObject:[toPrefs autorelease]];
	[engineController setSelectionIndex:[[engineController arrangedObjects] count]-1];
	
	[NSApp beginSheet:addSheet
	   modalForWindow:mainWindow
		modalDelegate:self
	   didEndSelector:@selector(didEndSheet:returnCode:contextInfo:)
		  contextInfo:nil];
}

- (IBAction)cancelAddSheet:(id)sender {
	[addSheet makeFirstResponder:nil];
	[NSApp endSheet:addSheet];	
	
	unsigned int idx = [[engineController arrangedObjects] count]-1;
	
	NSDictionary *obj = [[engineController arrangedObjects] objectAtIndex:idx];
	if ([(NSNumber *)[obj objectForKey:@"toBeAdded"] boolValue])
		[engineController removeObjectAtArrangedObjectIndex:idx];
	
//	NSLog(@"delete obj: %@", obj);
	
//	[engineController removeObjectAtArrangedObjectIndex:[[engineController arrangedObjects] count]-1];
	
}

- (IBAction)saveAddSheet:(id)sender {
	[addSheet makeFirstResponder:nil];	
	[NSApp endSheet:addSheet];	

	[[engineController selection] setValue:nil forKey:@"toBeAdded"];
}

- (IBAction)showDiscoverSheet:(id)sender {
	[(LoadController *)[discoverSheet windowController] startStuff];
	[NSApp beginSheet:discoverSheet
	   modalForWindow:mainWindow
		modalDelegate:self
	   didEndSelector:@selector(didEndSheet:returnCode:contextInfo:)
		  contextInfo:nil];
}

- (IBAction)saveAndCloseDiscoverSheet:(id)sender {
	[(LoadController *)[discoverSheet windowController] saveEngines];
//	[NSException raise:@"NotImplementedException" format:@"NOT IMPLEMENTED SAVING ENGINES! FIXME!"];
	
	[self closeDiscoverSheet:sender];
}

- (IBAction)closeDiscoverSheet:(id)sender {
	[(LoadController *)[discoverSheet windowController] closing];
	[NSApp endSheet:discoverSheet];	
}

- (void)didEndSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:self];
}


- (IBAction)statusItemStyleChanged:(id)sender {
	
	if ([[[statusItemStyle selectedItem] representedObject] objectForKey:@"no-sheen"]) {
		[hasSheenCheckbox setEnabled:NO];
	} else {
		[hasSheenCheckbox setEnabled:YES];
	}
	
	if (([[statusItemStyle selectedItem] tag] == 4000) &&
		([[[udc values] valueForKey:@"SearchBarStyle"] isNotEqualTo:[[[statusItemStyle selectedItem] representedObject] objectForKey:@"title"]])) {
		
		NSColorPanel *cp = [NSColorPanel sharedColorPanel];
		
		[cp setTarget:self];
		[cp setAction:@selector(setCustomStatusItemStyle:)];
		
		[cp setColor:[[[statusItemStyle selectedItem] representedObject] objectForKey:@"color"]];
		
		[cp orderFront:self];
		
		[statusItemStyle selectItemWithTag:4000];
		
	}
	
	[[udc values] setValue:[[[statusItemStyle selectedItem] representedObject] objectForKey:@"title"]  forKey:@"SearchBarStyle"];
//	[def synchronize];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"SearchBarStyleChanged" object:nil];
}

- (void) setCustomStatusItemStyle:(id)sender {
	[[udc values] setValue:[NSArchiver archivedDataWithRootObject:[sender color]] forKey:@"SearchBarCustomColor"];
	[self buildStyleMenu];
	[statusItemStyle selectItemWithTag:4000];
	[self statusItemStyleChanged:self];
}

- (void) buildStyleMenu {
	
	styles = [monocleController statusItemStyles];
	[styles retain];
	
	NSString *selectedStyle = [[udc values] valueForKey:@"SearchBarStyle"];
	
	NSEnumerator *styleEnumerator = [styles objectEnumerator];
	NSDictionary *style;
	NSMenuItem *mi;
	NSMenu *me = [[[NSMenu alloc] initWithTitle:@""] autorelease];
	int tag = 2000; int selTag = 4000; int fallbackTag = selTag;
	while (style = [styleEnumerator nextObject]) {
		
//		NSLog(@"style: %@", style);
		
		mi = [[[NSMenuItem alloc] initWithTitle:[style objectForKey:@"title"]
										action:@selector(statusItemStyleChanged:)
								 keyEquivalent:@""] autorelease];
		[mi setRepresentedObject:style];
		[mi setImage:[monocleController imageForStatusItemStyle:style]];
		[mi setTarget:self];
		[mi setTag:tag];
		if ([[style objectForKey:@"title"] isEqualToString:@"Custom"]) {
			[mi setTitle:[NSString stringWithFormat:@"Custom%C", 0x2026]];
			tag = 4000;
			[mi setTag:tag];
		}
		if ([style objectForKey:@"fallback"]) {
			fallbackTag = tag;
		}
		if ([style objectForKey:@"start"]) {
			[me addItem:[NSMenuItem separatorItem]];	
		}
		if ([selectedStyle isEqualToString:[style objectForKey:@"title"]])
			selTag = tag;
		
		[me addItem:mi];
		tag += 5;
	} 
	
	[statusItemStyle setMenu:me];
	if (selectedStyle != nil)
		[statusItemStyle selectItemWithTag:selTag];
	else
		[statusItemStyle selectItemWithTag:fallbackTag];
	
	if ([[[statusItemStyle selectedItem] representedObject] objectForKey:@"no-sheen"]) {
		[hasSheenCheckbox setEnabled:NO];
	} else {
		[hasSheenCheckbox setEnabled:YES];
	}
	
	[styles release];	
}

- (NSMutableArray *)constructSearchHelpers {
	
//	NSLog(@"construct search helpers");
	
	NSDictionary *providers = [MonocleSuggestionProvider providers];
	
//	NSLog(@"providers: %@", providers);
	
	NSArray *order = [MonoclePreferences arrayForKey:@"SearchHelpProvidersOrder" orDefault:[MonocleSuggestionProvider providerIdentifiers]];
	NSArray *enabledProviders = [MonoclePreferences arrayForKey:@"SearchHelpProvidersEnabled" orDefault:[MonocleSuggestionProvider providerIdentifiers]];
	
	NSMutableDictionary *byID = [NSMutableDictionary dictionary];
	
	NSEnumerator *rEnumerator = [[providers objectForKey:@"r"] objectEnumerator];
	id<MonocleResultProviding> rs;
	NSDictionary *dict;
	NSMutableArray *provs = [[NSMutableArray array] retain];
	while (rs = [rEnumerator nextObject]) {
		MonocleProviderInfo info = [rs resultsProviderInfo];
		NSString *identifier = [rs resultsSourceIdentifier];
		dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
				info.icon, @"icon",
				info.label, @"name",
				[NSNumber numberWithBool:[enabledProviders containsObject:identifier]], @"isChecked",
				[rs resultsSource], @"source", 
				identifier, @"identifier", 
				nil];
		[byID setObject:dict forKey:identifier];
//		NSLog(@"added results entry for %@, %@", identifier, dict);
		//		[provs addObject:dict];
	} 
	
	NSEnumerator *sEnumerator = [[providers objectForKey:@"s"] objectEnumerator];
	id<MonocleSuggestionProviding> ss;
	while (ss = [sEnumerator nextObject]) {
		MonocleProviderInfo info = [ss suggestionsProviderInfo];
		NSString *identifier = [ss suggestionsSourceIdentifier];
		dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
				info.icon, @"icon",
				info.label, @"name",
				[NSNumber numberWithBool:[enabledProviders containsObject:identifier]], @"isChecked",
				[ss suggestionsSource], @"source",
				identifier, @"identifier", 
				nil];
		[byID setObject:dict forKey:identifier];
		//		[provs addObject:dict];
	} 
	
	NSEnumerator *inOrderEnumerator = [order objectEnumerator];
	NSString *identifier;
	while (identifier = [inOrderEnumerator nextObject]) {
		NSDictionary *prov = [byID objectForKey:identifier];
		if (prov) {
			[provs addObject:prov];
			[byID removeObjectForKey:identifier];
		}
	}
	NSArray *remainingKeys = [byID allKeys];
//	NSLog(@"remaining keys: %@", remainingKeys);
	if ([remainingKeys count] > 0) {
		NSEnumerator *remainingEnumerator = [remainingKeys objectEnumerator];
		NSString *remainingKey;
		while (remainingKey = [remainingEnumerator nextObject]) {
//			NSLog(@"key: %@", remainingKey);
			NSDictionary *prov = [byID objectForKey:remainingKey];
//			NSLog(@"prov: %@", prov);
			if (prov) {
				[provs addObject:prov];
			}
		} 
	}
	
//	NSLog(@"provs: %@", provs);
	
	return [provs autorelease];	
	
}

- (IBAction)useSpecificSetupChanged:(id)sender {
	BOOL canEdit = YES;
	id useSpecificSetup = [[engineController selection] valueForKey:@"searchHelpUseSpecificSetup"];
	if (useSpecificSetup == nil || [(NSNumber *)useSpecificSetup boolValue] == NO) {
		canEdit = NO;
	}
	
//	NSLog(@"use specific setup changed: %d", canEdit);
	
	[engineSpecificSearchHelperController setCanDrag:canEdit];
	[[engineSpecificSearchHelpersTable tableColumnWithIdentifier:@"enabled"] setEditable:canEdit];
	
	[self willChangeValueForKey:@"engineSpecificSearchHelpProviders"];
	engineSpecificSearchHelpers = [[self constructSearchHelpersForEngine:[engineController selection]] retain];
	[self didChangeValueForKey:@"engineSpecificSearchHelpProviders"];
}

- (NSMutableArray *)constructSearchHelpersForEngine:(id)engine {

	id useSpecificSetup = [engine valueForKey:@"searchHelpUseSpecificSetup"];
//	NSLog(@"construct search helpers for engines; use specific setup = %@", useSpecificSetup);
	if (useSpecificSetup == nil || [(NSNumber *)useSpecificSetup boolValue] == NO) {
		return [self constructSearchHelpers];
	}
	
	NSDictionary *providers = [MonocleSuggestionProvider providers];
	
	//	NSLog(@"providers: %@", providers);

	NSArray *defaultOrder = [MonoclePreferences arrayForKey:@"SearchHelpProvidersOrder" orDefault:[MonocleSuggestionProvider providerIdentifiers]];
	NSArray *defaultProviders = [MonoclePreferences arrayForKey:@"SearchHelpProvidersEnabled" orDefault:[MonocleSuggestionProvider providerIdentifiers]];
	
	NSArray *orderFromEngine = [engine valueForKey:@"searchHelpProvidersOrder"];
	NSArray *order = (orderFromEngine == nil ? defaultOrder : orderFromEngine);
	NSArray *enabledProvidersFromEngine = [engine valueForKey:@"searchHelpProvidersEnabled"];
	NSArray *enabledProviders = (enabledProvidersFromEngine == nil ? defaultProviders : enabledProvidersFromEngine);
	
	NSMutableDictionary *byID = [NSMutableDictionary dictionary];
	
	NSEnumerator *rEnumerator = [[providers objectForKey:@"r"] objectEnumerator];
	id<MonocleResultProviding> rs;
	NSDictionary *dict;
	NSMutableArray *provs = [[NSMutableArray array] retain];
	while (rs = [rEnumerator nextObject]) {
		MonocleProviderInfo info = [rs resultsProviderInfo];
		NSString *identifier = [rs resultsSourceIdentifier];
		dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
				info.icon, @"icon",
				info.label, @"name",
				[NSNumber numberWithBool:[enabledProviders containsObject:identifier]], @"isChecked",
				[rs resultsSource], @"source", 
				identifier, @"identifier", 
				nil];
		[byID setObject:dict forKey:identifier];
		//		NSLog(@"added results entry for %@, %@", identifier, dict);
		//		[provs addObject:dict];
	} 
	
	NSEnumerator *sEnumerator = [[providers objectForKey:@"s"] objectEnumerator];
	id<MonocleSuggestionProviding> ss;
	while (ss = [sEnumerator nextObject]) {
		MonocleProviderInfo info = [ss suggestionsProviderInfo];
		NSString *identifier = [ss suggestionsSourceIdentifier];
		dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
				info.icon, @"icon",
				info.label, @"name",
				[NSNumber numberWithBool:[enabledProviders containsObject:identifier]], @"isChecked",
				[ss suggestionsSource], @"source",
				identifier, @"identifier", 
				nil];
		[byID setObject:dict forKey:identifier];
		//		[provs addObject:dict];
	} 
	
	NSEnumerator *inOrderEnumerator = [order objectEnumerator];
	NSString *identifier;
	while (identifier = [inOrderEnumerator nextObject]) {
		NSDictionary *prov = [byID objectForKey:identifier];
		if (prov) {
			[provs addObject:prov];
			[byID removeObjectForKey:identifier];
		}
	}
	NSArray *remainingKeys = [byID allKeys];
	//	NSLog(@"remaining keys: %@", remainingKeys);
	if ([remainingKeys count] > 0) {
		NSEnumerator *remainingEnumerator = [remainingKeys objectEnumerator];
		NSString *remainingKey;
		while (remainingKey = [remainingEnumerator nextObject]) {
			//			NSLog(@"key: %@", remainingKey);
			NSDictionary *prov = [byID objectForKey:remainingKey];
			//			NSLog(@"prov: %@", prov);
			if (prov) {
				[provs addObject:prov];
			}
		} 
	}
	
	//	NSLog(@"provs: %@", provs);
	
	return [provs autorelease];	
	
}

- (NSMutableArray *)searchHelpProviders {
//	NSLog(@"SEARCH HELP PROVIDERS CALLED, returning %@", searchHelpers);
	return searchHelpers;
}

- (NSMutableArray *)engineSpecificSearchHelpProviders {
	return engineSpecificSearchHelpers;
}

- (void)setSearchHelpProviders:(NSArray *)provs {
//	NSLog(@"set search help providers: %@", provs);
	
	searchHelpers = [provs mutableCopy];
	
	NSMutableArray *ordered = [NSMutableArray array];
	NSMutableArray *enabled = [NSMutableArray array];
	
	NSEnumerator *provEnumerator = [provs objectEnumerator];
	NSDictionary *prov;
	while (prov = [provEnumerator nextObject]) {
		NSString *identifier = [prov objectForKey:@"identifier"];
		if ([ordered containsObject:identifier]) continue;
		[ordered addObject:identifier];
		NSNumber *isEnabled = [prov objectForKey:@"isChecked"];
		if ([isEnabled boolValue])
			[enabled addObject:identifier];
	}
//	NSLog(@"ordered: %@", ordered);
//	NSLog(@"enabled: %@", enabled);
//	NSLog(@"---");
	
	[MonoclePreferences setPreference:ordered forKey:@"SearchHelpProvidersOrder"];
	[MonoclePreferences setPreference:enabled forKey:@"SearchHelpProvidersEnabled"];
}

- (void)setEngineSpecificSearchHelpProviders:(NSArray *)provs {
//	NSLog(@"set engine specific search help providers: %@", provs);
	
	engineSpecificSearchHelpers = [provs mutableCopy];
	
	NSMutableArray *ordered = [NSMutableArray array];
	NSMutableArray *enabled = [NSMutableArray array];
	
	NSEnumerator *provEnumerator = [provs objectEnumerator];
	NSDictionary *prov;
	while (prov = [provEnumerator nextObject]) {
		NSString *identifier = [prov objectForKey:@"identifier"];
		if ([ordered containsObject:identifier]) continue;
		[ordered addObject:identifier];
		NSNumber *isEnabled = [prov objectForKey:@"isChecked"];
		if ([isEnabled boolValue])
			[enabled addObject:identifier];
	}
//	NSLog(@"ordered: %@", ordered);
//	NSLog(@"enabled: %@", enabled);
//	NSLog(@"---");
	
	[engineController setValue:ordered forKeyPath:@"selection.searchHelpProvidersOrder"];
	[engineController setValue:enabled forKeyPath:@"selection.searchHelpProvidersEnabled"];
}

- (void)setSearchHelpProvidersManually:(NSArrayController *)lineup {
//	NSLog(@"content: %@", [searchHelperController content]);
//	NSLog(@"arrangedObjects: %@", [searchHelperController arrangedObjects]);
	if (lineup == searchHelperController) {
		[self setSearchHelpProviders:[searchHelperController content]];
	} else if (lineup == engineSpecificSearchHelperController) {
		[self setEngineSpecificSearchHelpProviders:[engineSpecificSearchHelperController content]];
	}
}


- (IBAction)showHelp:(id)sender {
//	NSLog(@"show help!");
}

@end
