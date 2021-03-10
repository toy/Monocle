//
//  MonocleSearchView.m
//  Monocle
//
//  Created by Jesper on 2006-06-17.
//  Copyright 2006 waffle software. All rights reserved.
//

#import "MonocleSearchView.h"
#import "MonocleSearchField.h"
#import "MonocleController.h"
#import "MonocleSuggestionProviding.h"
#import "MonocleWashDrawing.h"
#import "MonoclePreferences.h"

#import "CocoaAdditions.h"

#import "NSDictionary+BSJSONAdditions.h"
#import "NSColor+ContrastingLabelExtensions.h"

#import "DrawingExtras.h"
#import "CTGradient.h"

static NSString *MonocleSearchHelpDataUpdated = @"MonocleSearchHelpDataUpdated";

@interface WebView (SetDrawsBackgroundWorkaround)
- (void)setDrawsBackground:(BOOL)draws;
@end

@interface MonocleSearchPopUpButtonCell : NSPopUpButtonCell
@end

@implementation MonocleSearchPopUpButtonCell : NSPopUpButtonCell
- (void)drawTitleWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
  //	NSLog(@"drawTitleWithFrame");
  [super drawTitleWithFrame:cellFrame inView:controlView];
}

- (void)drawStateImageWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
  //	NSLog(@"drawStateImageWithFrame");
  [super drawStateImageWithFrame:cellFrame inView:controlView];
}

- (void)drawImageWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
  //	NSLog(@"drawImageWithFrame");
  [super drawImageWithFrame:cellFrame inView:controlView];
}

- (void)drawBorderAndBackgroundWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
  //	NSLog(@"drawBorderAndBackgroundWithFrame");
  [super drawBorderAndBackgroundWithFrame:cellFrame inView:controlView];
}

- (void)drawBezelWithFrame:(NSRect)frame inView:(NSView *)controlView {
  //	NSLog(@"drawBezelWithFrame");
  [super drawBezelWithFrame:frame inView:controlView];
}

- (void)drawImage:(NSImage *)image withFrame:(NSRect)frame inView:(NSView *)controlView {
  //	NSLog(@"drawImage");
  [super drawImage:image withFrame:frame inView:controlView];
}

- (NSRect)drawTitle:(NSAttributedString *)title withFrame:(NSRect)frame inView:(NSView *)controlView {
  //	NSLog(@"drawTitle");
  return [super drawTitle:title withFrame:frame inView:controlView];
}
@end

@interface MonocleSearchPopUpButton : NSPopUpButton
@end

@implementation MonocleSearchPopUpButton : NSPopUpButton
+ (Class)cellClass {
  return [MonocleSearchPopUpButtonCell class];
}
@end

#define MonocleDPIQuantifier ([[NSScreen mainScreen] userSpaceScaleFactor])
#define MonocleSearchViewFlanksWidth 16.0
#define MonocleSearchViewFlanksPadding 3.0
#define MonocleSearchViewBaseHeight 36.0

#define MonocleDPIDoScaling 0

#if (MonocleDPIDoScaling == 1)

#define MonocleDPIzeRect(x, y) [self rectByScalingRect:(x) toResolutionForScreen:(y)]
#define MonocleDPIzeRectD(x) [self rectByScalingRect:(x) toResolutionForScreen:[NSScreen mainScreen]]

#define MonocleDPIzePoint(x, y) [self pointByScalingPoint:(x) toResolutionForScreen:(y)]
#define MonocleDPIzePointD(x) [self pointByScalingPoint:(x) toResolutionForScreen:[NSScreen mainScreen]]

#define MonocleDPIzeSize(x, y) [self sizeByScalingSize:(x) toResolutionForScreen:(y)]
#define MonocleDPIzeSizeD(x) [self sizeByScalingSize:(x) toResolutionForScreen:[NSScreen mainScreen]]

#define MonocleDPIzeFloat(x, y) [self floatByScalingFloat:(x) toResolutionForScreen:(y)]
#define MonocleDPIzeFloatD(x) [self floatByScalingFloat:(x) toResolutionForScreen:[NSScreen mainScreen]]

#else

#define MonocleDPIPassthruOne(x, y) (x)
#define MonocleDPIPassthruTwo(x) (x)

#define MonocleDPIzeRect(x, y) MonocleDPIPassthruOne(x, y)
#define MonocleDPIzeSize(x, y) MonocleDPIPassthruOne(x, y)
#define MonocleDPIzePoint(x, y) MonocleDPIPassthruOne(x, y)
#define MonocleDPIzeFloat(x, y) MonocleDPIPassthruOne(x, y)

#define MonocleDPIzeRectD(x) MonocleDPIPassthruTwo(x)
#define MonocleDPIzeSizeD(x) MonocleDPIPassthruTwo(x)
#define MonocleDPIzePointD(x) MonocleDPIPassthruTwo(x)
#define MonocleDPIzeFloatD(x) MonocleDPIPassthruTwo(x)

#endif

@implementation MonocleSearchView

- (id)initWithFrame:(NSRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    engineIndex = 0;

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

    [nc addObserver:self selector:@selector(refreshView:) name:@"SearchBarStyleChanged" object:nil];

    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
                                                              forKeyPath:@"values.SearchBarHasSheen"
                                                                 options:NSKeyValueObservingOptionNew
                                                                 context:@"SearchBar"];
  }
  return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
  id ctxobject = (id)context;
  if ([ctxobject isEqualToString:@"SearchBar"])
    [self setNeedsDisplay:YES];
  else if ([ctxobject isEqualToString:@"selectedEngine"]) {
    [self whenSelectedEngineChanges];
    [self setNeedsDisplay:YES];
  } else if ([ctxobject isEqualToString:@"allEngines"])
    [self dirtyCallwordCache];
  else
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)refreshView:(NSNotification *)noti {
  //	NSLog(@"refresh view");
  [self display];
}

// static NSTimer *searchhelptimer = nil;
// static NSArray *searchhelpResults = nil;
// static NSArray *searchhelpSuggestions = nil;
static NSObject *searchhelpHandle = nil;
static NSObject *searchhelpUpdatingHandle = nil;

- (void)awakeFromNib {
  currentSearchhelpJob = 0;

  draftSearchhelpResults = [[NSMutableDictionary alloc] init];

  anySearchHelp = NO;

  [selectedEngine bind:@"contentObject"
              toObject:self
           withKeyPath:@"selectedEngine"
               options:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES],
                                     NSConditionallySetsEditableBindingOption,
                                     [NSNumber numberWithBool:YES],
                                     NSRaisesForNotApplicableKeysBindingOption,
                                     nil]];

  currentSearchhelpIsForString = @"";

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(updateSearchHelpDisplayInfo:)
                                               name:MonocleSearchHelpDataUpdated
                                             object:nil];

  NSRect webframe = [searchHelpWebView frame];
  borderlessSearchHelpWindow =
    [[NSWindow alloc] initWithContentRect:NSMakeRect(-5000, -5000, NSWidth(webframe), NSHeight(webframe))
                                styleMask:NSBorderlessWindowMask
                                  backing:NSBackingStoreBuffered
                                    defer:NO];
  [borderlessSearchHelpWindow setLevel:NSTornOffMenuWindowLevel];
  NSView *contentView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, NSWidth(webframe), NSHeight(webframe))];
  [contentView addSubview:searchHelpWebView];
  [borderlessSearchHelpWindow setContentView:[contentView autorelease]];
  [borderlessSearchHelpWindow setBackgroundColor:[NSColor clearColor]];
  [borderlessSearchHelpWindow setOpaque:NO];
  [borderlessSearchHelpWindow setHasShadow:YES];
  [borderlessSearchHelpWindow orderFront:self];
  [searchHelpWebView setFrameOrigin:NSMakePoint(0, 0)];
  [searchHelpWebView setFrameSize:NSMakeSize(NSWidth(webframe), NSHeight(webframe))];
  [borderlessSearchHelpWindow setAlphaValue:0];

  [[[searchHelpWebView mainFrame] frameView] setAllowsScrolling:NO];

  [[searchHelpWebView mainFrame]
    loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[NSBundle bundleForClass:[self class]]
                                                                      pathForResource:@"results"
                                                                               ofType:@"html"]]]];
  [searchHelpWebView setDrawsBackground:NO];

  displaySearchhelp = [[NSArray array] retain];
  /*[searchHelpTable setIntercellSpacing:NSZeroSize];
  searchhelpTableGridColor = [[[NSColor colorForControlTint:[NSColor currentControlTint]] shadowWithLevel:0.25] retain];
  [searchHelpTable setGridColor:searchhelpTableGridColor];
  [searchHelpTable reloadData];*/

  searchhelpHandle = [[[NSObject alloc] init] retain];
  searchhelpUpdatingHandle = [[[NSObject alloc] init] retain];

  [appMenuPopup setTitle:@""];
  NSRect popupRect = [appMenuPopup frame];
  double popupRectAdjustment = 17;
  popupRect.size.width -= popupRectAdjustment;
  popupRect.origin.x += popupRectAdjustment;
  [appMenuPopup setFrame:popupRect];

  enginePopUpCell = [[MonocleSearchPopUpButtonCell alloc] initTextCell:@"" pullsDown:NO];
  [enginePopUpCell setBordered:NO];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(engineMenuPopsUp:)
                                               name:NSPopUpButtonCellWillPopUpNotification
                                             object:enginePopUpCell];

  appPopUpCell = [[MonocleSearchPopUpButtonCell alloc] initTextCell:@"" pullsDown:YES];
  [appPopUpCell setBordered:NO]; /*
  [[NSNotificationCenter defaultCenter] addObserver:self
                       selector:@selector(appMenuPopsUp:)
                         name:NSPopUpButtonCellWillPopUpNotification
                         object:appPopUpCell];*/
  [appPopUpCell setMenu:appMenu];

  [[textField cell] setSendsWholeSearchString:YES];
  [[textField cell] setSendsSearchStringImmediately:NO];
  [textField setFocusRingType:NSFocusRingTypeNone];

  [selectedEngine addObserver:self
                   forKeyPath:@"selection"
                      options:NSKeyValueObservingOptionNew
                      context:@"selectedEngine"];

  [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
                                                            forKeyPath:@"values.engines"
                                                               options:NSKeyValueObservingOptionNew
                                                               context:@"allEngines"];
}

