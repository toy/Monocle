#import "MonocleController.h"
#import "MonocleSearchView.h"
#import "MonocleSearchField.h"
#import "MonocleSearchWindow.h"
#import "MonoclePreferenceController.h"
#import "MonocleFieldEditor.h"
#import "MonocleWashDrawing.h"
#import "MonoclePreferences.h"
#import "MonocleSuggestionProviding.h"

#import "SRCommon.h"
#import "SRRecorderControl.h"
#import "PTHotKeyCenter.h"
#import "PTHotKey.h"

#import "MonocleEncoding.h"

#import "CTGradient.h"

#import "MonocleStatusItem.h"

#import "CocoaAdditions.h"

//#import "MonocleWebKitGenericSiteIconAcquiring.h"

static MonocleController *sharedInstance = nil;

@implementation MonocleController

+ (MonocleController *)controller {
  return sharedInstance;
}

- (id)init {
  self = [super init];
  if (self != nil) {
    [self doReallyEarlyStuff];
  }
  sharedInstance = self;
  return self;
}

#define MonocleSearchWindowDefaultSize NSMakeSize(300.0, 32.0)

- (void)selectorForNSWindow_setCollectionBehavior:(NSUInteger)behavior {
}

- (void)prepareWindow:(NSWindow *)window forSpacesUsingCollectionBehavior:(NSUInteger)mode {
  BOOL allocatedBuffer = NO;
  NSUInteger *bufferPtr = NULL;

  // Also apply Exposé exemption.
  // HIWindowChangeAvailability((HIWindowRef)[window windowRef], kHIWindowExposeHidden, 0);

  [window setCollectionBehavior:mode]; /*

 @try {
   NSInvocation *setSpacesBehaviorInvocation = [NSInvocation invocationWithMethodSignature:[self
 methodSignatureForSelector:@selector(selectorForNSWindow_setCollectionBehavior:)]]; [setSpacesBehaviorInvocation
 setSelector:@selector(setCollectionBehavior:)]; [setSpacesBehaviorInvocation setTarget:window]; bufferPtr = (NSUInteger
 *)malloc(sizeof(NSUInteger)); allocatedBuffer = YES; *bufferPtr = mode; [setSpacesBehaviorInvocation
 setArgument:bufferPtr atIndex:2]; [setSpacesBehaviorInvocation invoke]; } @catch (NSException *ex) {
   ;
 } @finally {
   if (allocatedBuffer) {
     free(bufferPtr);
   }
 }*/
}

- (void)awakeFromNib {
  NSScreen *screenDim = [NSScreen mainScreen];
  NSSize screenSize = [screenDim frame].size;

  NSWindow *whiteWindow = [[NSWindow alloc]
    initWithContentRect:NSMakeRect(0, screenSize.height * 0.25, screenSize.width, screenSize.height * 0.75)
              styleMask:NSBorderlessWindowMask
                backing:NSBackingStoreBuffered
                  defer:NO];
  [whiteWindow setLevel:NSTornOffMenuWindowLevel - 2];
  [whiteWindow setBackgroundColor:[NSColor whiteColor]];
  [whiteWindow setMovableByWindowBackground:YES];
  [whiteWindow retain];
  //	[whiteWindow orderFront:self];

  NSRect searchRect = NSMakeRect(0.0, 0.0, MonocleSearchWindowDefaultSize.width, MonocleSearchWindowDefaultSize.height);

  [searchView setController:self];
  [searchView setFrame:searchRect];

  searchWindow =
    [[MonocleSearchWindow alloc] initWithContentRect:NSMakeRect(-5000, -5000, NSWidth(searchRect), NSHeight(searchRect))
                                           styleMask:NSBorderlessWindowMask
                                             backing:NSBackingStoreBuffered
                                               defer:NO];

  [searchWindow setLevel:NSTornOffMenuWindowLevel - 1];

  //	NSUInteger collectionCanJoinAllSpaces = (1 << 0); // NSWindowCollectionBehaviorCanJoinAllSpaces
  //	NSUInteger collectionTransient = (1 << 3); // NSWindowCollectionBehaviorTransient

  [self prepareWindow:searchWindow
    forSpacesUsingCollectionBehavior:NSWindowCollectionBehaviorMoveToActiveSpace |
    NSWindowCollectionBehaviorTransient];  //(collectionCanJoinAllSpaces | collectionTransient)];

  [searchWindow setIgnoresMouseEvents:NO];
  [searchWindow setOpaque:NO];
  [searchWindow setBackgroundColor:[[NSColor yellowColor] colorWithAlphaComponent:0.2]];  //[NSColor clearColor]]; //
  [searchWindow setContentView:searchView];
  [searchWindow setHasShadow:YES];
  [searchWindow setDelegate:self];

  [searchWindow retain];

  [self fixGlobalHotKey:nil];
}

