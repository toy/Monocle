//
//  MonocleSuggestionProviding.m
//  Monocle
//
//  Created by Jesper on 2006-07-26.
//  Copyright 2006 waffle software. All rights reserved.
//

#import "MonocleSuggestionProviding.h"
#import "HTML5Parser.h"
#import "HTMLLikeTag.h"

#import "MonoclePreferences.h"

#import "GTMNSString+HTML.h"

#import "NSDictionary+BSJSONAdditions.h"

@implementation MonocleSuggestion
- (NSString *)suggestion {
  return suggestion;
}
- (void)setSuggestion:(NSString *)newSuggestion {
  if (suggestion != newSuggestion) {
    [suggestion release];
    suggestion = [newSuggestion copy];
  }
}

+ (MonocleSuggestion *)suggestionWithString:(NSString *)sugg {
  MonocleSuggestion *s = [[MonocleSuggestion alloc] init];
  [s setSuggestion:sugg];
  return [s autorelease];
}

- (NSString *)jsonRepresentation {
  return [[NSDictionary dictionaryWithObject:suggestion forKey:@"suggestion"] jsonStringValue];
}

- (id)copyWithZone:(NSZone *)zone {
  return NSCopyObject(self, 0, zone);
}
@end

@implementation MonocleResult
- (NSString *)title {
  return title;
}
- (void)setTitle:(NSString *)newTitle {
  if (title != newTitle) {
    [title release];
    title = [newTitle copy];
  }
}

- (NSString *)description {
  return description;
}
- (void)setDescription:(NSString *)newDescription {
  if (description != newDescription) {
    [description release];
    description = [newDescription copy];
  }
}

- (NSString *)location {
  return location;
}
- (void)setLocation:(NSString *)newLocation {
  if (location != newLocation) {
    [location release];
    location = [newLocation copy];
  }
}

- (NSString *)url {
  return url;
}
- (void)setUrl:(NSString *)newUrl {
  if (url != newUrl) {
    [url release];
    url = [newUrl copy];
  }
}

- (NSString *)jsonRepresentation {
  NSDictionary *dict = [NSDictionary
    dictionaryWithObjectsAndKeys:title, @"title", description, @"description", location, @"location", url, @"url", nil];
  return [dict jsonStringValue];
}

- (id)copyWithZone:(NSZone *)zone {
  return NSCopyObject(self, 0, zone);
}
@end

@interface NSString (StringByResolvingJavascriptEscapes)
- (NSString *)stringByResolvingJavascriptEscapes;
@end

@implementation NSString (StringByResolvingJavascriptEscapes)
- (NSString *)stringByResolvingJavascriptEscapes {
  NSScanner *scannerForMe = [NSScanner scannerWithString:self];
  [scannerForMe setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@""]];
  NSMutableString *stringToKeep = [@"" mutableCopy];
  NSString *str = nil;

  NSCharacterSet *octalDigits = [NSCharacterSet characterSetWithCharactersInString:@"01234567"];

  NSCharacterSet *simpleEscapes =
    [NSCharacterSet characterSetWithCharactersInString:@"\\\"'bfnrt"];  // \, ", ', [bfnrt]
  NSDictionary *simpleEscapeMap = [NSDictionary
    dictionaryWithObjectsAndKeys:
      @"\\", @"\\", @"\"", @"\"", @"'", @"'", @"\b", @"b", @"\f", @"f", @"\n", @"n", @"\r", @"r", @"\t", @"t", nil];
  do {
    [scannerForMe scanUpToString:@"\\" intoString:&str];
    if (str != nil) {
      [stringToKeep appendString:str];
      if ([scannerForMe isAtEnd]) break;
      [scannerForMe scanString:@"\\" intoString:NULL];
      unsigned loc = [scannerForMe scanLocation];
      NSString *telltale = [self substringWithRange:NSMakeRange(loc, 1)];
      unichar telltaleUnichar = [telltale characterAtIndex:0];
      if ([simpleEscapes characterIsMember:telltaleUnichar]) {
        //				NSLog(@"character is telltale unichar: %@", telltale);
        [stringToKeep appendString:[simpleEscapeMap objectForKey:telltale]];
        //				NSLog(@"scanner location: %d, string length: %d", loc, [self length]);
        [scannerForMe setScanLocation:loc + 1];
      } else if ([telltale isEqualToString:@"x"]) {
        if ([self length] >= loc + 3) {
          NSString *hexpair = [self substringWithRange:NSMakeRange(loc + 1, 2)];
          unsigned actualHex = INT_MAX;
          [[NSScanner scannerWithString:hexpair] scanHexInt:&actualHex];
          if (actualHex != INT_MAX) {
            unichar charact = (unichar)actualHex;
            [stringToKeep appendString:[NSString stringWithCharacters:&charact length:1]];
          }
          [scannerForMe setScanLocation:loc + 3];
        }
      } else if ([telltale isEqualToString:@"u"]) {
        if ([self length] >= loc + 5) {
          NSString *uhexpair = [self substringWithRange:NSMakeRange(loc + 1, 4)];
          unsigned actualuHex = INT_MAX;
          [[NSScanner scannerWithString:uhexpair] scanHexInt:&actualuHex];
          if (actualuHex != INT_MAX) {
            unichar ucharact = (unichar)actualuHex;
            [stringToKeep appendString:[NSString stringWithCharacters:&ucharact length:1]];
          }
          [scannerForMe setScanLocation:loc + 5];
        }
      } else if ([octalDigits characterIsMember:telltaleUnichar]) {
        if ([self length] >= loc + 3) {
          NSString *octalzeroth = [self substringWithRange:NSMakeRange(loc + 2, 1)];
          NSString *octalfirst = [self substringWithRange:NSMakeRange(loc + 1, 1)];
          NSString *octalsecond = telltale;
          int octalvalue = ([octalzeroth intValue] + ([octalfirst intValue] * 8) + ([octalsecond intValue] * 64));
          unichar ocharact = (unichar)octalvalue;
          [stringToKeep appendString:[NSString stringWithCharacters:&ocharact length:1]];
          [scannerForMe setScanLocation:loc + 3];
        }
      } else {
        [stringToKeep appendString:telltale];
        [scannerForMe setScanLocation:loc + 1];
      }
    } else {
      break;
    }
  } while (YES);
  return [stringToKeep autorelease];
}
@end