- (void)dirtyCallwordCache {
  //	NSLog(@"dirtied callword cache");
  callwordCacheNeedsRedoing = YES;
  [self willChangeValueForKey:@"selectedEngine"];
  [self didChangeValueForKey:@"selectedEngine"];
  [self setNeedsDisplay:YES];
}

- (void)engineMenuPopsUp:(NSNotification *)noti {
  //	NSLog(@"menu pops up");

  NSMenu *menu = [[[NSMenu alloc] initWithTitle:@"Engines"] autorelease];

  NSArray *engines = [controlledEngines arrangedObjects];
  NSEnumerator *enumerator = [engines objectEnumerator];
  NSDictionary *engine;
  //	NSValueTransformer *trf = [NSValueTransformer valueTransformerForName:NSUnarchiveFromDataTransformerName];
  int idx = 0;
  while ((engine = [enumerator nextObject]) != nil) {
    if ([[engine valueForKey:@"toBeAdded"] boolValue]) {
      idx++;
      continue;
    }
    NSString *tengineName = [engine valueForKey:@"name"];
    // NSImage *tengineIcon = [trf transformedValue:[engine valueForKey:@"icon"]];
    NSImage *tengineIcon = [controller formFittedImageForEngine:engine];
    NSMenuItem *mi = [[[NSMenuItem alloc] initWithTitle:tengineName
                                                 action:@selector(changeEngineToMenuItem:)
                                          keyEquivalent:@""] autorelease];
    [mi setTarget:self];
    [mi setTag:idx];
    [mi setImage:tengineIcon];
    if (idx == engineIndex) [mi setState:NSOnState];
    [menu addItem:mi];
    idx++;
  }

  [enginePopUpCell setMenu:menu];
}

- (void)changeEngineToMenuItem:(id)sender {
  [enginePopUpCell selectItem:nil];

  //	NSLog(@"changeEngineToMenuItem: sender: %@ (%@)", sender, [sender className]);
  NSMenuItem *mi = (NSMenuItem *)sender;
  [self selectEngineWithIndex:[mi tag]];
}

- (void)bringUp {
  [[self window] makeKeyAndOrderFront:self];

  [self whenSelectedEngineChanges];
  [[[textField window] fieldEditor:YES
                         forObject:textField] setSelectedRange:NSMakeRange(0, [[textField stringValue] length])];
}

- (void)whenSelectedEngineChanges {
  //	NSLog(@"when selected engine changes");
  id engine = [self selectedEngine];
  if (!engine) return;
  NSString *name = [engine valueForKey:@"name"];

  [[textField cell] setPlaceholderString:name];
  if ([[self searchText] isNotEqualTo:@""]) {
    [self updateSearchHelp:[self searchText]];
  }
}

- (void)ready {
  [self appBecameActive];
  isSearchViewShown = YES;
  //	NSLog(@"is for string: %@", currentSearchhelpIsForString);
  [self showOrHideSearchHelp];
}

- (void)whenHiding {
  isSearchViewShown = NO;
  [self hideSearchHelp];
}

- (void)hide {
  [controller hideIfInStatusItem];
}

- (id)selectedEngine {
  NSArray *engines = [controlledEngines arrangedObjects];
  if ((!engines) || ([engines count] < 1)) return nil;
  if ([engines count] <= engineIndex) {
    engineIndex = [engines count] - 1;
  }
  id en = [engines objectAtIndex:engineIndex];
  [engineName release];
  engineName = [[en valueForKey:@"name"] copy];
  return en;
}

- (void)reselectBasedOnName {
  NSArray *engines = [controlledEngines arrangedObjects];
  NSEnumerator *engineEnumerator = [engines objectEnumerator];
  id engine;
  unsigned int i = 0;
  while (engine = [engineEnumerator nextObject]) {
    if ([[engine valueForKey:@"name"] isEqualToString:engineName]) {
      [self willChangeValueForKey:@"selectedEngine"];
      engineIndex = i;
      [self didChangeValueForKey:@"selectedEngine"];
      return;
    }
    i++;
  }
}

- (void)reorderableLineupDidReorder:(NSArrayController *)lineup {
  [self reselectBasedOnName];
}

#define MonocleSearchViewDrawingIconSize 16.0
#define MonocleSearchViewDrawingIconOffset 4.0
#define MonocleSearchViewDrawingIconPopupAreaWidth 7.0
#define MonocleSearchViewHitTestLeftCap (NSMinX([textField frame]) - (MonocleSearchViewDrawingIconOffset / 1.5))

#define MonocleSearchViewDrawingSettingsWidth 8.0
#define MonocleSearchViewDrawingSettingsOffset 6.0
#define MonocleSearchViewHitTestRightCap \
  (MonocleSearchViewDrawingSettingsWidth + MonocleSearchViewDrawingSettingsOffset) * 1.1

- (void)mouseDown:(NSEvent *)theEvent {
  NSPoint event_location = [theEvent locationInWindow];
  NSPoint local_point = [self convertPoint:event_location fromView:nil];
  NSRect leftCapHitFrame = NSMakeRect(0.0, 0.0, MonocleSearchViewHitTestLeftCap, NSHeight([self frame]));
  //	NSRect rightCapHitFrame = NSMakeRect(NSMaxX([self
  // frame])-MonocleSearchViewHitTestRightCap,0.0,MonocleSearchViewHitTestRightCap,NSHeight([self frame]));
  // NSLog(@"width of left hitFrame: %f, location: %f", MonocleSearchViewHitTestLeftCap, local_point.x); 	NSLog(@"width
  // of right hitFrame: %f, rect: %@, location: %f", MonocleSearchViewHitTestRightCap,
  // NSStringFromRect(rightCapHitFrame), local_point.x);
  if (NSPointInRect(local_point, leftCapHitFrame)) {
    [self doPopUpEngines];
    //	} else if (NSPointInRect(local_point,rightCapHitFrame)) {
    //		[self doPopUpMenu];
  } else {
    [super mouseDown:theEvent];
  }
}

- (void)doPopUpMenu {
  NSRect popUpCellFrame = NSMakeRect(NSMaxX([self frame]) - MonocleSearchViewHitTestRightCap,
    0.0,
    MonocleSearchViewHitTestRightCap,
    NSHeight([self frame]));
  [appPopUpCell performClickWithFrame:popUpCellFrame inView:self];
}

- (void)popUpEnginesAtTopOrBottom:(BOOL)atTop {
  [self selectEngineWithIndex:((atTop) ? 0 : ([[controlledEngines arrangedObjects] count] - 1))];
  [self doPopUpEngines];
}

- (void)doPopUpEngines {
  NSRect popUpCellFrame = NSMakeRect(6.0, 12.0, 26.0, 16.0);
  [enginePopUpCell performClickWithFrame:popUpCellFrame inView:self];
}

#define MONOCLE_USE_RADIUS NO