- (id)selectedEngine {
  return [searchView selectedEngine];
}

- (void)selectEngineWithIndex:(int)idx {
  [searchView selectEngineWithIndex:idx];
}

- (id)windowWillReturnFieldEditor:(NSWindow *)sender toObject:(id)anObject {
  /*	static MonocleFieldEditor *fe = nil;
    if (nil == fe) fe = [[MonocleFieldEditor alloc] init];
    return fe;*/
  return nil;
}

#pragma mark Hub accessors

- (MonocleSearchWindow *)searchWindow {
  return searchWindow;
}
- (MonocleSearchView *)searchView {
  return searchView;
}
- (MonocleStatusItem *)statusItem {
  return statusItem;
}
- (MonoclePreferenceController *)prefController {
  return prefController;
}

#pragma mark -

- (BOOL)folderExistsAtPath:(NSString *)path {
  NSFileManager *fm = [NSFileManager defaultManager];
  BOOL isDir;
  return [fm fileExistsAtPath:path isDirectory:&isDir] && isDir;
}

- (void)registerExtraSuggestionProviders {
  NSString *home = [@"~" stringByExpandingTildeInPath];
  NSString *library = [home stringByAppendingPathComponent:@"Library"];
  NSString *appSupport = [library stringByAppendingPathComponent:@"Application Support"];
  if (![self folderExistsAtPath:appSupport]) return;
  NSString *monocleAppSupport = [appSupport stringByAppendingPathComponent:@"Monocle"];
  if (![self folderExistsAtPath:monocleAppSupport]) {
    [[NSFileManager defaultManager] createDirectoryAtPath:monocleAppSupport attributes:nil];
  }
  NSArray *contents = [[NSFileManager defaultManager] directoryContentsAtPath:monocleAppSupport];
  NSEnumerator *contentsEnumerator = [contents objectEnumerator];
  NSString *fileName;
  //	NSLog(@"%d files in App Support folder", [contents count]);
  while (fileName = [contentsEnumerator nextObject]) {
    //		NSLog(@"candidate: %@", fileName);
    if ([[fileName pathExtension] isEqualToString:@"monoclePlugin"]) {
      if ([fileName hasPrefix:@"."]) {
        NSLog(
          @"INFO! A hidden Monocle plugin, '%@', was found; it was not loaded. Make it visible (remove the dot prefix) to load it.",
          fileName);
        continue;
      }
      NSString *absToFile = [monocleAppSupport stringByAppendingPathComponent:fileName];
      NSBundle *pluginBundle = [NSBundle bundleWithPath:absToFile];
      [pluginBundle load];
      NSString *princClass = [[pluginBundle infoDictionary] objectForKey:@"NSPrincipalClass"];
      if ([princClass isEqualToString:@""]) continue;
      Class c = NSClassFromString(princClass);
      if (c == Nil) {
        NSLog(@"ERROR! NSPrincipalClass in plugin specifies nonexisting class: %@", princClass);
      } else {
        //				NSLog(@"Loaded class: %@", princClass);
        [c self];
        NSLog(@"INFO! Initialized plugin %@", [fileName stringByDeletingPathExtension]);
      }
    }
  }
}

- (void)doReallyEarlyStuff {
  //	[MonocleWebKitGenericSiteIconAcquiring startAcquiringImage];
  [self registerDefaultSearchEngines];
  [MonocleSuggestionProvider initialize];
  [self registerExtraSuggestionProviders];
}

