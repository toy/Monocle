//
//  MonocleSuggestionProviding.h
//  Monocle
//
//  Created by Jesper on 2006-07-26.
//  Copyright 2006-2008 waffle software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

#import "MonocleSuggestionProviding_PublicAPI.h"

@interface MonocleSuggestionProvider (PrivateAPI)
+ (void)registerProviderVendor:(Class)providerVendor;

+ (NSDictionary *)providers;
+ (NSArray *)providerIdentifiers;
+ (NSArray *)orderedEnabledIdentifiers;
+ (NSArray *)orderedEnabledIdentifiersForEngine:(id)engine;

+ (NSArray *)resultsForString:(NSString *)string fromResultProvider:(id<MonocleResultProviding>)res;
+ (NSArray *)suggestionsForString:(NSString *)string fromSuggestionProvider:(id<MonocleSuggestionProviding>)sugg;

+ (BOOL)openResult:(NSString *)result usingProviderWithIdentifier:(NSString *)identifier;

//+ (void)combinedResultsSuggestionsForString:(NSString *)string forJob:(unsigned int)job delegate:(id)delegate;
+ (void)combinedResultsSuggestionsForString:(NSString *)string forJob:(unsigned int)job usingEngine:(id)engine delegate:(id)delegate;
+ (NSArray *)combinedResultsSuggestionsForString:(NSString *)string;
+ (NSArray *)combinedResultsForString:(NSString *)string;
+ (NSArray *)combinedSuggestionsForString:(NSString *)string;
@end

@interface MonocleSuggestion (PrivateAPI)
- (NSString *)jsonRepresentation;
@end

@interface MonocleResult (PrivateAPI)
- (NSString *)jsonRepresentation;
@end

@interface NSObject (MonocleResultsSuggestionsDelegate)
- (void)resultsSuggestions:(NSArray *)res fromProvider:(NSString *)prov forJob:(unsigned int)job;
@end

@interface MonocleSuggestionProviderFromSpellChecker : MonocleSuggestionProvider <MonocleSuggestionProviding> {
	NSSpellChecker *spc;
}
@end

@interface MonocleSuggestionProviderFromGoogle : MonocleSuggestionProvider <MonocleResultProviding, MonocleSuggestionProviding> {
	WebView *webView;
	NSString *lastSuggestionsResult;
}
@end
@interface MonocleSuggestionProviderFromYahoo : MonocleSuggestionProvider
@end