- (void)drawRect:(NSRect)rect {
  [super drawRect:rect];

  NSSize whole = [self visibleRect].size;
  NSSize asked = rect.size;
  if (asked.width < whole.width || asked.height < whole.height) {
    [self display];
    return;
  }

  double height = NSHeight(rect);

  /*
   * compute left end
   * compute mid
   * compute right end
   * compute left end color
   * compute left end's arrow color (contrasting)
   * compute right end color
   * compute right end's arrow color (contrasting)
   * compute right end's sharp shadow (contrasting color of arrow color)
   * draw mid background (MonocleWashDrawing)
   * draw right end background
   * draw left end background
   * draw left end<->mid transition groove line
   * draw left end icon
   * draw left end arrows (no shadow)
   * draw right end arrow (sharp shadow) */

  NSBezierPath *arrow = [NSBezierPath bezierPath];
  [arrow moveToPoint:NSMakePoint(0.0, 0.0)];
  [arrow lineToPoint:NSMakePoint(4.0, 0.0)];
  [arrow lineToPoint:NSMakePoint(2.0, 5.0)];
  [arrow closePath];

  NSBezierPath *settingsArrow = [NSBezierPath bezierPath];
  [settingsArrow moveToPoint:NSMakePoint(0.0, 0.0)];
  [settingsArrow lineToPoint:NSMakePoint(7.0, 0.0)];
  [settingsArrow lineToPoint:NSMakePoint(3.5, 6.0)];
  [settingsArrow closePath];

  NSSize settingsArrowSize = [settingsArrow bounds].size;

  double widthOfLeftCapInternals = MonocleSearchViewDrawingIconSize + MonocleSearchViewDrawingIconPopupAreaWidth;
  double edgePaddingLeftCap =
    (height - MonocleSearchViewDrawingIconSize) * 0.4;  // MonocleSearchViewDrawingIconSize*0.3;
  double widthOfLeftCapArea = widthOfLeftCapInternals + (edgePaddingLeftCap * 2.0);
  NSPoint iconOriginInLeftCap =
    NSMakePoint(edgePaddingLeftCap, NSMidY(rect) - (MonocleSearchViewDrawingIconSize / 2.0));
  NSPoint arrowOriginInLeftCap = NSMakePoint(edgePaddingLeftCap + MonocleSearchViewDrawingIconSize, NSMidY(rect));
  NSSize offsetBetweenArrowsAndIconEdgeInLeftCap = NSMakeSize(3, 2);
  NSRect leftCapArea = NSMakeRect(NSMinX(rect), NSMinY(rect), widthOfLeftCapArea, height);

  double widthOfRightCapInternals = (widthOfLeftCapInternals * 0.4);
  double edgePaddingRightCap = edgePaddingLeftCap;
  double widthOfRightCapArea = widthOfRightCapInternals + (edgePaddingRightCap * 2.0);
  NSPoint arrowOriginInRightCap = NSMakePoint(NSMaxX(rect) - ((widthOfRightCapArea + settingsArrowSize.width) / 2.0),
    NSMidY(rect) - (settingsArrowSize.height / 2.0));
  NSRect rightCapArea = NSMakeRect(NSMaxX(rect) - widthOfRightCapArea, NSMinY(rect), widthOfRightCapArea, height);

  NSRect midArea = NSMakeRect(NSMaxX(leftCapArea), NSMinY(rect), NSWidth(rect) - (widthOfLeftCapArea), height);

  NSColor *engineColor = [controller colorForEngine:[selectedEngine valueForKeyPath:@"selection"] isDeduced:NULL];
  //	NSLog(@"enginecolor: %@", engineColor);
  NSColor *engineArrowsColor = [engineColor contrastingLabelColor];

  NSColor *appMenuColor = [[NSColor blackColor] colorWithAlphaComponent:0.15];
  NSColor *washColorOnAverage;
  {
    CTGradient *midWash;
    [MonocleWashDrawing getPrimaryWash:&midWash hasSheen:NULL];
    washColorOnAverage = [midWash colorAtPosition:0.5];
    washColorOnAverage = [washColorOnAverage blendedColorWithFraction:0.5 ofColor:appMenuColor];
  }
  NSColor *appMenuArrowColor = [washColorOnAverage contrastingLabelColor];

  NSShadow *appMenuArrowShadow = [[[NSShadow alloc] init] autorelease];
  [appMenuArrowShadow setShadowBlurRadius:1.5];
  [appMenuArrowShadow setShadowOffset:NSMakeSize(1, 1)];
  [appMenuArrowShadow setShadowColor:[appMenuArrowColor contrastingLabelColor]];

  [MonocleWashDrawing drawCurrentWashInRect:midArea];

  [appMenuColor setFill];
  [[NSBezierPath bezierPathWithRect:rightCapArea] fill];
  [engineColor setFill];
  [[NSBezierPath bezierPathWithRect:leftCapArea] fill];

  id selection = [selectedEngine valueForKeyPath:@"selection"];
  NSImage *currIcon = [controller formFittedImageForEngine:selection];
  [currIcon compositeToPoint:iconOriginInLeftCap operation:NSCompositeSourceOver];

  NSBezierPath *bevelShadow = [NSBezierPath bezierPath];
  [[NSColor colorWithCalibratedWhite:0.0 alpha:0.1] setStroke];
  [bevelShadow moveToPoint:NSMakePoint(widthOfLeftCapArea - 0.5, NSMaxY(rect) + 0.5)];
  [bevelShadow lineToPoint:NSMakePoint(widthOfLeftCapArea - 0.5, NSMinY(rect) - 0.5)];
  [bevelShadow moveToPoint:NSMakePoint(NSWidth(rect) - (widthOfRightCapArea - 0.5), NSMaxY(rect) + 0.5)];
  [bevelShadow lineToPoint:NSMakePoint(NSWidth(rect) - (widthOfRightCapArea - 0.5), NSMinY(rect) - 0.5)];
  [bevelShadow stroke];

  NSBezierPath *bevelHighlight = [NSBezierPath bezierPath];
  [[NSColor colorWithCalibratedWhite:1.0 alpha:0.25] setStroke];
  [bevelHighlight moveToPoint:NSMakePoint(widthOfLeftCapArea + 0.5, NSMaxY(rect) + 0.5)];
  [bevelHighlight lineToPoint:NSMakePoint(widthOfLeftCapArea + 0.5, NSMinY(rect) - 0.5)];
  [bevelHighlight moveToPoint:NSMakePoint(NSWidth(rect) - (widthOfRightCapArea + 0.5), NSMaxY(rect) + 0.5)];
  [bevelHighlight lineToPoint:NSMakePoint(NSWidth(rect) - (widthOfRightCapArea + 0.5), NSMinY(rect) - 0.5)];
  [bevelHighlight stroke];

  [engineArrowsColor setFill];

  NSAffineTransform *moveDownArrow = [NSAffineTransform transform];
  [moveDownArrow translateXBy:arrowOriginInLeftCap.x + (offsetBetweenArrowsAndIconEdgeInLeftCap.width)
                          yBy:arrowOriginInLeftCap.y + (offsetBetweenArrowsAndIconEdgeInLeftCap.height / 2.0)];
  [arrow transformUsingAffineTransform:moveDownArrow];
  [arrow fill];

  NSAffineTransform *moveUpArrow = [NSAffineTransform transform];
  [moveUpArrow translateXBy:0.0 yBy:NSHeight(rect)];
  [moveUpArrow scaleXBy:1.0 yBy:-1.0];  // invert
  [arrow transformUsingAffineTransform:moveUpArrow];
  [arrow fill];

  [appMenuArrowShadow set];
  [appMenuArrowColor setFill];

  NSAffineTransform *settingsArrowT = [NSAffineTransform transform];
  [settingsArrowT translateXBy:arrowOriginInRightCap.x yBy:arrowOriginInRightCap.y + (settingsArrowSize.height * 0.8)];
  [settingsArrowT scaleXBy:1.0 yBy:-1.0];

  [settingsArrow transformUsingAffineTransform:settingsArrowT];
  [settingsArrow fill];
}

- (float)floatByScalingFloat:(float)fl toResolutionForScreen:(NSScreen *)screen {
  float factor = [screen userSpaceScaleFactor];
  return factor * fl;
}

- (NSRect)rectByScalingRect:(NSRect)rect toResolutionForScreen:(NSScreen *)screen {
  float factor = [screen userSpaceScaleFactor];
  /*rect.origin.x *= factor;
  rect.origin.y *= factor;*/
  rect.size.height *= factor;
  rect.size.width *= factor;
  return rect;
}

- (NSPoint)pointByScalingPoint:(NSPoint)point toResolutionForScreen:(NSScreen *)screen {
  float factor = [screen userSpaceScaleFactor];
  point.x *= factor;
  point.y *= factor;
  return point;
}

- (NSSize)sizeByScalingSize:(NSSize)size toResolutionForScreen:(NSScreen *)screen {
  float factor = [screen userSpaceScaleFactor];
  size.width *= factor;
  size.height *= factor;
  return size;
}