- (void)registerDefaultSearchEngines {
  NSValueTransformer *vt = [NSValueTransformer valueTransformerForName:NSUnarchiveFromDataTransformerName];

  NSImage *google = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Google"
                                                                                            ofType:@"tiff"]];
  NSImage *wikipedia = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Wikipedia"
                                                                                               ofType:@"tiff"]];
  NSImage *bing = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Bing"
                                                                                          ofType:@"tiff"]];
  NSImage *youTube = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"YouTube"
                                                                                             ofType:@"tiff"]];
  NSImage *yahoo = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Yahoo"
                                                                                           ofType:@"tiff"]];

  NSArray *defaultSearchEngines =
    [NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:@"Google",
                                            @"name",
                                            [vt reverseTransformedValue:[google autorelease]],
                                            @"icon",
                                            [vt reverseTransformedValue:[self deducedColorForImage:google]],
                                            @"color",
                                            @"Google Web Search",
                                            @"extraInfo",
                                            @"http://www.google.com/search?ie=utf8&oe=utf8&q=%@",
                                            @"get_URL",
                                            @"g",
                                            @"callword",
                                            @"UTF-8",
                                            @"encoding",
                                            @"GET",
                                            @"type",
                                            nil],
             [NSDictionary dictionaryWithObjectsAndKeys:@"Wikipedia",
                           @"name",
                           [vt reverseTransformedValue:[wikipedia autorelease]],
                           @"icon",
                           [vt reverseTransformedValue:[self deducedColorForImage:wikipedia]],
                           @"color",
                           @"The open encyclopedia",
                           @"extraInfo",
                           @"http://en.wikipedia.org/wiki/Special:Search?search=%@&go=Go",
                           @"get_URL",
                           //			@"underscore", @"get_transmutation",
                           @"w",
                           @"callword",
                           @"UTF-8",
                           @"encoding",
                           @"GET",
                           @"type",
                           nil],
             [NSDictionary dictionaryWithObjectsAndKeys:@"Bing",
                           @"name",
                           [vt reverseTransformedValue:[bing autorelease]],
                           @"icon",
                           [vt reverseTransformedValue:[self deducedColorForImage:bing]],
                           @"color",
                           @"Bing Web Search",
                           @"extraInfo",
                           @"http://www.bing.com/search?q=%@",
                           @"get_URL",
                           @"b",
                           @"callword",
                           @"UTF-8",
                           @"encoding",
                           @"GET",
                           @"type",
                           nil],
             [NSDictionary dictionaryWithObjectsAndKeys:@"Yahoo!",
                           @"name",
                           [vt reverseTransformedValue:[yahoo autorelease]],
                           @"icon",
                           [vt reverseTransformedValue:[self deducedColorForImage:yahoo]],
                           @"color",
                           @"Yahoo! Search",
                           @"extraInfo",
                           @"http://search.yahoo.com/search?p=%@&ei=UTF-8",
                           @"get_URL",
                           @"y",
                           @"callword",
                           @"UTF-8",
                           @"encoding",
                           @"GET",
                           @"type",
                           nil],
             [NSDictionary dictionaryWithObjectsAndKeys:@"YouTube",
                           @"name",
                           [vt reverseTransformedValue:[youTube autorelease]],
                           @"icon",
                           [vt reverseTransformedValue:[self deducedColorForImage:youTube]],
                           @"color",
                           @"YouTube Video Search",
                           @"extraInfo",
                           @"http://www.youtube.com/results?search_query=%@",
                           @"get_URL",
                           @"yt",
                           @"callword",
                           @"UTF-8",
                           @"encoding",
                           @"GET",
                           @"type",
                           nil],
             nil];

  [MonoclePreferences registerDefaultPreferences:[NSDictionary dictionaryWithObjectsAndKeys:defaultSearchEngines,
                                                               @"engines",
                                                               [NSNumber numberWithBool:YES],
                                                               @"emptiesSearchFieldBetweenSearches",
                                                               nil]];
}

