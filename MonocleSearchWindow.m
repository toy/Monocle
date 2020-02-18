//
//  MonocleSearchWindow.m
//  Monocle
//
//  Created by Jesper on 2006-06-17.
//  Copyright 2006 waffle software. All rights reserved.
//

#import "MonocleSearchWindow.h"
#import "NSEventMonocleExtensions.h"
#import "MonocleSearchView.h"

#import "MonoclePreferences.h"

@implementation MonocleSearchWindow
- (BOOL)canBecomeMainWindow {
	return YES;
}

- (BOOL)canBecomeKeyWindow {
	return YES;
}

- (BOOL)hasShadow {
	return NO;
}

- (BOOL)isOpaque {
	return NO;
}

- (void)sendEvent:(NSEvent *)event {
	/*
	if (([event type] == NSFlagsChanged)) {
		if (([event modifierFlags] & NSControlKeyMask)) {
			if ((!showingAccordion)) {
				[(MonocleSearchView *)[self contentView] showNextPrev];
				showingAccordion = YES;
			}
		} else {
			if (showingAccordion) {
				[(MonocleSearchView *)[self contentView] hideNextPrev];
				showingAccordion = NO;
			}
		}
	}*/
	
//	if (([event type] != NSKeyDown) && ([event type] != NSFlagsChanged))
	if ([event type] != NSKeyDown)
		return [super sendEvent: event];
	
	NSString *charactersIgnoringModifiers = [event charactersIgnoringModifiers];
	if ([charactersIgnoringModifiers length] == 0) return [super sendEvent:event]; // don't swallow dead keys
	
	unichar c = [charactersIgnoringModifiers characterAtIndex:0];
	unsigned short kc = [event keyCode];

//	NSLog(@"key press.. key code: %hu, key character: -- %@ --", kc, [event characters]);
	
	MonocleSearchView *searchView = [self contentView];
	
#define		MonocleEscapeKeyCode	53
#define		MonocleReturnCharCode	13
	if (kc == MonocleEscapeKeyCode) {
		if ([[searchView searchText] isEqualToString:@""])
			[searchView hide];
	}
	/*
	if ((kc == 76) || (kc == 36) || [[event characters] hasPrefix:@"\n"] ||  [[event characters] hasPrefix:@"\r"]) {
		NSLog(@"key press is considered return/enter");
		[searchView performSearch];
		return;
	}*/
	
	BOOL isOpt = (([event modifierFlags] & NSAlternateKeyMask) == NSAlternateKeyMask);
	if (isOpt) {
//		NSLog(@"is opt");
		if ((c == NSUpArrowFunctionKey)) {
//			NSLog(@"move search help up");
			[searchView moveSearchHelpSelectionUp];
			return;
		}
		if ((c == NSDownArrowFunctionKey)) {
//			NSLog(@"move search help down");
			[searchView moveSearchHelpSelectionDown];
			return;
		}
		if ((c == NSRightArrowFunctionKey)) {
//			NSLog(@"fill in search help");
			if ([searchView fillInSearchHelp])
				return;
		}
	}
	
	BOOL enterMeansSearch = [MonoclePreferences boolForKey:@"searchTakesPriority" orDefault:NO];
	
	BOOL isCmd = (([event modifierFlags] & NSCommandKeyMask) == NSCommandKeyMask);
	BOOL isCmdArrow = [MonoclePreferences boolForKey:@"arrowsNeedCommand" orDefault:NO];
//	NSLog(@"key code: %d, c: %d", [event keyCode], c);
	if (isCmd == isCmdArrow) {
		if ((c == NSUpArrowFunctionKey)) {
	//		NSLog(@"move up");
			if ([event modifierFlags] & NSControlKeyMask)
				[searchView popUpEnginesAtTopOrBottom:YES];
			else
				[searchView upArrowKey];
			return;
		}
		if ((c == NSDownArrowFunctionKey)) {
	//		NSLog(@"move down");
			if ([event modifierFlags] & NSControlKeyMask)
				[searchView popUpEnginesAtTopOrBottom:NO];
			else
				[searchView downArrowKey];
			return;
		}
		if ((c == MonocleReturnCharCode)) {
//			NSLog(@"IS ENTER");
			if ([searchView showsSearchHelp]) {
//				NSLog(@"SHOWS SEARCH HELP, enter means search? %d, is alt? %d", enterMeansSearch, isOpt);
				if (![searchView hasNonEmptySearchHelpSelected]) {
					[searchView performSearch];
					return;
				}
				if (enterMeansSearch == isOpt) {
//					NSLog(@"FILLING IN SEARCH HELP");
					[searchView fillInSearchHelp];
					return;
				} else {
					if (!enterMeansSearch && isOpt) {
//						NSLog(@"search!");
						[searchView performSearch];
						return;
					}
				}
			}
		}
/*		if ((c == NSRightArrowFunctionKey)) {
			if ([searchView rightArrowKey])
				return;
		}*/
	}
		
	return [super sendEvent:event];
}

- (void)keyDown:(NSEvent *)theEvent {
	NSLog(@"key down (SW): %@", theEvent);
	
	[super keyDown:theEvent];
}
@end