@interface NSScanner (QuotedStringAdditions)
- (BOOL)scanQuotedStringIntoString:(NSString **)into;
@end

@implementation NSScanner (QuotedStringAdditions)
- (BOOL)scanQuotedStringIntoString:(NSString **)into {
  NSString *returnableString = @"";
  [self scanString:@"\"" intoString:NULL];
  //	NSLog(@"scanned initial quote");
  NSString *q = nil;
  BOOL wasEscapedQuote;
  do {
    wasEscapedQuote = NO;
    [self scanUpToString:@"\"" intoString:&q];
    if (q == nil) q = @"";
    //		NSLog(@"scanned up to next quote (%@)", q);
    if ([q characterAtIndex:[q length] - 1] == '\\') {
      //			NSLog(@"last char is an escape - \\");
      q = [[q substringToIndex:[q length] - 1] stringByAppendingString:@"\""];
      [self scanString:@"\"" intoString:NULL];
      wasEscapedQuote = YES;
      //			NSLog(@"doing this again soon");
    }
    returnableString = [returnableString stringByAppendingString:q];
    //		NSLog(@"appended what's been scanned: returnable string is now %@", returnableString);
  } while (wasEscapedQuote);
  returnableString = [returnableString stringByResolvingJavascriptEscapes];
  [self scanString:@"\"" intoString:NULL];
  if (into) {
    *into = returnableString;
  }
  return YES;
}
@end

@implementation MonocleSuggestionProvider

static NSMutableSet *providers = nil;
static NSMutableSet *suggestionProviders = nil;
static NSMutableSet *resultProviders = nil;

static NSMutableDictionary *cachedSuggestions = nil;
static NSMutableDictionary *cachedResults = nil;
static NSMutableDictionary *cachedResultsSuggestions = nil;
static NSMutableArray *vendorIdentifiers = nil;
static NSMutableArray *providerIdentifiers = nil;

static BOOL initalizedAlready = NO;

+ (NSString *)vendorIdentifier {
  return nil;
}

+ (void)initialize {
  if (self == [MonocleSuggestionProvider class]) {
    if (initalizedAlready) return;

    providers = [[NSMutableSet set] retain];
    suggestionProviders = [[NSMutableSet set] retain];
    resultProviders = [[NSMutableSet set] retain];

    providerIdentifiers = [[NSMutableArray array] retain];
    vendorIdentifiers = [[NSMutableArray array] retain];

    cachedSuggestions = [[NSMutableDictionary dictionary] retain];
    cachedResults = [[NSMutableDictionary dictionary] retain];
    cachedResultsSuggestions = [[NSMutableDictionary dictionary] retain];

    [NSTimer scheduledTimerWithTimeInterval:0.02
                                     target:self
                                   selector:@selector(registerKnownVendors:)
                                   userInfo:nil
                                    repeats:NO];
    initalizedAlready = YES;
  } else {
    [MonocleSuggestionProvider registerProviderVendor:self];
  }
}

+ (NSDictionary *)providers {
  return [NSDictionary dictionaryWithObjectsAndKeys:suggestionProviders, @"s", resultProviders, @"r", nil];
}

+ (NSArray *)providerIdentifiers {
  return [[providerIdentifiers copy] autorelease];
}

+ (void)registerKnownVendors:(NSTimer *)t {
  //	[MonocleSuggestionProviderFromSpellChecker initialize];
  [MonocleSuggestionProviderFromGoogle initialize];
}

+ (void)registerProviderVendor:(Class)providerVendor {
  //	NSLog(@"Registering provider vendor class: %@", NSStringFromClass(providerVendor));
  NSValue *vendorValue = [NSValue value:providerVendor withObjCType:@encode(Class)];
  if ([providers containsObject:vendorValue]) return;
  NSAssert1(([providerVendor respondsToSelector:@selector(providesResults)] &&
              [providerVendor respondsToSelector:@selector(providesSuggestions)]),
    @"ERROR! The class %@ is not a valid provider vendor.",
    NSStringFromClass(providerVendor));
  NSString *vendorIdentifier = [providerVendor vendorIdentifier];
  if ([vendorIdentifiers containsObject:vendorIdentifier]) {
    NSLog(@"ERROR! Class %@ tried to register the provider vendor identifier %@ a second time.",
      NSStringFromClass(providerVendor),
      vendorIdentifier);
    return;
  } else if (vendorIdentifier == nil) {
    NSLog(@"ERROR! Class %@ provides a nil provider vendor identifier.", NSStringFromClass(providerVendor));
    return;
  } else {
    [vendorIdentifiers addObject:vendorIdentifier];
  }
  /*	NSAssert1(([providerVendor vendorIdentifier] != nil),
          @"The class %@ is a valid provider vendor but does not provide a valid vendorIdentifier.",
     NSStringFromClass(providerVendor));*/
  if ([providerVendor providesResults]) {
    id<MonocleResultProviding> rp = [providerVendor resultProvider];
    if (rp == nil) {
      NSLog(@"ERROR! Class %@ claims to support providing results, but provides a nil result provider.",
        NSStringFromClass(providerVendor));
      return;
    }
    if (![resultProviders containsObject:rp]) {
      [resultProviders addObject:rp];
      [providerIdentifiers addObject:[rp resultsSourceIdentifier]];
    }

    NSLog(@"INFO! Registered result provider: %@", [rp resultsSource]);
  }
  if ([providerVendor providesSuggestions]) {
    id<MonocleSuggestionProviding> sp = [providerVendor suggestionProvider];
    if (sp == nil) {
      NSLog(@"ERROR! Class %@ claims to support providing suggestions, but provides a nil suggestion provider.",
        NSStringFromClass(providerVendor));
      return;
    }
    if (![suggestionProviders containsObject:sp]) {
      [suggestionProviders addObject:sp];
      [providerIdentifiers addObject:[sp suggestionsSourceIdentifier]];
    }

    NSLog(@"INFO! Registered suggestion provider: %@", [sp suggestionsSource]);
  }
  [providers addObject:vendorValue];
}