- (void)showNextPrev {
  [self doPopUpEngines];

  return;

#if UseOutdatedAccordionCode

  NSRect existRect = [[self window] frame];
  NSScreen *scr = [[self window] screen];
  float baseHeight = MonocleDPIzeFloatD(MonocleSearchViewBaseHeight);
  NSLog(@"existRect: %@", NSStringFromRect(existRect));
  NSRect newRect =
    NSMakeRect(NSMinX(existRect), NSMaxY(existRect) - (baseHeight * 2.0), NSWidth(existRect), baseHeight * 3.0);
  NSRect rnewRect = [[self window] contentRectForFrameRect:newRect];
  NSRect origRnewRect = rnewRect;
  NSLog(@"rnewRect: %@", NSStringFromRect(rnewRect));
  rnewRect = MonocleDPIzeRect(rnewRect, scr);
  NSLog(@"corrected rnewRect: %@", NSStringFromRect(rnewRect));
  NSRect screenRect = [scr visibleFrame];
  if (!NSContainsRect(screenRect, origRnewRect)) {
    //		NSLog(@"doesn't contain rect");
    if (origRnewRect.origin.y + origRnewRect.size.height > screenRect.size.height)
      rnewRect.origin.y = MonocleDPIzeFloatD(screenRect.size.height) - rnewRect.size.height;
    if (origRnewRect.origin.y < 0.0) rnewRect.origin.y = 0.0;
    if (origRnewRect.origin.x + origRnewRect.size.width > screenRect.size.width)
      rnewRect.origin.x = MonocleDPIzeFloatD(screenRect.size.width) - rnewRect.size.width;
    if (origRnewRect.origin.x < 0.0) rnewRect.origin.x = 0.0;
  }

  if (NSEqualPoints(NSZeroPoint, referencePoint)) referencePoint = rnewRect.origin;

  if (!va) referencePoint = rnewRect.origin;

  NSMutableDictionary *md = [[NSDictionary dictionaryWithObjectsAndKeys:[self window],
                                           NSViewAnimationTargetKey,
                                           [NSValue valueWithRect:rnewRect],
                                           NSViewAnimationEndFrameKey,
                                           nil] mutableCopy];
  NSLog(@"rnewRect: %@", NSStringFromRect(rnewRect));

  NSDictionary *textFieldTransformation = [NSDictionary dictionaryWithObjectsAndKeys:textField,
                                                        NSViewAnimationTargetKey,
                                                        NSViewAnimationFadeOutEffect,
                                                        NSViewAnimationEffectKey,
                                                        nil];

  id fieldEditor = [[self window] fieldEditor:YES forObject:textField];
  //	NSLog(@"field editor: %@", fieldEditor);
  if ([fieldEditor respondsToSelector:@selector(selectedRanges)]) {
    referenceSelectedRanges = [[fieldEditor selectedRanges] retain];
  } else {
    referenceSelectedRanges = [[NSArray arrayWithObject:[NSValue valueWithRange:[fieldEditor selectedRange]]] retain];
  }
  [textField resignFirstResponder];

  if (va) {
    referencePoint.y -= baseHeight;
    rnewRect.origin = referencePoint;

    scr = [[self window] screen];
    screenRect = [scr visibleFrame];
    if (!NSContainsRect(screenRect, origRnewRect)) {
      //			NSLog(@"doesn't contain rect");
      if (origRnewRect.origin.y + origRnewRect.size.height > screenRect.size.height)
        rnewRect.origin.y = MonocleDPIzeFloatD(screenRect.size.height) - rnewRect.size.height;
      if (origRnewRect.origin.y < 0.0) rnewRect.origin.y = 0.0;
      if (origRnewRect.origin.x + origRnewRect.size.width > screenRect.size.width)
        rnewRect.origin.x = MonocleDPIzeFloatD(screenRect.size.width) - rnewRect.size.width;
      if (origRnewRect.origin.x < 0.0) rnewRect.origin.x = 0.0;
    }

    [md setObject:[NSValue valueWithRect:rnewRect] forKey:NSViewAnimationEndFrameKey];

    NSArray *v = [NSArray arrayWithObjects:md, textFieldTransformation, nil];

    [va setViewAnimations:v];
    if (![va isAnimating]) [va startAnimation];
    return;
    /*		[va stopAnimation];
    [va release];*/
    //		[md setObject:[NSValue valueWithRect:originalFrame] forKey:NSViewAnimationStartFrameKey];
    //		[[self window] setFrame:originalFrame display:YES];
  }

  NSArray *animations = [NSArray arrayWithObjects:md, textFieldTransformation, nil];

  va = [[[NSViewAnimation alloc] initWithViewAnimations:animations] retain];

  [va setDuration:[self accordionResizeTime]];
  [va setDelegate:self];

  [va startAnimation];

#endif
}

- (void)hideNextPrev {
  return;

#if UseOutdatedAccordionCode

  NSScreen *scr = [[self window] screen];
  NSRect existRect = [[self window] frame];
  float baseHeight = MonocleDPIzeFloatD(MonocleSearchViewBaseHeight);
  if (NSHeight(existRect) == baseHeight) return;
  NSRect newRect =
    NSMakeRect(NSMinX(existRect), NSMaxY(existRect) + (baseHeight * -2.0), NSWidth(existRect), baseHeight);
  NSRect rnewRect = [[self window] contentRectForFrameRect:newRect];
  NSRect origRnewRect = rnewRect;
  NSLog(@"rnewRect (hide): %@", NSStringFromRect(rnewRect));
  rnewRect = MonocleDPIzeRect(rnewRect, scr);
  NSLog(@"corrected rnewRect (hide): %@", NSStringFromRect(rnewRect));

  NSRect screenRect = [scr visibleFrame];
  if (!NSContainsRect(screenRect, origRnewRect)) {
    NSLog(@"doesn't contain rect");
    if (origRnewRect.origin.y + origRnewRect.size.height > screenRect.size.height)
      rnewRect.origin.y = MonocleDPIzeFloatD(screenRect.size.height) - rnewRect.size.height;
    if (origRnewRect.origin.y < 0.0) rnewRect.origin.y = 0.0;
    if (origRnewRect.origin.x + origRnewRect.size.width > screenRect.size.width)
      rnewRect.origin.x = MonocleDPIzeFloatD(screenRect.size.width) - rnewRect.size.width;
    if (origRnewRect.origin.x < 0.0) rnewRect.origin.x = 0.0;
  }

  if (NSEqualPoints(NSZeroPoint, referencePoint)) referencePoint = rnewRect.origin;

  if (!va) referencePoint = rnewRect.origin;

  NSMutableDictionary *md = [[NSDictionary dictionaryWithObjectsAndKeys:[self window],
                                           NSViewAnimationTargetKey,
                                           [NSValue valueWithRect:rnewRect],
                                           NSViewAnimationEndFrameKey,
                                           nil] mutableCopy];

  NSDictionary *textFieldTransformation = [NSDictionary dictionaryWithObjectsAndKeys:textField,
                                                        NSViewAnimationTargetKey,
                                                        NSViewAnimationFadeInEffect,
                                                        NSViewAnimationEffectKey,
                                                        nil];

  id fieldEditor = [[self window] fieldEditor:YES forObject:textField];
  //	NSLog(@"field editor: %@", fieldEditor);

  [[self window] makeFirstResponder:textField];

  if ([fieldEditor respondsToSelector:@selector(selectedRanges)]) {
    [fieldEditor setSelectedRanges:[referenceSelectedRanges autorelease]];
  } else {
    [fieldEditor setSelectedRange:[[referenceSelectedRanges lastObject] rangeValue]];
  }

  if (va) {
    referencePoint.y += baseHeight;
    rnewRect.origin = referencePoint;

    scr = [[self window] screen];
    screenRect = [scr visibleFrame];
    if (!NSContainsRect(screenRect, origRnewRect)) {
      //			NSLog(@"doesn't contain rect");
      if (origRnewRect.origin.y + origRnewRect.size.height > screenRect.size.height)
        rnewRect.origin.y = MonocleDPIzeFloatD(screenRect.size.height) - rnewRect.size.height;
      if (origRnewRect.origin.y < 0.0) rnewRect.origin.y = 0.0;
      if (origRnewRect.origin.x + origRnewRect.size.width > screenRect.size.width)
        rnewRect.origin.x = MonocleDPIzeFloatD(screenRect.size.width) - rnewRect.size.width;
      if (origRnewRect.origin.x < 0.0) rnewRect.origin.x = 0.0;
    }

    [md setObject:[NSValue valueWithRect:rnewRect] forKey:NSViewAnimationEndFrameKey];

    NSArray *v = [NSArray arrayWithObjects:md, textFieldTransformation, nil];
    [va setViewAnimations:v];
    if (![va isAnimating]) [va startAnimation];
    return;
    /*		[va stopAnimation];
        [va release];*/
    //		[md setObject:[NSValue valueWithRect:originalFrame] forKey:NSViewAnimationStartFrameKey];
    //		[[self window] setFrame:originalFrame display:YES];
  }

  NSArray *animations = [NSArray arrayWithObjects:md, textFieldTransformation, nil];
  va = [[[NSViewAnimation alloc] initWithViewAnimations:animations] retain];

  [va setDuration:[self accordionResizeTime]];
  [va setDelegate:self];

  [va startAnimation];

#endif
}

- (NSTimeInterval)accordionResizeTime {
  NSTimeInterval ti = 0.1;

  NSEvent *lastEv = [[NSApplication sharedApplication] currentEvent];
  unsigned int flags = [lastEv modifierFlags];
  if ((flags & NSShiftKeyMask) && (flags & NSControlKeyMask)) ti *= 4;

  return ti;
}

- (void)animationDidEnd:(NSAnimation *)animation {
  [va release];
  va = nil;
  referencePoint = NSZeroPoint;
}

- (MonocleController *)controller {
  return controller;
}

- (void)setController:(MonocleController *)aController {
  if (controller != aController) {
    [controller release];
    controller = [aController retain];
  }
}

- (NSString *)searchText {
  return [textField stringValue];
}

- (void)setSearchText:(NSString *)st {
  [textField setStringValue:st];
}

