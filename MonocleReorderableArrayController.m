//
//  MonocleReorderableArrayController.m
//  Monocle
//
//  Created by Jesper on 2007-06-09.
//  Copyright 2007 waffle software. All rights reserved.
//

#import "MonocleReorderableArrayController.h"

/** Drag and drop stuff below, almost completely courtesy of mmalc. Less than three, mmalc. Less than three.
*** http://homepage.mac.com/mmalc/CocoaExamples/controllers.html **/

@implementation MonocleReorderableArrayController

static NSString *dragTypeName = @"MonocleIntrisicTableReorderableType%d";
#define MonocleReorderableArrayControllerDragTypeName	[NSString stringWithFormat:dragTypeName, [self hash]]

- (BOOL)selectionShouldChangeInTableView:(NSTableView *)aTableView {
//	NSLog(@"selection should change, returning %@", (!(cantSelectRow) ? @"YES" : @"NO"));
	
	if (postDragDelegate != nil && [postDragDelegate respondsToSelector:@selector(draggingStopped)])
		[postDragDelegate performSelector:@selector(draggingStopped)];
	
	return YES;//!(cantSelectRow);	
}

#ifndef NSINTEGER_DEFINED
#if __LP64__ || NS_BUILD_32_LIKE_64
typedef long NSInteger;
typedef unsigned long NSUInteger;
#else
typedef int NSInteger;
typedef unsigned int NSUInteger;
#endif
#define NSINTEGER_DEFINED 1
#define NOTCOMPILEDONLEOPARD 1
#endif

- (BOOL)tableView:(NSTableView *)tableView shouldTrackCell:(NSCell *)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	if (!cantSelectRow)  return YES;
	if ([cell isKindOfClass:[NSButtonCell class]]) {
		return YES;
	} else {
		return NO;
	}
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(int)rowIndex {
//	NSLog(@"should select row %d, returning %@", rowIndex, (!(cantSelectRow) ? @"YES" : @"NO"));
//	return !(cantSelectRow);
	return YES;
}

- (void)setCanSelectRow:(BOOL)can {
	cantSelectRow = !can;
}

- (void)setCanDrag:(BOOL)can {
	draggingTemporarilyDisabled = !can;
}

- (BOOL)canDrag {
	return !draggingTemporarilyDisabled;
}

- (BOOL)tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard {
	if (draggingTemporarilyDisabled) return NO;
	// declare our own pasteboard types
    NSArray *typesArray = [NSArray arrayWithObject:MonocleReorderableArrayControllerDragTypeName];
	
	[pboard declareTypes:typesArray owner:self];
	
	NSValueTransformer *trf = [NSValueTransformer valueTransformerForName:NSUnarchiveFromDataTransformerName];
	
    // Stick index set in directly (encoded as NSData)
    [pboard setPropertyList:[trf reverseTransformedValue:rowIndexes] forType:MonocleReorderableArrayControllerDragTypeName];
	
    return YES;
}


- (NSDragOperation)tableView:(NSTableView*)tv
				validateDrop:(id <NSDraggingInfo>)info
				 proposedRow:(int)row
	   proposedDropOperation:(NSTableViewDropOperation)op
{
	if (draggingTemporarilyDisabled) return NSDragOperationNone;
	
//	NSLog(@"validate drop");
	
    // we want to put the object at, not over,
    // the current row (contrast NSTableViewDropOn) 
    [tv setDropRow:row dropOperation:NSTableViewDropAbove];
	
    return NSDragOperationMove;
}

- (void)registerTableViewToReceiveDrags:(NSTableView *)tv {
//	NSLog(@"register to receive drags for %@, %@", tv, MonocleReorderableArrayControllerDragTypeName);
    [tv registerForDraggedTypes:[NSArray arrayWithObject:MonocleReorderableArrayControllerDragTypeName]];	
	if ([tv respondsToSelector:@selector(setReorderableController:)]) {
		[tv performSelector:@selector(setReorderableController:) withObject:self];
	}
}

- (BOOL)tableView:(NSTableView*)tv
	   acceptDrop:(id <NSDraggingInfo>)info
			  row:(int)row
	dropOperation:(NSTableViewDropOperation)op
{
	if (draggingTemporarilyDisabled) return NO;
	
    if (row < 0) {
		row = 0;
	}
    
    if ([[[info draggingPasteboard] types] containsObject:MonocleReorderableArrayControllerDragTypeName]) {
		
		NSValueTransformer *trf = [NSValueTransformer valueTransformerForName:NSUnarchiveFromDataTransformerName];
		// Grab index set directly (encoded as NSData)
		NSIndexSet *indexSet = [trf transformedValue:[[info draggingPasteboard] propertyListForType:MonocleReorderableArrayControllerDragTypeName]];
		
		[self moveObjectsInArrangedObjectsFromIndexes:indexSet toIndex:row];
		
		// set selected rows to those that were just moved
		// Need to work out what moved where to determine proper selection...
		if (!cantSelectRow) {
			int rowsAbove = [self rowsAboveRow:row inIndexSet:indexSet];
		
			NSRange range = NSMakeRange(row - rowsAbove, [indexSet count]);
			indexSet = [NSIndexSet indexSetWithIndexesInRange:range];

			[self setSelectionIndexes:indexSet];
		} else {
			[self setSelectionIndexes:[NSIndexSet indexSet]];
		}
		
		[postDragDelegate performSelector:@selector(reorderableLineupDidReorder:) withObject:self];
		
		return YES;
    }
	
//	[postDragDelegate performSelector:@selector(draggingStopped:) withObject:self];
	
    return NO;
}

- (void)setPostDragDelegate:(id)del {
	postDragDelegate = del;
}

-(void) moveObjectsInArrangedObjectsFromIndexes:(NSIndexSet*)indexSet
										toIndex:(unsigned int)insertIndex
{
	
    NSArray		*objects = [self arrangedObjects];//[[self arrangedObjects] mutableCopy];
	int			index = [indexSet lastIndex];
	
    int			aboveInsertIndexCount = 0;
    id			object;
    int			removeIndex;
	
    while (NSNotFound != index) {
		if (index >= insertIndex) {
			removeIndex = index + aboveInsertIndexCount;
			aboveInsertIndexCount += 1;
		}
		else {
			removeIndex = index;
			insertIndex -= 1;
		}
		object = [[objects objectAtIndex:removeIndex] retain];
		
//		NSLog(@"moving %@", object);
//		NSLog(@"before: %@", [self arrangedObjects]);
//		[objects removeObjectAtIndex:removeIndex];
		[self removeObjectAtArrangedObjectIndex:removeIndex];
//		NSLog(@"after removing object at index %i: %@", removeIndex, [self arrangedObjects]);
//		[objects insertObject:object atIndex:insertIndex];
		[self insertObject:object atArrangedObjectIndex:insertIndex];
//		NSLog(@"after inserting object at index %i: %@", insertIndex, [self arrangedObjects]);
		[object release];
		
		index = [indexSet indexLessThanIndex:index];
    }
}

- (int)rowsAboveRow:(int)row inIndexSet:(NSIndexSet *)indexSet
{
    unsigned currentIndex = [indexSet firstIndex];
    int i = 0;
    while (currentIndex != NSNotFound) {
		if (currentIndex < row) { i++; }
		currentIndex = [indexSet indexGreaterThanIndex:currentIndex];
    }
    return i;
}
@end
