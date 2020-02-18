/* LoadController */

#import <Cocoa/Cocoa.h>

@class HTML5Parser, MonocleEngineArrayController, WebView, WebFrame;

@interface LoadController : NSWindowController
{
    IBOutlet NSImageView *pageIcon;
	IBOutlet NSTextField *searchEngine;
//	IBOutlet NSSegmentedControl *backNext;
//	IBOutlet NSSegmentedControl *stopReload;
    IBOutlet WebView *webView;
	
	NSURL *currentURL;
	
	IBOutlet NSPopUpButton *cogMenuButton;
	IBOutlet NSMenuItem *reloadMenuItem;
	IBOutlet NSMenuItem *stopMenuItem;
	
	IBOutlet NSButton *addButton;
	IBOutlet NSTextField *discVerbIndicator;
	IBOutlet NSTextField *discSearchURL;
    IBOutlet NSImageView *discPageIcon;
	IBOutlet NSTextField *discSearchEngine;
	IBOutlet NSPopUpButton *discoveredEnginesPopup;
	
	IBOutlet NSArrayController *discoveredEnginesArrayController;
	
	IBOutlet MonocleEngineArrayController *engineController;
	
	IBOutlet NSTextField *urlField;
	
	IBOutlet HTML5Parser *advancedParser;
	
	NSMutableArray *discoveredEngines;
	NSMutableSet *takenURLs;
	unsigned counter;
	
	NSImage *blankImage;
	
	NSString *mycroftEncodingName;
	
	NSImage *cmycroftImage;
	NSURL *cmycroftImageURL;
	NSURL *cmycroftSearchURL;
}

- (IBAction)segControlClicked:(id)sender;
- (IBAction)addClicked:(id)sender;
- (IBAction)goToWebsite:(id)sender;
- (IBAction)selectLoc:(id)sender;

- (IBAction)showInstructions:(id)sender;

- (void)startStuff;

- (BOOL)anyEnginesDetected;
- (BOOL)canRemove;

- (void)saveEngines;
- (void)closing;

- (IBAction)deleteSelectedEngines:(id)sender;

- (void)tryToDiscoverSearchEngineForFrame:(WebFrame *)frame;
- (NSString *)figureOutEngineName:(NSString *)title;

- (NSString *)ianaEncodingForFrame:(WebFrame *)frame;

- (void) addDiscoveredEngine:(NSString *)title icon:(NSImage *)icon url:(NSString *)url postData:(NSDictionary *)postData ianaEncoding:(NSString *)enc;
- (BOOL)tryToDiscoverSearchEngineFromSubmittedForm:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame;
- (void) rebuildDiscoveredEnginesPopup;
- (IBAction) viewEngineInfo:(id)sender;
@end
