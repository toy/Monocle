//
//  MonocleReorderableArrayController.h
//  Monocle
//
//  Created by Jesper on 2007-06-09.
//  Copyright 2007 waffle software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/** Drag and drop stuff below, almost completely courtesy of mmalc. Less than three, mmalc. Less than three.
*** http://homepage.mac.com/mmalc/CocoaExamples/controllers.html **/

@interface MonocleReorderableArrayController : NSArrayController {
  id postDragDelegate;
  BOOL cantSelectRow;
  BOOL draggingTemporarilyDisabled;
}
- (void)setCanSelectRow:(BOOL)can;
- (void)setCanDrag:(BOOL)can;
- (BOOL)canDrag;

- (void)registerTableViewToReceiveDrags:(NSTableView *)tv;

- (void)setPostDragDelegate:(id)del;
- (void)moveObjectsInArrangedObjectsFromIndexes:(NSIndexSet *)indexSet toIndex:(NSUInteger)insertIndex;
- (int)rowsAboveRow:(int)row inIndexSet:(NSIndexSet *)indexSet;
@end