#define MONOCLERESULTCACHETIMEOUT (60.0 * 10.0)

+ (NSArray *)orderedEnabledIdentifiers {
  NSArray *order = [MonoclePreferences arrayForKey:@"SearchHelpProvidersOrder" orDefault:providerIdentifiers];
  NSArray *enabledProviders = [MonoclePreferences arrayForKey:@"SearchHelpProvidersEnabled"
                                                    orDefault:providerIdentifiers];

  NSMutableArray *list = [[NSMutableArray array] retain];

  NSEnumerator *helperEnumerator = [order objectEnumerator];
  NSString *identifier;
  while (identifier = [helperEnumerator nextObject]) {
    if ([enabledProviders containsObject:identifier]) [list addObject:identifier];
  }
  return [list autorelease];
}

+ (NSArray *)orderedEnabledIdentifiersForEngine:(id)engine {
  if (engine == nil) return [self orderedEnabledIdentifiers];

  id useSpecificSetup = [engine valueForKey:@"searchHelpUseSpecificSetup"];
  if (useSpecificSetup == nil || [(NSNumber *)useSpecificSetup boolValue] == NO) {
    return [self orderedEnabledIdentifiers];
  }

  NSArray *defaultOrder = [MonoclePreferences arrayForKey:@"SearchHelpProvidersOrder" orDefault:providerIdentifiers];
  NSArray *defaultProviders = [MonoclePreferences arrayForKey:@"SearchHelpProvidersEnabled"
                                                    orDefault:providerIdentifiers];

  NSArray *orderFromEngine = [engine valueForKey:@"searchHelpProvidersOrder"];
  NSArray *order = (orderFromEngine == nil ? defaultOrder : orderFromEngine);
  NSArray *enabledProvidersFromEngine = [engine valueForKey:@"searchHelpProvidersEnabled"];
  NSArray *enabledProviders = (enabledProvidersFromEngine == nil ? defaultProviders : enabledProvidersFromEngine);

  NSMutableArray *list = [[NSMutableArray array] retain];

  NSEnumerator *helperEnumerator = [order objectEnumerator];
  NSString *identifier;
  while (identifier = [helperEnumerator nextObject]) {
    if ([enabledProviders containsObject:identifier]) [list addObject:identifier];
  }
  return [list autorelease];
}

+ (void)findOutResults:(NSDictionary *)context {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

  unsigned int job = [[context objectForKey:@"job"] unsignedIntValue];
  NSString *string = [context objectForKey:@"string"];

  id delegate = [context objectForKey:@"delegate"];

  id<MonocleResultProviding> res = (id<MonocleResultProviding>)[context objectForKey:@"result"];
  NSArray *results = [self resultsForString:string fromResultProvider:res];

  //	NSLog(@"[%d] %@ found out %d results for %@", job, [res resultsSourceIdentifier], [results count], string);
  [delegate
    resultsSuggestions:[NSArray arrayWithObjects:[res resultsSource], [res resultsSourceIdentifier], results, nil]
          fromProvider:[res resultsSourceIdentifier]
                forJob:job];

  [pool release];
}

+ (void)launchURLinBrowser:(NSURL *)url {
  [[NSWorkspace sharedWorkspace] openURL:url];
}

+ (BOOL)openResult:(NSString *)result usingProviderWithIdentifier:(NSString *)identifier {
  NSEnumerator *resultsProviderEnumerator = [resultProviders objectEnumerator];
  id<MonocleResultProviding> resultsProvider;
  while (resultsProvider = [resultsProviderEnumerator nextObject]) {
    if ([[resultsProvider resultsSourceIdentifier] isEqualToString:identifier]) {
      return [resultsProvider openResult:result];
    }
  }
  return NO;
}

+ (void)findOutSuggestions:(NSDictionary *)context {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

  unsigned int job = [[context objectForKey:@"job"] unsignedIntValue];
  NSString *string = [context objectForKey:@"string"];

  id delegate = [context objectForKey:@"delegate"];

  id<MonocleSuggestionProviding> sugg = (id<MonocleSuggestionProviding>)[context objectForKey:@"suggestion"];
  NSArray *suggs = [self suggestionsForString:string fromSuggestionProvider:sugg];

  //	NSLog(@"[%d] %@ found out %d suggestions for %@", job, [sugg suggestionsSourceIdentifier], [suggs count], string);
  [delegate
    resultsSuggestions:[NSArray
                         arrayWithObjects:[sugg suggestionsSource], [sugg suggestionsSourceIdentifier], suggs, nil]
          fromProvider:[sugg suggestionsSourceIdentifier]
                forJob:job];

  [pool release];
}

