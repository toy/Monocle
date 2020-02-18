//
//  NSEventMonocleExtensions.m
//  Monocle
//
//  Created by Jesper on 2006-07-30.
//  Copyright 2006 waffle software. All rights reserved.
//

#import "NSEventMonocleExtensions.h"

@implementation NSEvent (NSEventMonocleExtensions)

- (BOOL)isFunctionKeyPress {

	unichar sh = [[self charactersIgnoringModifiers] characterAtIndex:0];
	switch (sh) {
	
		case NSUpArrowFunctionKey:
		case NSDownArrowFunctionKey:
		case NSLeftArrowFunctionKey:
		case NSRightArrowFunctionKey:
		case NSF1FunctionKey:
		case NSF2FunctionKey:
		case NSF3FunctionKey:
		case NSF4FunctionKey:
		case NSF5FunctionKey:
		case NSF6FunctionKey:
		case NSF7FunctionKey:
		case NSF8FunctionKey:
		case NSF9FunctionKey:
		case NSF10FunctionKey:
		case NSF11FunctionKey:
		case NSF12FunctionKey:
		case NSF13FunctionKey:
		case NSF14FunctionKey:
		case NSF15FunctionKey:
		case NSF16FunctionKey:
		case NSF17FunctionKey:
		case NSF18FunctionKey:
		case NSF19FunctionKey:
		case NSF20FunctionKey:
		case NSF21FunctionKey:
		case NSF22FunctionKey:
		case NSF23FunctionKey:
		case NSF24FunctionKey:
		case NSF25FunctionKey:
		case NSF26FunctionKey:
		case NSF27FunctionKey:
		case NSF28FunctionKey:
		case NSF29FunctionKey:
		case NSF30FunctionKey:
		case NSF31FunctionKey:
		case NSF32FunctionKey:
		case NSF33FunctionKey:
		case NSF34FunctionKey:
		case NSF35FunctionKey:
		case NSInsertFunctionKey:
		case NSDeleteFunctionKey:
		case NSHomeFunctionKey:
		case NSBeginFunctionKey:
		case NSEndFunctionKey:
		case NSPageUpFunctionKey:
		case NSPageDownFunctionKey:
		case NSPrintScreenFunctionKey:
		case NSScrollLockFunctionKey:
		case NSPauseFunctionKey:
		case NSSysReqFunctionKey:
		case NSBreakFunctionKey:
		case NSResetFunctionKey:
		case NSStopFunctionKey:
		case NSMenuFunctionKey:
		case NSUserFunctionKey:
		case NSSystemFunctionKey:
		case NSPrintFunctionKey:
		case NSClearLineFunctionKey:
		case NSClearDisplayFunctionKey:
		case NSInsertLineFunctionKey:
		case NSDeleteLineFunctionKey:
		case NSInsertCharFunctionKey:
		case NSDeleteCharFunctionKey:
		case NSPrevFunctionKey:
		case NSNextFunctionKey:
		case NSSelectFunctionKey:
		case NSExecuteFunctionKey:
		case NSUndoFunctionKey:
		case NSRedoFunctionKey:
		case NSFindFunctionKey:
		case NSHelpFunctionKey:
		case NSModeSwitchFunctionKey:
			return YES;
		
	}
	return NO;
	
}

@end
