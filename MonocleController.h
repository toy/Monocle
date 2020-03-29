/* MonocleController */

#import <Cocoa/Cocoa.h>

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

@class MonocleSearchView, MonocleSearchWindow, MonoclePreferenceController, PTHotKey, MonocleStatusItem;
@interface MonocleController : NSObject {
  MonocleSearchWindow *searchWindow;
  IBOutlet MonocleSearchView *searchView;
  MonoclePreferenceController *prefController;
  PTHotKey *globalHotKey;
  IBOutlet MonocleStatusItem *statusItem;
}

+ (MonocleController *)controller;

- (IBAction)openMonocleWebsite:(id)sender;

- (IBAction)bringUp:(id)sender;
- (IBAction)showPrefs:(id)sender;
- (IBAction)searchWithClipboard:(id)sender;

- (void)selectorForNSWindow_setCollectionBehavior:(NSUInteger)behavior;
- (void)prepareWindow:(NSWindow *)window forSpacesUsingCollectionBehavior:(NSUInteger)mode;

- (void)bringUpOrHide;

- (void)hideIfInStatusItem;
- (void)tellSearchViewToBringUp;
- (void)tellSearchViewToHide;
- (void)ready;

- (id)selectedEngine;
- (void)selectEngineWithIndex:(int)idx;

- (void)doReallyEarlyStuff;
- (void)registerDefaultSearchEngines;

- (void)dispatchSearchForQuery:(NSString *)query usingEngine:(id)engine;
- (void)dispatchGETSearchForQuery:(NSString *)query usingEngine:(id)engine;
- (void)dispatchPOSTSearchForQuery:(NSString *)query usingEngine:(id)engine;

- (MonocleSearchWindow *)searchWindow;
- (MonocleSearchView *)searchView;
- (MonocleStatusItem *)statusItem;
- (MonoclePreferenceController *)prefController;

- (NSColor *)deducedColorForEngine:(id)engine;
- (NSColor *)deducedColorForImage:(NSImage *)icon;
- (NSColor *)deducedColorForBitmapImageRep:(NSBitmapImageRep *)bmp;
- (NSColor *)colorForEngine:(id)engine isDeduced:(BOOL *)ded;
//- (NSImage *)genericWebKitSiteIcon;
- (NSImage *)formFittedImageForEngine:(id)engine;
- (NSBitmapImageRep *)bitmapImageRepForImage:(NSImage *)currIcon;
- (NSBitmapImageRep *)bitmapImageRepForEngine:(id)engine;

- (NSArray *)statusItemStyles;
- (NSColor *)customStatusItemColor;
- (NSImage *)imageForStatusItemStyle:(NSDictionary *)style;

- (IBAction)fixGlobalHotKey:(id)sender;

@end

@interface MonocleWashView : NSView {
  IBOutlet MonoclePreferenceController *monoclePreferenceController;
}
@end
