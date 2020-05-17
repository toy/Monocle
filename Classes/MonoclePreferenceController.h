//
//  MonoclePreferenceController.h
//  Monocle
//
//  Created by Jesper on 2006-07-15.
//  Copyright 2006 waffle software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MonocleController, MonocleReorderableArrayController, MonocleEngineArrayController, SRRecorderControl, SUUpdater;

@interface MonoclePreferenceController : NSWindowController {
  IBOutlet NSView *enginesView;
  IBOutlet NSView *searchingView;
  IBOutlet NSView *appearanceView;

  IBOutlet NSPopUpButton *addSpecial;

  IBOutlet NSWindow *mainWindow;

  IBOutlet NSPopUpButton *statusItemStyle;
  IBOutlet NSButton *hasSheenCheckbox;
  NSArray *styles;

  IBOutlet NSTokenField *callwordFormatField;

  IBOutlet SRRecorderControl *hotKeyRecorder;

  IBOutlet NSPanel *editSheet;
  IBOutlet NSPanel *discoverSheet;
  IBOutlet NSPanel *addSheet;
  IBOutlet NSPanel *searchHelpSheet;

  IBOutlet NSView *addSheetEditingPlaceholder;
  IBOutlet NSView *editSheetEditingPlaceholder;

  IBOutlet NSView *editingView;

  IBOutlet NSUserDefaultsController *udc;
  IBOutlet MonocleEngineArrayController *engineController;
  IBOutlet MonocleReorderableArrayController *searchHelperController;
  IBOutlet MonocleReorderableArrayController *engineSpecificSearchHelperController;

  NSMutableArray *searchHelpers;

  NSMutableArray *engineSpecificSearchHelpers;

  IBOutlet NSTableView *enginesTable;
  IBOutlet NSTableView *searchHelpersTable;
  IBOutlet NSTableView *engineSpecificSearchHelpersTable;

  IBOutlet NSButton *addEngineButton;
  IBOutlet NSButton *removeEngineButton;

  IBOutlet NSButton *helpButton;
  IBOutlet NSView *helpButtonView;

  NSView *currentView;
  NSView *oldView;
  NSArray *views;

  NSViewAnimation *animation;

  NSArray *toolbarChoices;

  NSDictionary *viewHeights;
  NSDictionary *viewForToolbarChoice;
  NSDictionary *labelForToolbarChoice;
  NSDictionary *iconForToolbarChoice;
  NSToolbar *toolbar;

  MonocleController *monocleController;
}

- (void)changePanel:(id)sender;
- (void)setupToolbar;

- (BOOL)suggestFromCountryIsEnabled;
- (NSString *)labelForSuggestFromCountry;

- (void)setMonocleController:(MonocleController *)mc;
- (MonocleController *)monocleController;

- (BOOL)hasAddableSpecialEngines;
- (NSArray *)addableSpecialEngines;

- (IBAction)showDiscoverSheet:(id)sender;
- (IBAction)saveAndCloseDiscoverSheet:(id)sender;
- (IBAction)closeDiscoverSheet:(id)sender;

- (IBAction)removeEngineAfterAsking:(id)sender;

- (IBAction)showEngineSpecificSearchHelpSheet:(id)sender;
- (IBAction)closeEngineSpecificSearchHelpSheet:(id)sender;

- (IBAction)showEditSheet:(id)sender;
- (IBAction)closeEditSheet:(id)sender;

- (IBAction)showAddSheet:(id)sender;
- (IBAction)cancelAddSheet:(id)sender;
- (IBAction)saveAddSheet:(id)sender;

- (IBAction)showHelp:(id)sender;

- (IBAction)statusItemStyleChanged:(id)sender;

- (NSMutableArray *)constructSearchHelpers;
- (NSMutableArray *)constructSearchHelpersForEngine:(id)engine;
- (NSMutableArray *)searchHelpProviders;
- (NSMutableArray *)engineSpecificSearchHelpProviders;
- (void)setSearchHelpProvidersManually:(NSArrayController *)lineup;

- (IBAction)useSpecificSetupChanged:(id)sender;

- (void)setupPostDragDelegate:(id)del;

- (NSIndexSet *)indexSetForEngine:(id)engine;
- (void)markEngineChanged:(id)engine;

- (void)buildStyleMenu;
@end

@interface DragToReorderTableView : NSTableView {
  BOOL mouseIsDown;
  MonocleReorderableArrayController *reorderController;
}
- (void)setReorderableController:(MonocleReorderableArrayController *)controller;
@end
