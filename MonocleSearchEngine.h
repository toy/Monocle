//
//  MonocleSearchEngine.h
//  Monocle
//
//  Created by Jesper on 2006-07-28.
//  Copyright 2006 waffle software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#ifdef ACTUALLY_DO_BUILD_SEARCH_ENGINE_OBJECT

#ifdef IS_THE_MONOCLE_PROJECT
@class MonocleSearchEngine;
#else
/* define a crude husk */
@interface MonocleSearchEngine : NSObject
@end

/* Use this method whenever you open a URL that should
** open in the browser preferred for Monocle. */
@interface MonocleController : NSObject
+ (void)openBrowserURL:(NSURL *)url;
@end
#endif

@interface MonocleSearchEngine (PublicAPI)
/* Whether only one engine should be allowed to be created.
** For an imaginary simple Spotlight engine with no properties,
** adding several different such engines varying only in things
** like name but identical in function would not make sense.
** If this returns YES, then at no point will you be able to
** add more than one of these engines in Monocle.
**
** Must be overridden by the subclass.
*/
+ (BOOL)vendsSingleEngine;

/* Whether the engine is currently a debug engine.
** By default returns NO, and slightly changes behavior
** to make it easier for the developer when overridden
** to return YES, and when Monocle is also in debug mode.
*/
+ (BOOL)isDebugEngine;

/* The following methods assist in providing a user interface
** when editing the engine's properties. If this isn't needed,
** you can safely avoid implementing the methods.
**
** +providesUIForEditing checks whether UI support is given
** at all. The default implementation returns `NO`, and the
** Preferences panel will do something appropriate to indicate
** that there is nothing to configure.
**
** If the engine is a debug engine and has properties, a
** rudimentary UI is provided to edit these properties
** that currently have property list values - NSNumber, NSDate,
** NSData, NSString, NSArray and NSDictionary.
**
** If the engine is not a debug engine and has properties, a
** message will be logged to the Console (to encourage proper
** UIs).
**
** +setUpEngineEditingInView: is called the first time
** the Preferences panel is loaded, and should load any NIBs
** and establish anything needed, including adding its user
** interface to the host view.
**
** -refreshEditingUI is called whenever the selection changes
** to encompass a different engine, or periodically when the
** backend data store used for engines in Monocle is invalidated.
** The UI should be updated to reflect the stored, committed
** properties of the engine.
**
** -willChangeEngineProperty: and -didChangeEngineProperty:
** should be called before and after any properties are
** changed in the editing UI.
**
** The current UI methods are designed around single-engine
** selections. If multiple-engine selections are ever made
** possible (which seems unlikely, given the situation where
** multiple custom engines with their own UI could be selected)
** they will work with a different set of methods.
*/
+ (BOOL)providesUIForEditing;
+ (void)setUpEngineEditingInView:(NSView *)hostView;
- (void)refreshEditingUI;
- (void)willChangeEngineProperty:(NSString *)propertyKey;
- (void)didChangeEngineProperty:(NSString *)propertyKey;

/* The designated initializer.
** Your engine is responsible for defining and implementing
** its own storage for the properties. The property keys
** are not guaranteed to be the same as when they are
** stored in the defaults database (or elsewhere), but
** any possible transformation magic is guaranteed to be
** invisible to any engines.
**
** Must be overridden by the subclass.
*/
- (id)initWithProperties:(NSDictionary *)properties;

/* Tells the engine to reset its properties to the defaults.
** Will often follow creation of a new engine.
**
** Must be overridden by the subclass.
*/
- (void)applyDefaultEngineProperties;

/* Actually performs the search.
**
** Must be overridden by the subclass.
** If the engine should open a URL in a browser,
** please use +[MonocleController openBrowserURL:].
*/
- (void)performSearchForQuery:(NSString *)query;

/* Returns the engine-specific properties.
**
** The default implementation returns an empty
** dictionary. If your engine does not rely on
** properties, you do not have to override this.
*/
- (NSDictionary *)properties;
@end

/*@interface MonocleSearchEngine : NSObject <MonocleSearchEngineering> {

}

+ (id)engineWithProperties:(NSDictionary *)properties;


@end*/

#endif