+ (NSArray *)resultsForString:(NSString *)string fromResultProvider:(id<MonocleResultProviding>)res {
  string = [string stringByTrimmingWhitespace];

  if (nil == string || [string isEqualToString:@""]) return [NSArray array];

  NSString *lookupString = [NSString stringWithFormat:@"%@\t%@", [res resultsSourceIdentifier], string];

  NSDictionary *cr = nil;
  if ((cr = [[cachedResults objectForKey:lookupString] retain]) != nil) {
    NSDate *expire = [cr objectForKey:@"expire"];

    if ([[NSDate date] laterDate:expire] == expire) {
      // NSLog(@"isn't expired");
      NSArray *cres = [cr objectForKey:@"cache"];
      NSMutableDictionary *mcr = [[cr mutableCopy] autorelease];
      [mcr setObject:[[NSDate date] addTimeInterval:MONOCLERESULTCACHETIMEOUT] forKey:@"expire"];
      [cachedResults setObject:mcr forKey:lookupString];
      [cr release];
      // NSLog(@"returning %d results", [cres count]);
      return cres;
    } else {
      [cr release];
    }
  }

  NSArray *results = [res resultsForString:string];
  NSDictionary *tcr = [NSDictionary dictionaryWithObjectsAndKeys:results,
                                    @"cache",
                                    [[NSDate date] addTimeInterval:MONOCLERESULTCACHETIMEOUT],
                                    @"expire",
                                    nil];

  [cachedResults setObject:tcr forKey:lookupString];

  return results;
}

+ (NSArray *)suggestionsForString:(NSString *)string fromSuggestionProvider:(id<MonocleSuggestionProviding>)sugg {
  string = [string stringByTrimmingWhitespace];

  if (nil == string || [string isEqualToString:@""]) return [NSArray array];

  NSString *lookupString = [NSString stringWithFormat:@"%@\t%@", [sugg suggestionsSourceIdentifier], string];

  NSDictionary *cs = nil;
  if ((cs = [[cachedSuggestions objectForKey:lookupString] retain]) != nil) {
    NSDate *expire = [cs objectForKey:@"expire"];
    if ([[NSDate date] laterDate:expire] == expire) {
      // NSLog(@"isn't expired");
      NSArray *csugg = [cs objectForKey:@"cache"];
      NSMutableDictionary *mcs = [[cs mutableCopy] autorelease];
      [mcs setObject:[[NSDate date] addTimeInterval:MONOCLERESULTCACHETIMEOUT] forKey:@"expire"];
      [cachedSuggestions setObject:mcs forKey:lookupString];
      //			[cr release];
      // NSLog(@"returning %d results", [cres count]);
      [cs release];
      return csugg;
    } else {
      [cs release];
    }
  }

  NSArray *suggestions = [sugg suggestionsForString:string];
  NSDictionary *tcs = [NSDictionary dictionaryWithObjectsAndKeys:suggestions,
                                    @"cache",
                                    [[NSDate date] addTimeInterval:MONOCLERESULTCACHETIMEOUT],
                                    @"expire",
                                    nil];

  [cachedSuggestions setObject:tcs forKey:lookupString];

  return suggestions;
}

+ (void)combinedResultsSuggestionsForString:(NSString *)string
                                     forJob:(unsigned int)job
                                usingEngine:(id)engine
                                   delegate:(id)delegate {
  NSDictionary *context = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:job],
                                        @"job",
                                        string,
                                        @"string",
                                        delegate,
                                        @"delegate",
                                        nil];

  //	NSMutableDictionary *resultsSuggestionsForProvider = [[NSMutableDictionary dictionary] retain];

  NSArray *ordered = [self orderedEnabledIdentifiersForEngine:engine];

  //	NSMutableArray *results = [NSMutableArray array];

  NSEnumerator *resEnumerator = [resultProviders objectEnumerator];
  id<MonocleResultProviding> res;
  while (res = [resEnumerator nextObject]) {
    NSString *resId = [res resultsSourceIdentifier];
    if (![ordered containsObject:resId]) continue;
    NSMutableDictionary *myCtx = [context mutableCopy];
    [myCtx setObject:res forKey:@"result"];
    [NSThread detachNewThreadSelector:@selector(findOutResults:) toTarget:self withObject:myCtx];
    [myCtx release];
  }

  NSEnumerator *sugEnumerator = [suggestionProviders objectEnumerator];
  id<MonocleSuggestionProviding> sug;
  while (sug = [sugEnumerator nextObject]) {
    NSString *sugId = [sug suggestionsSourceIdentifier];
    if (![ordered containsObject:sugId]) continue;
    NSMutableDictionary *myCtx = [context mutableCopy];
    [myCtx setObject:sug forKey:@"suggestion"];
    [NSThread detachNewThreadSelector:@selector(findOutSuggestions:) toTarget:self withObject:myCtx];
    [myCtx release];
  }

  //	NSLog(@"spawned threads");

  /*
  NSEnumerator *orderedEnumerator = [ordered objectEnumerator];
  NSString *orderedId;
  while (orderedId = [orderedEnumerator nextObject]) {
    id ressug = [resultsSuggestionsForProvider objectForKey:orderedId];
    if (ressug) {
      [results addObject:ressug];
    }
  }
   */
}

