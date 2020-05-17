//
//  MonocleEngineArrayController.m
//  Monocle
//
//  Created by Jesper on 2006-07-30.
//  Copyright 2006 waffle software. All rights reserved.
//

#import "MonocleReorderableArrayController.h"
#import "MonocleEngineArrayController.h"

@implementation MonocleEngineArrayController

- (void)sharedInit {
  [self addObserver:self
         forKeyPath:@"selection"
            options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
            context:NULL];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
  if ([keyPath isEqualToString:@"selection"] && object == self) {
    //		NSLog(@"selection changed");
    id newSel = [change objectForKey:NSKeyValueChangeNewKey];
    id oldSel = [change objectForKey:NSKeyValueChangeOldKey];
    [newSel addObserver:self forKeyPath:@"color" options:0 context:NULL];
    [newSel addObserver:self forKeyPath:@"colorSpecified" options:0 context:NULL];
    [newSel addObserver:self forKeyPath:@"icon" options:0 context:NULL];
    [oldSel removeObserver:self forKeyPath:@"color"];
    [oldSel removeObserver:self forKeyPath:@"colorSpecified"];
    [oldSel removeObserver:self forKeyPath:@"icon"];
  } else if ([keyPath isEqualToString:@"color"] || [keyPath isEqualToString:@"icon"] ||
    [keyPath isEqualToString:@"colorSpecified"]) {
    //		NSLog(@"%@ changed for selection", keyPath);
    [self willChange:NSKeyValueChangeSetting valuesAtIndexes:[self selectionIndexes] forKey:@"arrangedObjects"];
    [self didChange:NSKeyValueChangeSetting valuesAtIndexes:[self selectionIndexes] forKey:@"arrangedObjects"];
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
  } else {
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
  }
}

- (id)initWithContent:(id)content {
  self = [super initWithContent:content];
  if (self != nil) {
    //		NSLog(@"inited with content");
    [self sharedInit];
  }
  return self;
}

- (id)initWithCoder:(NSCoder *)c {
  self = [super initWithCoder:c];
  if (self != nil) {
    //		NSLog(@"inited with coder");
    [self sharedInit];
  }
  return self;
}

- (void)addObject:(id)object {
  //	NSLog(@"asked to add object: %@, class: %@", object, [object className]);
  id name = [object objectForKey:@"name"];
  if (!name || [name isEqualToString:@""]) {
    NSMutableDictionary *d = [object mutableCopy];
    [d setObject:@"New engine" forKey:@"name"];
    [d setObject:@"GET" forKey:@"type"];
    [super addObject:[d autorelease]];
  } else {
    [super addObject:object];
  }
}

- (void)remove:(id)sender {
  //	NSLog(@"asked to remove selected object. sender: %@, selection: %@", sender, [self valueForKey:@"selection"]);
  [super remove:sender];
}

- (BOOL)canRemove {
  if ((![self arrangedObjects]) || ([[self arrangedObjects] count] < 2)) return NO;
  return [super canRemove];
}

/*
- (BOOL)tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes
toPasteboard:(NSPasteboard*)pboard {
  // declare our own pasteboard types
    NSArray *typesArray = [NSArray arrayWithObject:@"MonocleIntrisicTableEngineType"];

  [pboard declareTypes:typesArray owner:self];

  NSValueTransformer *trf = [NSValueTransformer valueTransformerForName:NSUnarchiveFromDataTransformerName];

    // Stick index set in directly (encoded as NSData)
    [pboard setPropertyList:[trf reverseTransformedValue:rowIndexes] forType:@"MonocleIntrisicTableEngineType"];

    return YES;
}


- (NSDragOperation)tableView:(NSTableView*)tv
        validateDrop:(id <NSDraggingInfo>)info
         proposedRow:(int)row
     proposedDropOperation:(NSTableViewDropOperation)op
{

    // we want to put the object at, not over,
    // the current row (contrast NSTableViewDropOn)
    [tv setDropRow:row dropOperation:NSTableViewDropAbove];

    return NSDragOperationMove;
}



- (BOOL)tableView:(NSTableView*)tv
     acceptDrop:(id <NSDraggingInfo>)info
        row:(int)row
  dropOperation:(NSTableViewDropOperation)op
{
    if (row < 0) {
    row = 0;
  }

    if ([[[info draggingPasteboard] types] containsObject:@"MonocleIntrisicTableEngineType"]) {

    NSValueTransformer *trf = [NSValueTransformer valueTransformerForName:NSUnarchiveFromDataTransformerName];
    // Grab index set directly (encoded as NSData)
    NSIndexSet *indexSet = [trf transformedValue:[[info draggingPasteboard]
propertyListForType:@"MonocleIntrisicTableEngineType"]];

    [self moveObjectsInArrangedObjectsFromIndexes:indexSet toIndex:row];

    // set selected rows to those that were just moved
    // Need to work out what moved where to determine proper selection...
    int rowsAbove = [self rowsAboveRow:row inIndexSet:indexSet];

    NSRange range = NSMakeRange(row - rowsAbove, [indexSet count]);
    indexSet = [NSIndexSet indexSetWithIndexesInRange:range];
    [self setSelectionIndexes:indexSet];

    [postDragDelegate performSelector:@selector(engineLineupDidReorder)];

    return YES;
    }

    return NO;
}

- (void)setPostDragDelegate:(id)del {
  postDragDelegate = del;
}

-(void) moveObjectsInArrangedObjectsFromIndexes:(NSIndexSet*)indexSet
                    toIndex:(unsigned int)insertIndex
{

    NSArray		*objects = [self arrangedObjects];
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
    object = [objects objectAtIndex:removeIndex];
    [self removeObjectAtArrangedObjectIndex:removeIndex];
    [self insertObject:object atArrangedObjectIndex:insertIndex];

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
}*/

@end
