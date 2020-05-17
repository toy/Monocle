//
//  MonocleSuggestionProviding_PublicAPI.h
//  Monocle
//
//  Copyright 2006-2008 waffle software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// How to implement a search help provider:
//
// * Create a subclass of MonocleSuggestionProvider - your "provider class".
//   Your provider class will be used to dole out objects that actually
//   provide *suggestions* and *results*. (In your provider class, if you
//   implement +initialize, call super - this is how your class is detected.)
// * Make sure your provider class returns a vendor identifier. This
//   follows the same form of a bundle identifier.
// * Implement +providesSuggestions and +providesResults to return
//   whether you can provide those things. If you can, and only if,
//   Monocle will continue to ask for a particular instance of fitting
//   objects to actually provide these things. (+suggestionProvider and
//   +resultProvider.) Note that this can be an instance of your provider
//   class or of some other class, it doesn't matter.
// * MonocleSuggestionProviding and MonocleResultProviding both follow
//   similar patterns:
//   * The ...Source method returns a very brief, localized string
//     identifying your provider in log messages and grouping your
//     suggestions/results in the search help list.
//   * The ...SourceIdentifier method again returns a bundle identifier-like
//     string (for the particular provider, not for the provider class).
//   * The ...ProviderInfo method returns the struct MonocleProviderInfo,
//     into which you should stuff a localized string and an appropriate
//     icon. The icon is intended for display at 16x16, but since it's a
//     resolution-independent world, try to provide an image which can
//     work at higher resolutions (via multiple image representations)
//     if needed. (Both objects should be retained by you.)
//   * Finally, the ...ForString method returns an array containing
//     instances of the appropriate result class - suggestion providers
//     return MonocleSuggestions and result providers MonocleResults.
//     Obviously, you return appropriate items based on the string.
// * Additionally, MonocleResultProviding specifies the -openResult:
//   method. The string passed in is whatever is stored in MonocleResult's
//   'url' field. If you're just going to open the URL in a web browser,
//   use MonocleSuggestionProvider's +launchURLinBrowser: method, which
//   will guarantee the correct behavior if Monocle is ever altered to
//   facilitate opening results in different web browsers.
//   If opening the result failed for some reason, return NO; otherwise,
//   or if you can't tell, like when opening URLs in web browsers,
//   return YES. If opening the result failed, Monocle will keep the
//   search panel and the search help list open, so that another result
//   may be tried.
// * Design your providers to be efficient and quick-running. The methods
//   returning providers in the provider class should return the same
//   instance on every call.
// * Produce a bundle with the extension .monoclePlugin, and make sure
//   that the principial class - if it's not your provider class - causes
//   your provider class to load by referencing it in some way.
// * Use the Mac OS X 10.4 SDK and build universal binaries, unless
//   you're using functionality strictly available only on one platform.
// * Link to the Monocle application using BUNDLE_LOADER. Read:
//   <http://talblog.info/archives/2007/05/look_ma_no_fram.html>
// * Place your bundle in ~/Library/Application Support/Monocle/.

typedef struct _MonocleProviderInfo {
  NSImage *icon;
  NSString *label;

} MonocleProviderInfo;

@interface MonocleSuggestion : NSObject <NSCopying> {
  NSString *suggestion;
}
- (NSString *)suggestion;
- (void)setSuggestion:(NSString *)newSuggestion;

+ (MonocleSuggestion *)suggestionWithString:(NSString *)sugg;
@end

@interface MonocleResult : NSObject <NSCopying> {
  NSString *title;
  NSString *description;
  NSString *location;
  NSString *url;
}
/* The title is the main title shown for the result; like the document title of a web page. */
- (NSString *)title;
- (void)setTitle:(NSString *)newTitle;

/* The description contains a description of the result or nearby words matching the search query. The description is
 * not currently exposed in the user interface but is set to appear in later versions of Monocle. */
- (NSString *)description;
- (void)setDescription:(NSString *)newDescription;

/* The location contains a casual, short version of where the result is located. For web page results, this can be the
 * host and a subdirectory. This helps disambiguate from other results. */
- (NSString *)location;
- (void)setLocation:(NSString *)newLocation;

/* The URL is very likely an actual URL; it is what is passed back when the result provider is asked to open the result.
 * Since you can implement openResult: in any way you'd like, however, it could be any pertinent context data. The URL
 * is never exposed in the user interface. */
- (NSString *)url;
- (void)setUrl:(NSString *)newUrl;
@end

@protocol MonocleSuggestionProviding
- (NSArray *)suggestionsForString:(NSString *)string;
- (NSString *)suggestionsSource;
- (NSString *)suggestionsSourceIdentifier;
- (MonocleProviderInfo)suggestionsProviderInfo;
@end

@protocol MonocleResultProviding
- (NSArray *)resultsForString:(NSString *)string;
- (NSString *)resultsSource;
- (NSString *)resultsSourceIdentifier;
- (BOOL)openResult:(NSString *)result;
- (MonocleProviderInfo)resultsProviderInfo;
@end

@protocol MonocleSuggestionProviderVending
+ (BOOL)providesSuggestions;
+ (id<MonocleSuggestionProviding>)suggestionProvider;
+ (BOOL)providesResults;
+ (id<MonocleResultProviding>)resultProvider;
+ (NSString *)vendorIdentifier;
@end

@interface MonocleSuggestionProvider : NSObject <MonocleSuggestionProviderVending>
+ (void)launchURLinBrowser:(NSURL *)url;
@end