+ (NSArray *)combinedResultsSuggestionsForString:(NSString *)string {
  string = [string stringByTrimmingWhitespace];

  if (nil == string || [string isEqualToString:@""]) return [NSArray array];

  NSDictionary *cr = nil;
  if ((cr = [[cachedResultsSuggestions objectForKey:string] retain]) != nil) {
    // NSLog(@"has cached entry, %@", [NSThread currentThread]);
    NSDate *expire = [cr objectForKey:@"expire"];
    if ([[NSDate date] laterDate:expire] == expire) {
      // NSLog(@"isn't expired");
      NSArray *cres = [cr objectForKey:@"cache"];
      NSMutableDictionary *mcr = [[cr mutableCopy] autorelease];
      [mcr setObject:[[NSDate date] addTimeInterval:MONOCLERESULTCACHETIMEOUT] forKey:@"expire"];
      [cachedResultsSuggestions setObject:mcr forKey:string];
      [cr release];
      // NSLog(@"returning %d results", [cres count]);
      return cres;
    } else {
      [cr release];
    }
  }

  NSMutableDictionary *resultsSuggestionsForProvider = [NSMutableDictionary dictionary];

  NSArray *ordered = [self orderedEnabledIdentifiers];

  NSMutableArray *results = [NSMutableArray array];

  NSEnumerator *resEnumerator = [resultProviders objectEnumerator];
  id<MonocleResultProviding> res;
  while (res = [resEnumerator nextObject]) {
    NSString *resId = [res resultsSourceIdentifier];
    if (![ordered containsObject:resId]) continue;
    NSArray *r = [res resultsForString:string];
    NSArray *rx = [NSArray arrayWithObjects:[res resultsSource], r, nil];
    //		[results addObject:rx];
    [resultsSuggestionsForProvider setObject:rx forKey:resId];
  }

  NSEnumerator *sugEnumerator = [suggestionProviders objectEnumerator];
  id<MonocleSuggestionProviding> sug;
  while (sug = [sugEnumerator nextObject]) {
    NSString *sugId = [sug suggestionsSourceIdentifier];
    if (![ordered containsObject:sugId]) continue;
    NSArray *s = [sug suggestionsForString:string];
    NSArray *sx = [NSArray arrayWithObjects:[sug suggestionsSource], s, nil];
    //		[results addObject:rx];
    [resultsSuggestionsForProvider setObject:sx forKey:sugId];
  }

  NSEnumerator *orderedEnumerator = [ordered objectEnumerator];
  NSString *orderedId;
  while (orderedId = [orderedEnumerator nextObject]) {
    id ressug = [resultsSuggestionsForProvider objectForKey:orderedId];
    if (ressug) {
      [results addObject:ressug];
    }
  }

  NSDictionary *tcr = [NSDictionary dictionaryWithObjectsAndKeys:results,
                                    @"cache",
                                    [[NSDate date] addTimeInterval:MONOCLERESULTCACHETIMEOUT],
                                    @"expire",
                                    nil];

  [cachedResults setObject:tcr forKey:string];

  return results;
}

+ (NSArray *)combinedResultsForString:(NSString *)string {
  string = [string stringByTrimmingWhitespace];

  if (nil == string || [string isEqualToString:@""]) return [NSArray array];

  NSDictionary *cr = nil;
  if ((cr = [[cachedResults objectForKey:string] retain]) != nil) {
    // NSLog(@"has cached entry, %@", [NSThread currentThread]);
    NSDate *expire = [cr objectForKey:@"expire"];
    if ([[NSDate date] laterDate:expire] == expire) {
      // NSLog(@"isn't expired");
      NSArray *cres = [cr objectForKey:@"cache"];
      NSMutableDictionary *mcr = [[cr mutableCopy] autorelease];
      [mcr setObject:[[NSDate date] addTimeInterval:MONOCLERESULTCACHETIMEOUT] forKey:@"expire"];
      [cachedResults setObject:mcr forKey:string];
      [cr release];
      // NSLog(@"returning %d results", [cres count]);
      return cres;
    } else {
      [cr release];
    }
  }

  NSMutableArray *results = [NSMutableArray array];

  NSEnumerator *resEnumerator = [resultProviders objectEnumerator];
  id<MonocleResultProviding> res;
  while (res = [resEnumerator nextObject]) {
    NSArray *r = [res resultsForString:string];
    NSArray *rx = [NSArray arrayWithObjects:[res resultsSource], r, nil];
    [results addObject:rx];
    // NSLog(@"%d results from %@", [r count], [res resultsSource]);
  }

  NSDictionary *tcr = [NSDictionary dictionaryWithObjectsAndKeys:results,
                                    @"cache",
                                    [[NSDate date] addTimeInterval:MONOCLERESULTCACHETIMEOUT],
                                    @"expire",
                                    nil];

  [cachedResults setObject:tcr forKey:string];

  return results;
}