- (IBAction)openMonocleWebsite:(id)sender {
  [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://wafflesoftware.net/monocle/"]];
}

- (IBAction)bringUp:(id)sender {
  [statusItem bringUp];
}

- (void)bringUpOrHide {
  [statusItem bringUpOrHide];
}

- (void)ready {
  [searchView ready];
}

- (void)tellSearchViewToHide {
  [searchView whenHiding];
}

- (void)tellSearchViewToBringUp {
  [searchView bringUp];
}

- (void)hideIfInStatusItem {
  //	NSLog(@"hide if in status item");
  [statusItem hide];
}

- (IBAction)showPrefs:(id)sender {
  if (prefController) {
    [[prefController window] makeKeyAndOrderFront:self];
    return;
  }
  prefController = [[MonoclePreferenceController alloc] init];
  [prefController setMonocleController:self];
  [NSBundle loadNibNamed:@"SearchingPrefs" owner:prefController];
  [prefController setupPostDragDelegate:searchView];
}

- (IBAction)searchWithClipboard:(id)sender {
  NSPasteboard *pb = [NSPasteboard pasteboardWithName:NSFindPboard];
  NSArray *types = [pb types];
  NSString *q = nil;

  NSLog(@"types: %@", types);

  // Use plain text NSStrings as is, and stupefy RTF and HTML

  if ([types containsObject:NSStringPboardType]) {
    q = [[pb stringForType:NSStringPboardType] retain];
  } else if ([types containsObject:NSHTMLPboardType]) {
    NSTextStorage *ts = [[NSTextStorage alloc] initWithHTML:[pb dataForType:NSRTFPboardType] documentAttributes:NULL];
    q = [[ts string] retain];
    [ts release];
  } else if ([types containsObject:NSRTFPboardType]) {
    NSTextStorage *ts = [[NSTextStorage alloc] initWithRTF:[pb dataForType:NSRTFPboardType] documentAttributes:NULL];
    q = [[ts string] retain];
    [ts release];
  } else if ([types containsObject:NSRTFDPboardType]) {
    NSTextStorage *ts = [[NSTextStorage alloc] initWithRTFD:[pb dataForType:NSRTFDPboardType] documentAttributes:NULL];
    q = [[ts string] retain];
    [ts release];
  }

  [searchView setSearchText:[q autorelease]];
  [searchView nudge];
  [self bringUp:nil];
}

- (NSArray *)searchEngineTypes {
  return [NSArray arrayWithObjects:@"GET search engine", @"POST search engine", nil];
}

- (NSArray *)addableSpecialEngines {
  return [NSArray array];
  //	return [NSArray arrayWithObjects:@"Spotlight", @"Zomg", nil];
}

- (NSString *)escapeString:(NSString *)string usingIANAEncoding:(NSString *)iana {
  NSStringEncoding stringEncoding = [NSString stringEncodingForIANA:iana];
  CFStringEncoding cfstringEncoding = CFStringConvertNSStringEncodingToEncoding(stringEncoding);
  NSString *encodedString = (NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,
    (CFStringRef)string,
    NULL,
    (CFStringRef) @"!*'();:@&=+$,/?%#[]",
    cfstringEncoding);
  return [encodedString autorelease];
}

- (void)dispatchSearchForQuery:(NSString *)query usingEngine:(id)engine {
  if (!engine) return;
  NSString *type = [engine valueForKey:@"type"];
  if (!type) return;
  if ([type isEqualToString:@"GET"]) {
    //		NSLog(@"do GET search using engine %@ for %@", [engine valueForKey:@"name"], query);
    [self dispatchGETSearchForQuery:query usingEngine:engine];

  } else if ([type isEqualToString:@"POST"]) {
    //		NSLog(@"do POST search using engine %@ for %@", [engine valueForKey:@"name"], query);
    [self dispatchPOSTSearchForQuery:query usingEngine:engine];
  }
}

- (void)dispatchGETSearchForQuery:(NSString *)query usingEngine:(id)engine {
  NSString *getURL = [engine valueForKey:@"get_URL"];
  if (!getURL) return;
  if ([[getURL stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""])
    return;
  //	NSLog(@"GET URL: %@", getURL);
  if ([[getURL componentsSeparatedByString:@"%@"] count] != 2) {
    //		NSLog(@"GET URL contains no or two or more %@s.", @"%@");
    return;
  }
  NSString *iana = [engine valueForKey:@"encoding"];
  if (iana == nil) iana = MonocleSearchEngineDefaultEncoding;
  NSString *q = query;
  if ([[engine valueForKey:@"get_transmutation"] isEqualToString:@"underscore"]) {
    q = [[query componentsSeparatedByString:@" "] componentsJoinedByString:@"_"];
  }
  NSString *percentEscapedQuery = [self escapeString:q usingIANAEncoding:iana];
  NSString *urlToLaunch = [[getURL componentsSeparatedByString:@"%@"] componentsJoinedByString:percentEscapedQuery];

  //	NSLog(@"would GET %@", urlToLaunch);

  [searchView searchLaunched];

  NSWorkspace *wks = [NSWorkspace sharedWorkspace];
  [wks openURL:[NSURL URLWithString:urlToLaunch]];

  //	NSLog(@"dispatched GET search using engine %@ for %@", [engine valueForKey:@"name"], query);
}

- (void)dispatchPOSTSearchForQuery:(NSString *)query usingEngine:(id)engine {
  NSString *getURL = [engine valueForKey:@"get_URL"];
  if (!getURL) return;
  if ([[getURL stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""])
    return;
  //	NSLog(@"POST: GET URL: %@", getURL);

  NSString *iana = [engine valueForKey:@"encoding"];
  if (iana == nil) iana = MonocleSearchEngineDefaultEncoding;
  NSStringEncoding enc = [NSString stringEncodingForIANA:iana];

  NSString *q = query;
  if ([[engine valueForKey:@"get_transmutation"] isEqualToString:@"underscore"]) {
    q = [[query componentsSeparatedByString:@" "] componentsJoinedByString:@"_"];
  }
  NSString *percentEscapedQuery = [self escapeString:q usingIANAEncoding:iana];
  NSString *urlToLaunch = [[getURL componentsSeparatedByString:@"%@"] componentsJoinedByString:percentEscapedQuery];

  [searchView searchLaunched];

  NSString *MonoclePOSTSearchPageStyle = @"body { font-family: \"Lucida Grande\"; font-size: 12px; }";

  NSString *formHTML = [NSString
    stringWithFormat:
      @"<html><head><title>Monocle POST search for \"%@\"</title><style>%@</style></head><body><form action=\"%@\" id=\"post-form\" accept-charset=\"%@\" method=\"POST\" target=\"_self\">",
    [query stringByHTMLEntityEscaping],
    MonoclePOSTSearchPageStyle,
    urlToLaunch,
    iana];

  NSArray *kvs = [engine valueForKey:@"post_data"];
  //	NSLog(@"kvs: %@", kvs);
  int i;
  for (i = 0; i < [kvs count]; i++) {
    id kv = [kvs objectAtIndex:i];
    //		NSLog(@"kv: %@", kv);
    id k = [[[[kv valueForKey:@"key"] componentsSeparatedByString:@"%@"]
      componentsJoinedByString:[query stringByHTMLEntityEscaping]] stringByReplacingPercentEscapesUsingEncoding:enc];
    id v = [[[[kv valueForKey:@"value"] componentsSeparatedByString:@"%@"]
      componentsJoinedByString:[query stringByHTMLEntityEscaping]] stringByReplacingPercentEscapesUsingEncoding:enc];
    formHTML = [formHTML stringByAppendingFormat:@"<input type=\"hidden\" name=\"%@\" value=\"%@\" />", k, v];
  }

  NSFileManager *fm = [NSFileManager defaultManager];
  BOOL isDir;
  NSString *tmpFolder = [NSHomeDirectory() stringByAppendingPathComponent:@".monocletmp"];
  if (![fm fileExistsAtPath:tmpFolder isDirectory:&isDir]) {
    [fm createDirectoryAtPath:tmpFolder attributes:nil];
  }

  NSValueTransformer *vt = [NSValueTransformer valueTransformerForName:NSUnarchiveFromDataTransformerName];
  NSImage *im = [vt transformedValue:[engine valueForKey:@"icon"]];
  NSString *iconhtml = @"";

  if (im) {
    NSData *tiff = [im TIFFRepresentation];
    NSBitmapImageRep *bit = [[NSBitmapImageRep alloc] initWithData:tiff];
    NSData *png = [bit representationUsingType:NSPNGFileType properties:[NSDictionary dictionary]];
    [bit autorelease];
    NSString *iconpath =
      [tmpFolder stringByAppendingPathComponent:[NSString stringWithFormat:@"%i.png", [engine hash]]];
    [png writeToFile:iconpath atomically:YES];
    iconhtml = [NSString stringWithFormat:@"<img src=\"%@\" alt=\"%@\" /> ",
                         [[NSURL fileURLWithPath:iconpath] absoluteString],
                         [[engine valueForKey:@"name"] stringByHTMLEntityEscaping]];
  }

  formHTML = [formHTML
    stringByAppendingFormat:
      @"<script>document.getElementById('post-form').submit();</script><div>Monocle search using %@<b>%@</b>: <input type=\"submit\" value=\"Perform the search for '%@'\" /></div></form></body></html>",
    iconhtml,
    [[engine valueForKey:@"name"] stringByHTMLEntityEscaping],
    [query stringByHTMLEntityEscaping]];

  NSString *tmpFile = [tmpFolder
    stringByAppendingPathComponent:[NSString stringWithFormat:@"monocle-tmp-post-search-%i.html", [formHTML hash]]];
  [formHTML writeToFile:tmpFile atomically:YES encoding:NSUTF8StringEncoding error:NULL];

  NSURL *urlToTempFile = [NSURL fileURLWithPath:tmpFile];
  [[NSWorkspace sharedWorkspace] openURL:urlToTempFile];

  NSDirectoryEnumerator *de = [fm enumeratorAtPath:tmpFolder];
  NSString *fi;
  NSString *ffi;
  while (fi = [de nextObject]) {
    ffi = [tmpFolder stringByAppendingPathComponent:fi];
    NSDate *d = [[fm fileAttributesAtPath:ffi traverseLink:YES] objectForKey:NSFileModificationDate];
    if ([d timeIntervalSinceNow] < -(60.0 * 10.0)) {
      //				NSLog(@"%@ is ripe for deletion", ffi);
      [fm removeFileAtPath:ffi handler:nil];
    }
  }

  //	NSLog(@"dispatched POST search using engine %@ for %@", [engine valueForKey:@"name"], query);
}

- (NSColor *)deducedColorForBitmapImageRep:(NSBitmapImageRep *)bmp {
  NSColor *engineColor = [bmp colorAtX:0 y:0];
  if ([engineColor alphaComponent] < 0.2) engineColor = [NSColor whiteColor];
  return engineColor;
}

- (NSColor *)deducedColorForImage:(NSImage *)icon {
  NSBitmapImageRep *bmp = [self bitmapImageRepForImage:icon];
  return [self deducedColorForBitmapImageRep:bmp];
}

- (NSColor *)deducedColorForEngine:(id)engine {
  NSBitmapImageRep *bmp = [self bitmapImageRepForEngine:engine];
  return [self deducedColorForBitmapImageRep:bmp];
}

- (NSColor *)colorForEngine:(id)engine isDeduced:(BOOL *)ded {
  BOOL deduceColor = YES;
  NSColor *engineColor = nil;

  NSValueTransformer *trf = [NSValueTransformer valueTransformerForName:NSUnarchiveFromDataTransformerName];

  if ([engine valueForKeyPath:@"color"] != nil) {
    if ([engine valueForKeyPath:@"colorSpecified"] == nil)
      ;
    //			NSLog(@"deduce, color specified is nil, %@", [engine valueForKeyPath:@"selection.colorSpecified"]);
    else if (![(NSNumber *)[engine valueForKeyPath:@"colorSpecified"] boolValue])
      ;
    //			NSLog(@"deduce color, specified: %@", [engine valueForKeyPath:@"selection.colorSpecified"]);
    else {
      //			NSLog(@"use specified color");
      engineColor = [trf transformedValue:[engine valueForKeyPath:@"color"]];
      deduceColor = NO;
    }
  }

  //	NSLog(@"engine: %@, deduce color: %d, engine color: %@", [engine valueForKey:@"name"], deduceColor, engineColor);

  if (deduceColor) {
    engineColor = [self deducedColorForEngine:engine];
  }

  if (ded) *ded = deduceColor;

  return engineColor;
}

#define MonocleFormFittingImageSize 16.0

- (NSImage *)formFittedImageForEngine:(id)engine {
  double dim = MonocleFormFittingImageSize;

  NSBitmapImageRep *bmp = [self bitmapImageRepForEngine:engine];
  NSImage *canvas = [[NSImage alloc] initWithSize:NSMakeSize(dim, dim)];

  [[NSGraphicsContext currentContext] saveGraphicsState];
  [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];

  [canvas lockFocus];
  if ([bmp pixelsWide] == [bmp pixelsHigh]) {
    [bmp drawInRect:NSMakeRect(0.0, 0.0, dim, dim)];
  } else {
    NSRect r;
    double w = 0.0;
    double h = 0.0;
    if ([bmp pixelsWide] > [bmp pixelsHigh]) {
      w = dim;
      h = ([bmp size].height) / ([bmp size].width) * dim;
    } else {
      h = dim;
      w = ([bmp size].width) / ([bmp size].height) * dim;
    }
    //		NSLog(@"h: %f, w: %f", h, w);
    r = NSMakeRect((dim - w) / 2.0, (dim - h) / 2.0, dim - (dim - w), dim - (dim - h));
    //		NSLog(@"rect: %@", NSStringFromRect(r));
    [bmp drawInRect:r];
    //		NSRect r = NSMakeRect(,<#float y#>,<#float w#>,<#float h#>)
  }
  [canvas unlockFocus];
  [[NSGraphicsContext currentContext] restoreGraphicsState];

  return [canvas autorelease];
}

- (NSBitmapImageRep *)bitmapImageRepForImage:(NSImage *)currIcon {
  NSImageRep *rep = (NSImageRep *)[[currIcon representations] objectAtIndex:0];
  NSBitmapImageRep *bmp = nil;
  if ([rep isKindOfClass:[NSBitmapImageRep class]])
    bmp = (NSBitmapImageRep *)rep;
  else {
    // Make really sure we get a bitmap rep by making NSBitmapImageRep render a tiff of our rep and then init a new
    // bitmap rep from that
    bmp = [[[NSBitmapImageRep alloc] initWithData:[currIcon TIFFRepresentation]] autorelease];
  }
  return bmp;
}

- (NSBitmapImageRep *)bitmapImageRepForEngine:(id)engine {
  NSValueTransformer *trf = [NSValueTransformer valueTransformerForName:NSUnarchiveFromDataTransformerName];

  NSImage *currIcon = [trf transformedValue:[engine valueForKeyPath:@"icon"]];
  return [self bitmapImageRepForImage:currIcon];
}
/*
- (NSImage *)genericWebKitSiteIcon {
  return [MonocleWebKitGenericSiteIconAcquiring icon];
}*/

#define GRADIENT_LEOPARD_START ([NSColor colorWithCalibratedWhite:150.0 / 255.0 alpha:1.0])
#define GRADIENT_LEOPARD_END ([NSColor colorWithCalibratedWhite:197.0 / 255.0 alpha:1.0])

#define GRADIENT_LEOPARD_PALE_START ([NSColor colorWithCalibratedWhite:207.0 / 255.0 alpha:1.0])
#define GRADIENT_LEOPARD_PALE_END ([NSColor colorWithCalibratedWhite:233.0 / 255.0 alpha:1.0])

- (NSArray *)statusItemStyles {
  return [NSArray
    arrayWithObjects:[NSDictionary
                       dictionaryWithObjectsAndKeys:[self customStatusItemColor], @"color", @"Custom", @"title", nil],
    [NSDictionary dictionaryWithObjectsAndKeys:[CTGradient gradientWithBeginningColor:GRADIENT_LEOPARD_START
                                                                          endingColor:GRADIENT_LEOPARD_END],
                  @"gradient",
                  @"Leopard",
                  @"title",
                  @"YES",
                  @"start",
                  nil],
    [NSDictionary dictionaryWithObjectsAndKeys:[CTGradient gradientWithBeginningColor:GRADIENT_LEOPARD_PALE_START
                                                                          endingColor:GRADIENT_LEOPARD_PALE_END],
                  @"gradient",
                  @"Leopard Pale",
                  @"title",
                  @"YES",
                  @"fallback",
                  nil],
    [NSDictionary dictionaryWithObjectsAndKeys:[[NSColor blackColor] highlightWithLevel:0.2],
                  @"color",
                  @"Charcoal",
                  @"title",
                  @"YES",
                  @"start",
                  nil],
    [NSDictionary
      dictionaryWithObjectsAndKeys:[NSColor alternateSelectedControlColor], @"color", @"Selection", @"title", nil],
    /*		[NSDictionary dictionaryWithObjectsAndKeys:[NSColor colorForControlTint:NSBlueControlTint], @"color",
       @"Blue", @"title", nil], [NSDictionary dictionaryWithObjectsAndKeys:[NSColor
       colorForControlTint:NSGraphiteControlTint], @"color", @"Graphite", @"title", nil],*/

    /*		[NSDictionary dictionaryWithObjectsAndKeys:[[NSColor whiteColor] shadowWithLevel:0.2], @"color",
       @"Off-White", @"title", nil],*/
    [NSDictionary dictionaryWithObjectsAndKeys:[CTGradient aquaNormalGradient],
                  @"gradient",
                  @"Aqua",
                  @"title",
                  @"YES",
                  @"no-sheen",
                  nil],
    [NSDictionary dictionaryWithObjectsAndKeys:[CTGradient aquaSelectedGradient],
                  @"gradient",
                  @"Aqua Selected",
                  @"title",
                  @"YES",
                  @"no-sheen",
                  nil],
    /*		[NSDictionary dictionaryWithObjectsAndKeys:[CTGradient unifiedNormalGradient], @"gradient", @"Unified",
       @"title", nil], [NSDictionary dictionaryWithObjectsAndKeys:[CTGradient unifiedSelectedGradient], @"gradient",
       @"Unified Selected", @"title", nil], [NSDictionary dictionaryWithObjectsAndKeys:[CTGradient
       unifiedDarkGradient], @"gradient", @"Unified Dark", @"title", nil],*/
    nil];
}

- (NSColor *)customStatusItemColor {
  id i = [[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"SearchBarCustomColor"];
  NSColor *c = [[NSColor greenColor] shadowWithLevel:0.313];
  if (nil != i) c = (NSColor *)[NSUnarchiver unarchiveObjectWithData:i];

  return c;
}
- (NSImage *)imageForStatusItemStyle:(NSDictionary *)style {
  NSSize size = NSMakeSize(24.0, 12.0);
  NSImage *im = [[NSImage alloc] initWithSize:size];
  NSRect rect = NSMakeRect(0.0, 0.0, size.width, size.height);

  [im lockFocus];
  if ([style objectForKey:@"color"]) {
    NSColor *c = (NSColor *)[style objectForKey:@"color"];
    [MonocleWashDrawing drawBackgroundWash:[CTGradient gradientWithBeginningColor:c endingColor:c] inFrame:rect];
  } else if ([style objectForKey:@"gradient"]) {
    CTGradient *g = (CTGradient *)[style objectForKey:@"gradient"];
    [g fillRect:rect angle:90.0];
  }
  [[[NSColor blackColor] colorWithAlphaComponent:0.3] setStroke];
  [NSBezierPath strokeRect:rect];
  [im unlockFocus];

  return [im autorelease];
}

- (IBAction)fixGlobalHotKey:(id)sender {
  if (globalHotKey != nil) {
    [[PTHotKeyCenter sharedCenter] unregisterHotKey:globalHotKey];
    [globalHotKey release];
    globalHotKey = nil;
  }
  PTKeyCombo *ptkc;
  if (sender) {
    SRRecorderControl *shortcutRecorder = sender;
    if (!SRStringForKeyCode([shortcutRecorder keyCombo].code)) return;
    ptkc = [PTKeyCombo keyComboWithKeyCode:[shortcutRecorder keyCombo].code
                                 modifiers:[shortcutRecorder cocoaToCarbonFlags:[shortcutRecorder keyCombo].flags]];
  } else {
    NSString *defaultsKey = @"ShortcutRecorder SearchHotKey";

    id values = [[NSUserDefaultsController sharedUserDefaultsController] values];
    NSDictionary *savedCombo = [values valueForKey:defaultsKey];
    if (!savedCombo) return;

    signed short keyCode = [[savedCombo valueForKey:@"keyCode"] shortValue];
    unsigned int flags = [[savedCombo valueForKey:@"modifierFlags"] unsignedIntValue];

    // There was *something* saved, but it's basically null, so let's return.
    if (!SRStringForKeyCode(keyCode) || flags == 0) return;

    ptkc = [PTKeyCombo keyComboWithKeyCode:keyCode modifiers:SRCocoaToCarbonFlags(flags)];
  }

  globalHotKey = [[PTHotKey alloc] initWithIdentifier:@"MonocleHotKey" keyCombo:ptkc];

  [globalHotKey setTarget:self];
  [globalHotKey setAction:@selector(hitHotKey:)];

  [[PTHotKeyCenter sharedCenter] registerHotKey:globalHotKey];
}

- (void)hitHotKey:(PTHotKey *)hotKey {
  [self bringUpOrHide];
}

- (void)applicationDidBecomeActive:(NSNotification *)aNotification {
  [searchView appBecameActive];
}

- (void)applicationDidResignActive:(NSNotification *)aNotification {
  [self hideIfInStatusItem];
}

/* dealloc */
- (void)dealloc {
  [super dealloc];
}

@end

@implementation MonocleWashView : NSView

- (id)initWithFrame:(NSRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

    [nc addObserver:self selector:@selector(refreshWashView:) name:@"SearchBarStyleChanged" object:nil];

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
  else
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)refreshWashView:(NSNotification *)noti {
  [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)rect {
  // NSSize whole = [self visibleRect].size;
  // NSSize asked = rect.size;
  // if (!NSEqualSizes(whole,asked)) { [self display]; return; }

  [MonocleWashDrawing drawCurrentWashInRect:rect];

  [[[NSColor blackColor] colorWithAlphaComponent:0.3] setStroke];
  [NSBezierPath strokeRect:rect];
}

@end