- (IBAction)doSearch:(id)sender {
  if ([[[self searchText] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]
        isEqualTo:@""])
    return;
  //	NSLog(@"do search... text: %@", [self searchText]);

  //	NSString *suggstr = [self searchText];
  /*	[[[self window] fieldEditor:YES forObject:textField] complete:self];
    MonocleSuggestionProviderFromSpellChecker *spsc = [[MonocleSuggestionProviderFromSpellChecker alloc] init];
    NSLog(@" - spell checker: %@", [spsc suggestionsForString:suggstr]);*/
  /*	MonocleSuggestionProviderFromGoogle *spg = [[MonocleSuggestionProviderFromGoogle alloc] init];
    NSLog(@" - Google: %@", [spg suggestionsForString:suggstr]);
    MonocleSuggestionProviderFromYahoo *spy = [[MonocleSuggestionProviderFromYahoo alloc] init];
    NSLog(@" - Yahoo!: %@", [spy suggestionsForString:suggstr]);

    suggstr = @"1\"3'3";
    NSLog(@"suggestions for %@", suggstr);
    NSLog(@" - spell checker: %@", [spsc suggestionsForString:suggstr]);
    NSLog(@" - Google: %@", [spg suggestionsForString:suggstr]);
    NSLog(@" - Yahoo!: %@", [spy suggestionsForString:suggstr]);*/

  [self performSearch];
}

- (void)performSearch {
  id sl = [self selectedEngine];
  if (sl == nil) return;

  [[self controller] dispatchSearchForQuery:[self searchText] usingEngine:sl];

  [[self controller] hideIfInStatusItem];
}

- (void)selectEngineWithIndex:(int)idx {
  [self willChangeValueForKey:@"selectedEngine"];
  NSArray *engines = [controlledEngines arrangedObjects];
  if ((!engines) || ([engines count] < 1)) {
    [self didChangeValueForKey:@"selectedEngine"];
    return;
  }
  engineIndex = idx;
  [self didChangeValueForKey:@"selectedEngine"];

  [self makeSureSelectedIsNotIncapacitatedAdjustingUp:YES];
}

- (void)upArrowKey {
  if (anySearchHelp) {
    [self moveSearchHelpSelectionUp];
  } else {
    [self moveSelectionUp];
  }
}

- (void)downArrowKey {
  if (anySearchHelp) {
    [self moveSearchHelpSelectionDown];
  } else {
    [self moveSelectionDown];
  }
}

- (BOOL)rightArrowKey {
  if (anySearchHelp) {
    return [self fillInSearchHelp];
  } else {
    return NO;
  }
}

- (void)moveSelectionDown {
  [self willChangeValueForKey:@"selectedEngine"];
  NSArray *engines = [controlledEngines arrangedObjects];
  if ((!engines) || ([engines count] < 2)) {
    [self didChangeValueForKey:@"selectedEngine"];
    return;
  }
  unsigned int count = [engines count];
  if ((engineIndex + 1) == count) {
    engineIndex = 0;
  } else {
    engineIndex++;
  }
  [self didChangeValueForKey:@"selectedEngine"];
  [self makeSureSelectedIsNotIncapacitatedAdjustingUp:NO];
}

- (void)moveSelectionUp {
  [self willChangeValueForKey:@"selectedEngine"];
  NSArray *engines = [controlledEngines arrangedObjects];
  if ((!engines) || ([engines count] < 2)) {
    [self didChangeValueForKey:@"selectedEngine"];
    return;
  }
  unsigned int count = [engines count];
  if (engineIndex == 0) {
    engineIndex = count - 1;
  } else {
    engineIndex--;
  }
  [self didChangeValueForKey:@"selectedEngine"];
  [self makeSureSelectedIsNotIncapacitatedAdjustingUp:YES];
}

- (void)makeSureSelectedIsNotIncapacitatedAdjustingUp:(BOOL)up {
  if ([[[selectedEngine selection] valueForKey:@"toBeAdded"] boolValue]) {
    if (up)
      [self moveSelectionUp];
    else
      [self moveSelectionDown];
  }
}

- (void)controlTextDidChange:(NSNotification *)aNotification {
  NSUserDefaultsController *udc = [NSUserDefaultsController sharedUserDefaultsController];

  NSNumber *usesCallwords = [udc valueForKeyPath:@"values.usesCallwords"];
  //	NSLog(@"uses callwords: %@", usesCallwords);
  //	if (usesCallwords == nil) return;
  if ((usesCallwords != nil) && ([usesCallwords boolValue] == NO)) return;

  NSNumber *appr = [udc valueForKeyPath:@"values.callwordScheme"];
  //	NSLog(@"callword approach: %@", appr);
  if (appr == nil) appr = [NSNumber numberWithInt:0];
  int a = [appr intValue];
  //	NSLog(@"effective callword approach: %d", a);

  static NSMutableDictionary *callwords = nil;

  //	NSLog(@"has callwords?");
  if ((nil == callwords) || callwordCacheNeedsRedoing) {
    /*		if (nil == callwords)
          NSLog(@"no! let's build 'em");
        else
          NSLog(@"yes, but they're outdated");*/
    if (callwordCacheNeedsRedoing && (callwords != nil))
      [callwords removeAllObjects];
    else
      callwords = [[NSDictionary dictionary] mutableCopy];
    NSArray *engines = [controlledEngines arrangedObjects];
    NSEnumerator *engineEnumerator = [engines objectEnumerator];
    NSMutableDictionary *engine;
    while (engine = [engineEnumerator nextObject]) {
      if ([engine objectForKey:@"callword"]) {
        //				NSLog(@"adding name: %@, callword: %@", [engine objectForKey:@"name"], [engine
        // objectForKey:@"callword"]);
        [callwords setObject:[engine objectForKey:@"callword"] forKey:[engine objectForKey:@"name"]];
      }
    }
    callwordCacheNeedsRedoing = NO;
  }

  NSString *text = [[aNotification object] stringValue];
  //	NSLog(@"text is: %@", text);
  NSString *prefix = nil;
  switch (a) {
    case 0:
      prefix = @":";
      break;
    case 1:
      prefix = @"_";
      break;
    case 2:
      prefix = @"%";
      break;
  }
  if ((prefix == nil || [text hasPrefix:prefix]) && [callwords count] > 0) {
    NSEnumerator *keyEnumerator = [[callwords allKeys] objectEnumerator];
    NSString *key;
    while (key = [keyEnumerator nextObject]) {
      NSString *cw = [callwords objectForKey:key];
      NSString *lookFor =
        ((prefix == nil) ? [NSString stringWithFormat:@"%@ ", cw] : [NSString stringWithFormat:@"%@%@ ", prefix, cw]);
      if ([text hasPrefix:lookFor]) {
        NSArray *engines = [controlledEngines arrangedObjects];
        NSEnumerator *engineEnumerator = [engines objectEnumerator];
        NSDictionary *engine;
        int i = 0;
        while (engine = [engineEnumerator nextObject]) {
          if ([[engine objectForKey:@"name"] isEqualToString:key]) break;
          i++;
        }

        [self willChangeValueForKey:@"selectedEngine"];
        engineIndex = i;
        [self didChangeValueForKey:@"selectedEngine"];

        // Is there a better way to move caret while removing the prefix?
        for (i = 0; i < [lookFor length]; i++) {
          [[[aNotification object] currentEditor] moveLeft:nil];
        }
        [[aNotification object] setStringValue:[text substringFromIndex:[lookFor length]]];
      }
    }
  }

  text = [[aNotification object] stringValue];

  NSMutableString *mutableText = [[text mutableCopy] autorelease];
  [mutableText replaceOccurrencesOfString:@"\t"
                               withString:@" "
                                  options:NSLiteralSearch
                                    range:NSMakeRange(0, [mutableText length])];
  [mutableText replaceOccurrencesOfString:@"\r\n"
                               withString:@" "
                                  options:NSLiteralSearch
                                    range:NSMakeRange(0, [mutableText length])];
  [mutableText replaceOccurrencesOfString:@"\n"
                               withString:@" "
                                  options:NSLiteralSearch
                                    range:NSMakeRange(0, [mutableText length])];
  [mutableText replaceOccurrencesOfString:@"\r"
                               withString:@" "
                                  options:NSLiteralSearch
                                    range:NSMakeRange(0, [mutableText length])];
  if (![text isEqualToString:[mutableText description]]) {
    text = [mutableText description];
    [[aNotification object] setStringValue:text];
  }

  NSString *oldCurrentSearchText = currentSearchText;
  currentSearchText = [text retain];
  [oldCurrentSearchText release];

  [self updateSearchHelp];

  //	NSLog(@"text did change");
}

- (void)nudge {
  [self updateSearchHelp];
}

//#define	MONOCLE_SEARCH_HELP_COLLATING_DELAY	0.09
#define MONOCLE_SEARCH_HELP_COLLATING_DELAY 0.15

- (void)updateSearchHelp {
  SEL invocationSelector = @selector(updateSearchHelpDoStart:);
  [[self class] cancelPreviousPerformRequestsWithTarget:self selector:invocationSelector object:nil];
  [self performSelector:invocationSelector withObject:nil afterDelay:MONOCLE_SEARCH_HELP_COLLATING_DELAY];
}

// http://cocoadev.com/index.pl?DetachedThreadWithNSTimer
/*-(void)establishSearchHelpTimer {



    NSRunLoop *theLoop = [NSRunLoop currentRunLoop];
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
//	NSLog(@"established search help timer in new thread");
  double interval = 0.45;
    NSTimer *timer = [[NSTimer scheduledTimerWithTimeInterval:interval
                        target:self
                                            selector:@selector(updateSearchHelpTimer:)
                                            userInfo:nil
                       repeats:YES] retain];
    [theLoop addTimer:timer forMode:NSDefaultRunLoopMode];
    [theLoop run];

//	NSLog(@"search help timer thread returned!?");
    [pool release];
}*/