+ (NSArray *)combinedSuggestionsForString:(NSString *)string {
  string = [string stringByTrimmingWhitespace];

  if (nil == string || [string isEqualToString:@""]) return [NSArray array];

  NSDictionary *cr = nil;
  if ((cr = [[cachedSuggestions objectForKey:string] retain]) != nil) {
    // NSLog(@"has cached entry, %@", [NSThread currentThread]);
    NSDate *expire = [cr objectForKey:@"expire"];

    if ([[NSDate date] laterDate:expire] == expire) {
      // NSLog(@"isn't expired");
      NSArray *cres = [cr objectForKey:@"cache"];
      NSMutableDictionary *mcr = [[cr mutableCopy] autorelease];
      [mcr setObject:[[NSDate date] addTimeInterval:MONOCLERESULTCACHETIMEOUT] forKey:@"expire"];
      [cachedSuggestions setObject:mcr forKey:string];
      [cr release];
      // NSLog(@"returning %d results", [cres count]);
      return cres;
    } else {
      [cr release];
    }
  }

  NSMutableArray *suggestions = [NSMutableArray array];

  NSEnumerator *suggEnumerator = [suggestionProviders objectEnumerator];
  id<MonocleSuggestionProviding> sugg;
  while (sugg = [suggEnumerator nextObject]) {
    NSArray *s = [sugg suggestionsForString:string];
    NSArray *sx = [NSArray arrayWithObjects:[sugg suggestionsSource], s, nil];
    [suggestions addObject:sx];
    // NSLog(@"%d suggestions from %@", [s count], [sugg suggestionsSource]);
  }

  NSDictionary *tcr = [NSDictionary dictionaryWithObjectsAndKeys:suggestions,
                                    @"cache",
                                    [[NSDate date] addTimeInterval:MONOCLERESULTCACHETIMEOUT],
                                    @"expire",
                                    nil];

  [cachedSuggestions setObject:tcr forKey:string];

  return suggestions;
}

- (NSArray *)suggestionsForString:(NSString *)string {
  NSLog(@"suggestionsForString: unimplemented in class %@", [self className]);
  return [NSArray array];
}

- (NSArray *)resultsForString:(NSString *)string {
  NSLog(@"resultsForString: unimplemented in class %@", [self className]);
  return [NSArray array];
}

- (NSString *)suggestionsSourceIdentifier {
  return [NSString stringWithFormat:@"%@.suggestions", [[self class] vendorIdentifier]];
}
- (NSString *)resultsSourceIdentifier {
  return [NSString stringWithFormat:@"%@.results", [[self class] vendorIdentifier]];
}

- (BOOL)openResult:(NSString *)result {
  [MonocleSuggestionProvider launchURLinBrowser:[NSURL URLWithString:result]];
  return YES;
}

+ (id<MonocleSuggestionProviding>)suggestionProvider {
  return nil;
}
+ (id<MonocleResultProviding>)resultProvider {
  return nil;
}

+ (BOOL)providesSuggestions {
  return NO;
}

+ (BOOL)providesResults {
  return NO;
}
@end

@implementation MonocleSuggestionProviderFromSpellChecker
static MonocleSuggestionProviderFromSpellChecker *sharedMonocleSuggestionProviderFromSpellCheckerInstance = nil;

+ (NSString *)vendorIdentifier {
  return @"net.wafflesoftware.Monocle.providers.SystemSpellChecker";
}

+ (id)__sharedInstance {
  if (nil == sharedMonocleSuggestionProviderFromSpellCheckerInstance) {
    sharedMonocleSuggestionProviderFromSpellCheckerInstance = [[MonocleSuggestionProviderFromSpellChecker alloc] init];
    [sharedMonocleSuggestionProviderFromSpellCheckerInstance retain];
  }
  return sharedMonocleSuggestionProviderFromSpellCheckerInstance;
}

+ (BOOL)providesSuggestions {
  return NO;
}

+ (id<MonocleSuggestionProviding>)suggestionProvider {
  return [self __sharedInstance];
}

- (NSString *)suggestionsSource {
  return @"Spelling word list";
}

- (NSArray *)suggestionsForString:(NSString *)string {
  if (spc == nil) {
    spc = [[NSSpellChecker sharedSpellChecker] retain];
  }
  NSArray *sugg = [spc completionsForPartialWordRange:[string rangeOfString:string]
                                             inString:string
                                             language:nil
                               inSpellDocumentWithTag:0];
  NSEnumerator *suggestionEnumerator = [sugg objectEnumerator];
  NSString *s;
  NSMutableArray *ms = [NSMutableArray array];
  while (s = [suggestionEnumerator nextObject]) {
    [ms addObject:[MonocleSuggestion suggestionWithString:s]];
  }

  return ms;
}

- (MonocleProviderInfo)suggestionsProviderInfo {
  MonocleProviderInfo x;
  x.icon = [NSImage imageNamed:@"NSApplicationIcon"];
  x.label = @"Word list suggestions";
  return x;
}

@end

@implementation MonocleSuggestionProviderFromGoogle
static MonocleSuggestionProviderFromGoogle *sharedMonocleSuggestionProviderFromGoogleInstance = nil;

+ (NSString *)vendorIdentifier {
  return @"net.wafflesoftware.Monocle.providers.Google";
}

+ (id)sharedInstance {
  if (nil == sharedMonocleSuggestionProviderFromGoogleInstance) {
    sharedMonocleSuggestionProviderFromGoogleInstance = [[MonocleSuggestionProviderFromGoogle alloc] init];
    [sharedMonocleSuggestionProviderFromGoogleInstance retain];
  }
  return sharedMonocleSuggestionProviderFromGoogleInstance;
}

+ (id<MonocleSuggestionProviding>)suggestionProvider {
  return [self sharedInstance];
}
+ (id<MonocleResultProviding>)resultProvider {
  return [self sharedInstance];
}

- (id)init {
  self = [super init];
  if (self != nil) {
    webView = [[WebView alloc] initWithFrame:NSMakeRect(-5000, -500, 20, 20) frameName:nil groupName:nil];
    WebPreferences *webPrefs = [[WebPreferences alloc] init];
    [webPrefs setJavaScriptEnabled:YES];
    [webView setPreferences:webPrefs];
    [webPrefs release];

    NSString *suggestionExtractionScript =
      [NSString stringWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"GoogleSuggestExtract"
                                                                                          ofType:@"js"]
                                encoding:NSUTF8StringEncoding
                                   error:NULL];

    [[webView mainFrame] loadHTMLString:[NSString stringWithFormat:@"<script>%@</script>", suggestionExtractionScript]
                                baseURL:nil];
  }
  return self;
}

+ (BOOL)providesSuggestions {
  return YES;
}

+ (BOOL)providesResults {
  return YES;
}

- (void)runSuggestionsParsing:(NSString *)callToExtractSuggestions {
  WebScriptObject *wso = nil;
  BOOL looped = NO;
  while ((wso = [webView windowScriptObject]) == nil) {
    looped = YES;
    NSLog(@"window script object is nil, waiting");
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.02]];
  }
  if (looped) {
    NSLog(@"window script object exists! %@", wso);
  }
  id evals = [wso evaluateWebScript:callToExtractSuggestions];
  //	NSLog(@"evals: %@", evals);
  if ([evals isKindOfClass:[NSString class]]) {
    NSString *jsRes = (NSString *)evals;
    //		NSLog(@"results: %@", jsRes);
    lastSuggestionsResult = [jsRes copy];
  } else {
    lastSuggestionsResult = nil;
  }
}

- (NSArray *)suggestionsForString:(NSString *)string {
  // http://www.google.com/complete/search?js=true&qu=133
  NSString *urlenc = [string stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
  NSData *resultData = [NSData
    dataWithContentsOfURL:[NSURL
                            URLWithString:[NSString
                                            stringWithFormat:@"http://www.google.com/complete/search?js=true&qu=%@",
                                            urlenc]]];
  NSString *result = [[NSString alloc] initWithData:resultData encoding:NSUTF8StringEncoding];
  //	NSLog(@"result for %@:\n--\n%@\n--", string, result);

  // OLD VERSION window.google.ac.Suggest_apply(frameElement, "iphone", new Array(2, "iphone", "152,000,000 results",
  // "iphone games", "188,000,000 results", "iphone apps", "54,600,000 results", "iphone unlock", "2,390,000 results",
  // "iphone accessories", "4,660,000 results", "iphone review", "156,000,000 results", "iphone canada", "32,500,000
  // results", "iphone applications", "62,000,000 results", "iphone ringtones", "2,240,000 results", "iphones",
  // "8,060,000 results"), new Array(""));
#ifdef USEOLDVERSIONNOPE
  {
    NSScanner *sc = [[NSScanner scannerWithString:result] retain];
    [sc scanUpToString:@"frameElement" intoString:NULL];
    [sc scanString:@"frameElement," intoString:NULL];
    NSString *q;
    [sc scanQuotedStringIntoString:&q];

    [sc scanUpToString:@"new Array(" intoString:NULL];
    [sc scanString:@"new Array(" intoString:NULL];
    [sc scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:NULL];

    NSMutableArray *results = [[NSMutableArray array] retain];

    [sc scanCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:NULL];
    [sc scanCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@", \t\n"] intoString:NULL];

    BOOL canContinue = YES;
    while (canContinue) {
      NSString *res = nil;
      if ([sc scanString:@")" intoString:NULL]) {
        canContinue = NO;
        continue;  // snigger
      }
      //		NSLog(@"a");
      [sc scanQuotedStringIntoString:&res];
      //		NSLog(@"result: %@", res);
      //		NSLog(@"b (%@)", res);
      [sc scanString:@"," intoString:NULL];
      //		NSLog(@"c");
      [sc scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:NULL];
      //		NSLog(@"d");
      // scan past "N results"
      [sc scanQuotedStringIntoString:NULL];
      //		NSLog(@"e");
      [sc scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:NULL];
      //		NSLog(@"f");
      if (![sc scanString:@"," intoString:NULL]) {
        canContinue = NO;
        //			NSLog(@"scanned result: %@, can't scan comma", res);
      } else {
        [sc scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:NULL];
        //			NSLog(@"scanned result: %@, scanning whitespace", res);
      }
      if (res != nil) [results addObject:[MonocleSuggestion suggestionWithString:res]];
    }

    //	NSLog(@"scanned quoted string: %@", q);
  }
#endif

  // window.google.ac.h(["133",[["1337","42,300,000 results","0"],["1337 translator","1,120,000 results","1"],["1330
  // boylston","34,400 results","2"],["1337 google","2,350,000 results","3"],["1335 avenue of the americas","364,000
  // results","4"],["1337x.org","219,000 results","5"],["1337pwn","331,000 results","6"],["133t","207,000
  // results","7"],["133 east 64th street","19,600 results","8"],["1333 minna","50,300 results","9"]]])
  // NEW VERSION
  NSString *magicStarter = @"window.google.ac.h";

  NSArray *actualResults = [[NSArray alloc] init];

  if ([result hasPrefix:magicStarter]) {
    /*
    // windowScriptObject *may* trigger creation
    NSLog(@"before wso");
    WebScriptObject *wso = [webView windowScriptObject];
    [wso retain]; [wso release];
    NSLog(@"wso: %@", wso);*/
    NSString *callToExtractSuggestions = [NSString
      stringWithFormat:@"extractGoogleSuggestSuggestions%@", [result substringFromIndex:[magicStarter length]]];
    //		NSLog(@"query %@, extract: %@", string, callToExtractSuggestions);
    [self performSelectorOnMainThread:@selector(runSuggestionsParsing:)
                           withObject:callToExtractSuggestions
                        waitUntilDone:YES];

    NSString *suggestionLines = [lastSuggestionsResult copy];
    [lastSuggestionsResult release];

    NSArray *suggestions = [suggestionLines componentsSeparatedByString:@"\n"];
    [suggestionLines release];

    NSMutableArray *results = [[NSMutableArray alloc] initWithCapacity:[suggestions count]];
    NSEnumerator *suggEnumerator = [suggestions objectEnumerator];
    NSString *suggline;
    while ((suggline = [suggEnumerator nextObject])) {
      if (suggline && [suggline length] > 0) {
        [results addObject:[MonocleSuggestion suggestionWithString:suggline]];
      }
    }

    [actualResults release];
    actualResults = results;
  }

  [result release];

  return [actualResults autorelease];
}