- (void)updateSearchHelpDoStart:(id)object {
  [NSThread detachNewThreadSelector:@selector(updateSearchHelpTimer:) toTarget:self withObject:nil];
}

- (void)updateSearchHelpTimer:(NSTimer *)timer {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

  if (isUpdatingSearchhelp) {
    wantsToUpdateSearchhelp = YES;
    // NSLog(@"already updating search help; bailing");
    return;
  }
  NSString *string = [currentSearchText copy];
  if (([string isEqualToString:currentSearchhelpIsForString] || [string isEqualToString:draftSearchhelpIsForString]) &&
    !wantsToUpdateSearchhelp) {
    // NSLog(@"already have up-to-date search help; bailing");
    [string release];
    return;
  }
  wantsToUpdateSearchhelp = NO;
  isUpdatingSearchhelp = YES;
  [self updateSearchHelp:[string autorelease]];
  isUpdatingSearchhelp = NO;

  [pool release];
}

- (void)resultsSuggestions:(NSArray *)res fromProvider:(NSString *)prov forJob:(unsigned int)job {
  @synchronized(searchhelpHandle) {
    if (job == currentSearchhelpJob) {
      //			NSLog(@"[%d] received from provider: %@", job, prov);
      [draftSearchhelpResults setObject:res forKey:prov];
      //			NSLog(@"[%d] value: %@", job, res);

      NSArray *ordered = [MonocleSuggestionProvider orderedEnabledIdentifiersForEngine:[self selectedEngine]];

      NSMutableArray *results = [NSMutableArray array];

      //			NSLog(@"[%d] assembling list (%@)", job, [draftSearchhelpResults allKeys]);

      NSEnumerator *orderedEnumerator = [ordered objectEnumerator];
      NSString *orderedId;
      while (orderedId = [orderedEnumerator nextObject]) {
        id ressug = [draftSearchhelpResults objectForKey:orderedId];
        if (ressug) {
          [results addObject:ressug];
        }
      }

      [currentSearchhelpResults autorelease];
      currentSearchhelpResults = [results copy];
      //			NSLog(@"curr results: %@", currentSearchhelpResults);

      [currentSearchhelpIsForString autorelease];
      currentSearchhelpIsForString = [draftSearchhelpIsForString copy];
    }
  }
  [self performSelectorOnMainThread:@selector(updateSearchHelpDisplayInfo:) withObject:nil waitUntilDone:NO];
}

- (BOOL)updateSearchHelp:(NSString *)string {
  // NSLog(@"update search help: %@", string);
  @synchronized(searchhelpHandle) {
    currentSearchhelpJob++;
    [draftSearchhelpIsForString release];
    draftSearchhelpIsForString = [string copy];
    [draftSearchhelpResults removeAllObjects];
    [MonocleSuggestionProvider combinedResultsSuggestionsForString:string
                                                            forJob:currentSearchhelpJob
                                                       usingEngine:[self selectedEngine]
                                                          delegate:self];

  }/*
	{
		[searchhelpResults release];
//		[searchhelpSuggestions release];
		searchhelpResults = [[MonocleSuggestionProvider combinedResultsSuggestionsForString:string] retain];
//		searchhelpSuggestions = [[MonocleSuggestionProvider combinedSuggestionsForString:string] retain];
		//NSLog(@"Results for query %@: %@", string, searchhelpResults);
		//NSLog(@"Suggestions for query %@: %@", string, searchhelpSuggestions);
		[currentSearchhelpResults release];
		currentSearchhelpResults = [searchhelpResults copy];
/*		[currentSearchhelpSuggestions release];
		currentSearchhelpSuggestions = [searchhelpSuggestions copy];/
		[currentSearchhelpIsForString release];
		currentSearchhelpIsForString = [string copy];
	}*//*
	if (!wantsToUpdateSearchhelp) {
//		NSLog(@"updated search help");
//	[self updateSearchHelpDisplayInfo:nil];//  [[NSNotificationCenter defaultCenter] postNotificationName:MonocleSearchHelpDataUpdated object:self];	
		[self performSelectorOnMainThread:@selector(updateSearchHelpDisplayInfo:) withObject:nil waitUntilDone:NO];
		return YES;
	} else {*/
  return NO;
  //	}
}

- (void)hideSearchHelp {
  anySearchHelp = NO;
  [borderlessSearchHelpWindow setAlphaValue:0];
}

- (BOOL)hasNonEmptySearchHelpSelected {
  BOOL x = [[[searchHelpWebView windowScriptObject] callWebScriptMethod:@"hasAnySelection"
                                                          withArguments:[NSArray array]] boolValue];
  //	NSLog(@"hasNonEmptySearchHelpSelected? %d", x);
  return x;
}

- (void)doTheRightThingWhenSearchHelpSelectionChanges {
  id selection = [[searchHelpWebView windowScriptObject] callWebScriptMethod:@"getSelection"
                                                               withArguments:[NSArray array]];
  if ([[selection description] isEqualToString:@"null"]) {
    selectedSearchHelp = nil;
  } else {
    NSDictionary *selDict = [NSDictionary dictionaryWithJSONString:[selection description]];
    selectedSearchHelp = [selDict copy];
    //		NSLog(@"selected search help: %@", selectedSearchHelp);
  }
}

- (void)moveSearchHelpSelectionUp {
  [[searchHelpWebView windowScriptObject] callWebScriptMethod:@"moveSelectionUp" withArguments:[NSArray array]];
  [self doTheRightThingWhenSearchHelpSelectionChanges];
}

- (void)moveSearchHelpSelectionDown {
  [[searchHelpWebView windowScriptObject] callWebScriptMethod:@"moveSelectionDown" withArguments:[NSArray array]];
  [self doTheRightThingWhenSearchHelpSelectionChanges];
}

- (BOOL)fillInSearchHelp {
  if (!selectedSearchHelp) return NO;
  if ([selectedSearchHelp objectForKey:@"suggestion"]) {
    NSString *sugg = [selectedSearchHelp objectForKey:@"suggestion"];
    /*
    NSRange r = [[[textField window] fieldEditor:NO forObject:textField] selectedRange];
    NSString *currentText = [textField stringValue];
    if (r.length > 0) {
      currentText = [currentText substringToIndex:r.location];
    }
    NSLog(@"suggested string: %@, current: %@", sugg, currentText);
    [textField setStringValue:sugg];
    if ([[sugg lowercaseString] hasPrefix:[currentText lowercaseString]]) {
      // find common case-insensitive length
      int width = 0;
      int max = MIN([sugg length], [currentText length]);
      for (; width < max-1; width++) {
        NSRange rangeOfCharString = NSMakeRange(width, 1);
        NSLog(@"range: %@", NSStringFromRange(rangeOfCharString));
        if (!([[[sugg substringWithRange:rangeOfCharString] lowercaseString]
             isEqualToString:[[currentText substringWithRange:rangeOfCharString] lowercaseString]]))
          break;
      }
      [[[textField window] fieldEditor:NO forObject:textField] setSelectedRange:NSMakeRange(width, [sugg
    length]-width)]; } else {
      [[[textField window] fieldEditor:NO forObject:textField] setSelectedRange:NSMakeRange(0, [sugg length])];
    }*/

    [textField setStringValue:sugg];
    [self controlTextDidChange:[NSNotification notificationWithName:NSControlTextDidChangeNotification
                                                             object:textField]];
    [[[textField window] fieldEditor:NO forObject:textField] setSelectedRange:NSMakeRange([sugg length], 0)];
  } else {
    //		NSLog(@"supposed to navigate to site: %@", selectedSearchHelp);
    BOOL succeeded = [MonocleSuggestionProvider openResult:[selectedSearchHelp objectForKey:@"url"]
                               usingProviderWithIdentifier:[selectedSearchHelp objectForKey:@"providerIdentifier"]];
    //		[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[selectedSearchHelp objectForKey:@"url"]]];
    if (succeeded) {
      [self searchLaunched];
    }
    return succeeded;
    //[self setSearchText:@""];
  }
  return YES;
}

- (BOOL)showsSearchHelp {
  return anySearchHelp;
}