- (NSString *)suggestionsSource {
  return @"Google Suggest";
}

- (NSArray *)resultsForString:(NSString *)string {
  NSURL *u = [NSURL
    URLWithString:[NSString
                    stringWithFormat:@"http://ajax.googleapis.com/ajax/services/search/web?v=1.0&hl=en&q=%@",
                    [string stringByAddingPercentEscapesUsingEncoding:
                              NSUTF8StringEncoding]]];  //[NSURL fileURLWithPath:[[NSHomeDirectory()
                                                        // stringByAppendingPathComponent:@"Desktop"]
                                                        // stringByAppendingPathComponent:@"googlexhtmlquote.txt"]];
                                                        //	NSLog(@"U: %@", u);
                                                        //    NSURLConnection *conn = [[NSURLConnection alloc] ini]

  NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] initWithURL:u] autorelease];
  [request setValue:@"http://wafflesoftware.net/monocle/" forHTTPHeaderField:@"Referer"];

  NSData *dataFromGoogle = [NSURLConnection sendSynchronousRequest:request
                                                 returningResponse:NULL
                                                             error:NULL];  //[NSData dataWithContentsOfURL:u];
  NSString *jsonResultString = [[NSString alloc] initWithData:dataFromGoogle encoding:NSUTF8StringEncoding];
  //	NSLog(@"data %@, res: %@", dataFromGoogle, jsonResultString);

  NSDictionary *jsonResult = [NSDictionary dictionaryWithJSONString:jsonResultString];

  [jsonResultString release];

  //	NSLog(@"google results: %@", jsonResult);

  /*{
   "responseData" : {
   "results" : [],
   "cursor" : {}
   },
   "responseDetails" : null | string-on-error,
   "responseStatus" : 200 | error-code
   }*/

  //	NSLog(@"A");

  if (!jsonResult || [jsonResult count] < 1) {
    return [NSArray array];
  }

  //	NSLog(@"B");

  NSDictionary *responseData = [jsonResult objectForKey:@"responseData"];
  if (!responseData || [responseData count] < 1) {
    return [NSArray array];
  }

  //	NSLog(@"C");

  NSArray *resultsD = [responseData objectForKey:@"results"];
  if (!resultsD || [resultsD count] < 1 || ![resultsD isKindOfClass:[NSArray class]]) {
    return [NSArray array];
  }

  //	NSLog(@"D");

  NSMutableArray *finalResults = [NSMutableArray array];
  NSMutableSet *takenURLs = [NSMutableSet set];

  static NSMutableCharacterSet *dashWhitespaceNewlineSet = nil;
  if (dashWhitespaceNewlineSet == nil) {
    dashWhitespaceNewlineSet = [[NSCharacterSet characterSetWithCharactersInString:@"-"] mutableCopy];
    [dashWhitespaceNewlineSet formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  }

  NSEnumerator *enumerateResultsD = [resultsD objectEnumerator];
  NSDictionary *res;
  while ((res = [enumerateResultsD nextObject])) {
    NSString *url = [res objectForKey:@"unescapedUrl"];
    if ([takenURLs containsObject:url]) continue;

    MonocleResult *result = [[MonocleResult alloc] init];
    [result setUrl:url];
    [takenURLs addObject:url];

    NSString *title = [res objectForKey:@"titleNoFormatting"];
    [result setTitle:[title gtm_stringByUnescapingFromHTML]];

    //		NSLog(@"title: %@", title);

    NSString *descr = [res objectForKey:@"content"];
    [result
      setDescription:[[descr stringByTrimmingCharactersInSet:dashWhitespaceNewlineSet] gtm_stringByUnescapingFromHTML]];

    NSString *shurl = [res objectForKey:@"visibleUrl"];
    [result setLocation:((shurl != nil) ? [shurl stringByTrimmingWhitespace] : nil)];

    [finalResults addObject:[result autorelease]];

    //		NSLog(@"added result %@", result);
  }

  return finalResults;
}

- (NSString *)resultsSource {
  return @"Google results";
}

static NSImage *googleIcon = nil;

- (void)privateInitGoogleIcon {
  if (googleIcon != nil) return;
  googleIcon = [[NSImage alloc] initByReferencingFile:[[NSBundle mainBundle] pathForImageResource:@"Google"]];
  [googleIcon retain];
}

- (MonocleProviderInfo)suggestionsProviderInfo {
  [self privateInitGoogleIcon];
  MonocleProviderInfo x;
  x.icon = googleIcon;
  x.label = @"Google query suggestions";
  return x;
}

- (MonocleProviderInfo)resultsProviderInfo {
  [self privateInitGoogleIcon];
  MonocleProviderInfo x;
  x.icon = googleIcon;
  x.label = @"Google search results";
  return x;
}

- (BOOL)openResult:(NSString *)result {
  return [super openResult:result];
}

@end
@implementation MonocleSuggestionProviderFromYahoo
@end