- (void)updateSearchHelpDisplayInfo:(NSNotification *)notificationPerhaps {
  //	NSLog(@"asked to display search help: %@", currentSearchhelpResults);
  while (isDisplayingSearchhelp) {
    //		NSLog(@"spinning");
    int i = 0;
    for (; i < 15; i++) {
      [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
      if (!isDisplayingSearchhelp) break;
    }
  }
  isDisplayingSearchhelp = YES;
  @synchronized(searchhelpUpdatingHandle) {
    //		NSLog(@"displaying");
    NSMutableArray *data = [NSMutableArray array];

    NSArray *searchhelpResultsSnapshot = [currentSearchhelpResults copy];
    //		NSLog(@"search help: %@", searchhelpResultsSnapshot);

    NSEnumerator *resEnumerator = [searchhelpResultsSnapshot objectEnumerator];
    NSArray *resSet;
    while (resSet = [resEnumerator nextObject]) {
      if ([resSet count] != 3) continue;
      NSString *info = [resSet objectAtIndex:0];
      NSString *identifier = [resSet objectAtIndex:1];
      NSArray *rs = [resSet objectAtIndex:2];
      if ([rs count] == 0) continue;

      [data addObject:info];
      [data addObject:identifier];
      [data addObjectsFromArray:rs];
    }

    [searchhelpResultsSnapshot release];

    NSString *resultsJSON = [[NSDictionary dictionaryWithObject:data forKey:@"results"] jsonStringValue];
    //		NSLog(@"data %@", data);
    //		NSLog(@"resultsJSON: %@", resultsJSON);

    [[searchHelpWebView windowScriptObject]
      callWebScriptMethod:@"updateResultsList"
            withArguments:[NSArray
                            arrayWithObjects:resultsJSON, [self searchText], [[self searchText] lowercaseString], nil]];

    [self showOrHideSearchHelp];

    isDisplayingSearchhelp = NO;
  }
}

- (void)nilOutSearchHelp {
  currentSearchhelpJob++;
  [[searchHelpWebView windowScriptObject]
    callWebScriptMethod:@"updateResultsList"
          withArguments:[NSArray arrayWithObjects:[[NSDictionary dictionaryWithObject:[NSArray array]
                                                                               forKey:@"results"] jsonStringValue],
                                 @"",
                                 @"",
                                 nil]];

  NSString *oldStr = currentSearchhelpIsForString;
  currentSearchhelpIsForString = [@"" copy];
  [oldStr release];

  NSArray *oldArr = currentSearchhelpResults;
  currentSearchhelpResults = [[NSArray alloc] init];
  [oldArr release];

  isDisplayingSearchhelp = NO;
}

- (void)appBecameActive {
  hideSearchHelpUntilBecomesActive = NO;
}

- (void)searchLaunched {
  if ([MonoclePreferences boolForKey:@"emptiesSearchFieldBetweenSearches" orDefault:YES]) {
    [self setSearchText:@""];
    [self nilOutSearchHelp];
  }

  hideSearchHelpUntilBecomesActive = YES;
  [self hideSearchHelp];
  [self hide];
}

- (void)showOrHideSearchHelp {
  if (!isSearchViewShown) {
    [self hideSearchHelp];
    return;
  }
  if (!hasSetSpacesBehavior) {
    [controller prepareWindow:borderlessSearchHelpWindow
      forSpacesUsingCollectionBehavior:1 /* NSWindowCollectionBehaviorCanJoinAllSpaces */];
    hasSetSpacesBehavior = YES;
  }

  if (hideSearchHelpUntilBecomesActive) {
    [self hideSearchHelp];
    return;
  }
  BOOL noResults = [[[searchHelpWebView windowScriptObject] callWebScriptMethod:@"isEmpty"
                                                                  withArguments:[NSArray array]] boolValue];
  if (noResults) {
    [self hideSearchHelp];
  } else {
    anySearchHelp = YES;
    [borderlessSearchHelpWindow setAlphaValue:0.9];
    [borderlessSearchHelpWindow orderFront:self];

    NSRect searchPanelFrame = [[self window] frame];
    searchPanelFrame.size.height = NSHeight([self frame]);

    id height = [[searchHelpWebView windowScriptObject] callWebScriptMethod:@"getHeight" withArguments:[NSArray array]];

    //		NSRect webRect = [[[[searchHelpWebView mainFrame] frameView] documentView] frame];

    //			NSLog(@"height: %@, class: %@", height, [height className]);
    //			NSLog(@"rect: %@", NSStringFromRect(searchPanelFrame));

    double y = NSMinY(searchPanelFrame);

    double calcHeight = MAX([height doubleValue], 30);
    calcHeight = MIN(calcHeight, 400);
    //		NSLog(@"calc height: %f", calcHeight);

    //			NSLog(@"y: %f", y);
    if ((y - calcHeight) < 0) {
      //				NSLog(@"calc height too high: %f", (y - calcHeight));
      calcHeight += (y - calcHeight);
      //				NSLog(@"calc height corrected: %f", calcHeight);

      //				NSLog(@"y = %f", (y - calcHeight));
    }

    NSRect webRect = NSMakeRect(NSMinX(searchPanelFrame), y - calcHeight, NSWidth(searchPanelFrame), calcHeight);

    //			NSLog(@"webRect: %@", NSStringFromRect(webRect));

    /*
    // hack to get rid of lingering scroll bar
    [[searchHelpWebView window] setFrame:webRect display:NO];
    webRect.origin.y-=1;
    webRect.size.height+=1;
    [[searchHelpWebView window] setFrame:webRect display:NO];
    webRect.origin.y+=1;
    webRect.size.height-=1;*/
    [[searchHelpWebView window] setFrame:webRect display:YES];

    //		[[searchHelpWebView window] setFrame:[[searchHelpWebView window]
    // frameRectForContentRect:NSMakeRect(NSMinX(searchPanelFrame), y - calcHeight, NSWidth(searchPanelFrame),
    // calcHeight)] display:YES];//MAX(NSHeight(webRect), 120))];
    //		[[searchHelpWebView window]  setFrameTopLeftPoint:NSMakePoint(NSMinX(searchPanelFrame),
    // NSMinY(searchPanelFrame))];
  }
}

- (void)webView:(WebView *)sender windowScriptObjectAvailable:(WebScriptObject *)windowScriptObject {
  [windowScriptObject setValue:self forKey:@"monocle"];
  //	NSLog(@"registered scripting object");
}

- (void)webView:(WebView *)sender runJavaScriptAlertPanelWithMessage:(NSString *)message {
  //	NSLog(@"JSALERT: %@", message);
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)aSelector {
  return (aSelector != @selector(jsvisible_goToResult:) && aSelector != @selector(jsvisible_getHeight) &&
    aSelector != @selector(jsvisible_getInstructionsInnerHTML) &&
    aSelector != @selector(jsvisible_getInstructionsInnerHTMLNonSelection));
}

+ (NSString *)webScriptNameForSelector:(SEL)aSelector {
  if (aSelector == @selector(jsvisible_goToResult:)) {
    return @"goToResult";
  }
  if (aSelector == @selector(jsvisible_getHeight)) {
    return @"getHeight";
  }
  if (aSelector == @selector(jsvisible_getInstructionsInnerHTML)) {
    return @"getInstructionsInnerHTML";
  }
  if (aSelector == @selector(jsvisible_getInstructionsInnerHTMLNonSelection)) {
    return @"getInstructionsInnerHTMLNonSelection";
  }
  return [super webScriptNameForSelector:aSelector];
}

- (int)jsvisible_getHeight {
  return NSHeight([[searchHelpWebView window] frame]);
}

#define KEY_CODE_FOR_RETURN 36
#define KEY_CODE_FOR_UPARROW 126
#define KEY_CODE_FOR_DOWNARROW 125

- (NSString *)jsvisible_getInstructionsInnerHTML {
  BOOL enterMeansSearch = [MonoclePreferences boolForKey:@"searchTakesPriority" orDefault:NO];

  return [NSString
    stringWithFormat:NSLocalizedString(@"Search with %@. Follow suggestion/result with %@.",
                       @"Instructions in search help (selection active)"),
    //			[engineName stringByHTMLEntityEscaping],
    SRStringForCocoaModifierFlagsAndKeyCode((enterMeansSearch ? 0 : NSAlternateKeyMask), KEY_CODE_FOR_RETURN),
    SRStringForCocoaModifierFlagsAndKeyCode((enterMeansSearch ? NSAlternateKeyMask : 0), KEY_CODE_FOR_RETURN)];
}

- (NSString *)jsvisible_getInstructionsInnerHTMLNonSelection {
  //	BOOL enterMeansSearch = [MonoclePreferences boolForKey:@"searchTakesPriority" orDefault:NO];
  BOOL cmdKeyToSelect = [MonoclePreferences boolForKey:@"arrowsNeedCommand" orDefault:NO];

  return
    [NSString stringWithFormat:NSLocalizedString(@"Search with %@. Select suggestion/result with %@/%@.",
                                 @"Instructions in search help"),
              //			[engineName stringByHTMLEntityEscaping],
              SRStringForCocoaModifierFlagsAndKeyCode(0, KEY_CODE_FOR_RETURN),
              SRStringForCocoaModifierFlagsAndKeyCode((cmdKeyToSelect ? NSCommandKeyMask : 0), KEY_CODE_FOR_UPARROW),
              SRStringForCocoaModifierFlagsAndKeyCode((cmdKeyToSelect ? NSCommandKeyMask : 0), KEY_CODE_FOR_DOWNARROW)];
}

- (void)jsvisible_goToResult:(NSString *)str {
  //	NSDictionary *dict = [NSDictionary dictionaryWithJSONString:str];
  //	NSLog(@"go to result: %@", dict);
}

/*
#pragma mark -
#pragma mark Search helper table data source

- (int)numberOfRowsInTableView:(NSTableView *)aTableView {
  return [displaySearchhelp count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
  return [displaySearchhelp objectAtIndex:rowIndex];
}

- (NSAttributedString *)searchhelpAttributedStringForRow:(int)rowIndex {

  id data = [displaySearchhelp objectAtIndex:rowIndex];

  NSTextBlock *block = [[NSTextBlock alloc] init];
  [block setWidth:2.0 type:NSTextBlockAbsoluteValueType forLayer:NSTextBlockPadding];

  NSMutableParagraphStyle *mps = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
  [mps setTextBlocks:[NSArray arrayWithObject:block]];

  double paddingX = 4.0;

  NSMutableParagraphStyle *leading = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
  [leading setMinimumLineHeight:12.0];
  [leading setFirstLineHeadIndent:paddingX];
  [leading setTailIndent:-paddingX];
  [leading setHeadIndent:paddingX];

  NSDictionary *groups = [NSDictionary dictionaryWithObjectsAndKeys:
    [NSFont fontWithName:@"Helvetica-Bold" size:13.0], NSFontAttributeName,
    [NSColor gridColor], NSBackgroundColorAttributeName,
    [NSColor alternateSelectedControlTextColor], NSForegroundColorAttributeName,
    leading, NSParagraphStyleAttributeName,
    nil];
  /*
  NSDictionary *def = [NSDictionary dictionaryWithObjectsAndKeys:
    [NSFont systemFontOfSize:[NSFont smallSystemFontSize]], NSFontAttributeName,
    leading, NSParagraphStyleAttributeName,
    nil];

  NSDictionary *loc = [NSDictionary dictionaryWithObjectsAndKeys:
    [NSFont systemFontOfSize:[NSFont smallSystemFontSize]], NSFontAttributeName,
    [[NSColor greenColor] shadowWithLevel:0.4], NSForegroundColorAttributeName,
    leading, NSParagraphStyleAttributeName,
    nil];

  NSDictionary *suggc = [NSDictionary dictionaryWithObjectsAndKeys:
    [NSFont boldSystemFontOfSize:[NSFont smallSystemFontSize]], NSFontAttributeName,
    [NSColor grayColor], NSForegroundColorAttributeName,
    leading, NSParagraphStyleAttributeName,
    nil];

  NSDictionary *descr = [NSDictionary dictionaryWithObjectsAndKeys:
    [NSFont systemFontOfSize:[NSFont smallSystemFontSize]-1.0], NSFontAttributeName,
    leading, NSParagraphStyleAttributeName,
    nil];

  NSDictionary *bolded = [NSDictionary dictionaryWithObjectsAndKeys:
    [NSFont boldSystemFontOfSize:[NSFont smallSystemFontSize]], NSFontAttributeName,
    leading, NSParagraphStyleAttributeName,
    nil];
   ///


  NSDictionary *def = [NSDictionary dictionaryWithObjectsAndKeys:
    [NSFont systemFontOfSize:[NSFont smallSystemFontSize]], NSFontAttributeName,
    leading, NSParagraphStyleAttributeName,
    nil];

  NSShadow *subtle = [[NSShadow alloc] init];
  [subtle setShadowColor:[[NSColor textColor] colorWithAlphaComponent:0.12]];
  [subtle setShadowBlurRadius:2.0];
  [subtle setShadowOffset:NSMakeSize(0.0,-0.5)];

  NSDictionary *loc = [NSDictionary dictionaryWithObjectsAndKeys:
    [NSFont fontWithName:@"Helvetica-Bold" size:[NSFont systemFontSize]*0.85], NSFontAttributeName,
    [searchhelpTableGridColor shadowWithLevel:0.1], NSForegroundColorAttributeName,
//		subtle, NSShadowAttributeName,
    [NSNumber numberWithFloat:-0.15], NSKernAttributeName,
    leading, NSParagraphStyleAttributeName,
    nil];

  NSDictionary *suggc = [NSDictionary dictionaryWithObjectsAndKeys:
    [NSFont boldSystemFontOfSize:[NSFont smallSystemFontSize]], NSFontAttributeName,
    [NSColor grayColor], NSForegroundColorAttributeName,
    leading, NSParagraphStyleAttributeName,
    nil];

  NSDictionary *descr = [NSDictionary dictionaryWithObjectsAndKeys:
    [NSFont fontWithName:@"Helvetica" size:[NSFont systemFontSize]*0.95], NSFontAttributeName,
    [[NSColor textColor] colorWithAlphaComponent:0.7], NSForegroundColorAttributeName,
    leading, NSParagraphStyleAttributeName,
    nil];

  NSDictionary *bolded = [NSDictionary dictionaryWithObjectsAndKeys:
    [NSFont fontWithName:@"Helvetica-Bold" size:[NSFont systemFontSize]*0.95], NSFontAttributeName,
    [NSColor textColor], NSForegroundColorAttributeName,
    [NSNumber numberWithFloat:-0.1], NSKernAttributeName,
    leading, NSParagraphStyleAttributeName,
    nil];


  NSDictionary *paddingdict = [NSDictionary dictionaryWithObjectsAndKeys:
    [NSFont systemFontOfSize:paddingX], NSFontAttributeName,
    nil];

  NSAttributedString *padding = [[NSAttributedString alloc] initWithString:@"\n" attributes:paddingdict];

  NSMutableAttributedString *mas = [[NSMutableAttributedString alloc] initWithString:@"" attributes:def];
  if ([data isKindOfClass:[MonocleResult class]]) {
    MonocleResult *res = data;
    [mas appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n",[res
title]] attributes:bolded]]; if ([res description] != nil) { [mas appendAttributedString:[[NSAttributedString alloc]
initWithString:[NSString stringWithFormat:@"%@\n",[res description]] attributes:descr]];
    }
    [mas appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n",[res
location]] attributes:loc]]; } else if ([data isKindOfClass:[MonocleSuggestion class]]) { MonocleSuggestion *sug = data;
    [mas appendAttributedString:[[NSAttributedString alloc] initWithString:[sug suggestion] attributes:suggc]];
  } else {
    [mas appendAttributedString:[[NSAttributedString alloc] initWithString:[data description] attributes:groups]];
  }

  [mas insertAttributedString:[padding copy] atIndex:0];
  [mas appendAttributedString:[padding copy]];

//	[mas addAttribute:NSParagraphStyleAttributeName value:mps range:NSMakeRange(0,[[mas string] length])];

  return mas;
}

- (double)searchhelpHeightForRow:(int)rowIndex {
  NSTextStorage *textStorage = [[[NSTextStorage alloc]
        initWithAttributedString:[self searchhelpAttributedStringForRow:rowIndex]] autorelease];
  NSTextContainer *textContainer = [[[NSTextContainer alloc]
        initWithContainerSize: NSMakeSize([[[searchHelpTable tableColumns] objectAtIndex:0] width], FLT_MAX)]
autorelease]; NSLayoutManager *layoutManager = [[[NSLayoutManager alloc] init] autorelease];

  [layoutManager addTextContainer:textContainer];
  [textStorage addLayoutManager:layoutManager];
  [textContainer setLineFragmentPadding:8.0];

  (void) [layoutManager glyphRangeForTextContainer:textContainer];
  NSRect r = [layoutManager usedRectForTextContainer:textContainer];
  double height = NSHeight(r);

  NSLog(@"search help height %f [%@] for row %@", height, NSStringFromRect(r), [textStorage string]);
//	if ([[displaySearchhelp objectAtIndex:rowIndex] isKindOfClass:[MonocleResult class]]) height += 6.0;
  return height;
}

#pragma mark Search helper table delegate

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn
row:(int)rowIndex {

  id data = [displaySearchhelp objectAtIndex:rowIndex];
  NSTextFieldCell *c = aCell;
  if ([data isKindOfClass:[NSString class]]) {
    NSAttributedString *as = [self searchhelpAttributedStringForRow:rowIndex];
    [c setDrawsBackground:YES];
    NSMutableAttributedString *mas = [as mutableCopy];
    [mas removeAttribute:NSBackgroundColorAttributeName range:NSMakeRange(0,[[mas string] length])];
    [mas addAttribute:NSBackgroundColorAttributeName value:searchhelpTableGridColor range:NSMakeRange(0,[[mas string]
length])]; [c setBackgroundColor:searchhelpTableGridColor]; [c setAttributedStringValue:mas]; } else { [c
setDrawsBackground:NO]; NSAttributedString *as = [self searchhelpAttributedStringForRow:rowIndex];

    [c setAttributedStringValue:as];
  }

}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(int)rowIndex {
  id data = [displaySearchhelp objectAtIndex:rowIndex];
  return !([data isKindOfClass:[NSString class]]);
}

- (float)tableView:(NSTableView *)tableView heightOfRow:(int)row {
//	double defaultRowHeight = [tableView rowHeight];
//	id data = [displaySearchhelp objectAtIndex:row];
//	NSAttributedString *as = [self searchhelpAttributedStringForRow:row];
/*	NSLog(@"rect: %@ for size: %@ of row: %@",
      NSStringFromRect([as boundingRectWithSize:NSMakeSize(NSWidth([tableView frame]),90000.0)
options:(NSStringDrawingUsesDeviceMetrics & NSStringDrawingUsesFontLeading)]),
      NSStringFromSize(NSMakeSize(NSWidth([tableView frame]),90000.0)),
      [as string]);///
  return [self searchhelpHeightForRow:row];
//	return [as size].height;
}
*/
#pragma mark -
#pragma mark Dealloc

/* dealloc */
- (void)dealloc {
  [self setController:nil];
  [super dealloc];
}

@end
