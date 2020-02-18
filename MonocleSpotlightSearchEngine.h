//
//  MonocleSpotlightSearchEngine.h
//  Monocle
//
//  Created by Jesper on 2006-07-28.
//  Copyright 2006 waffle software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MonocleSearchEngine;

@interface MonocleSpotlightSearchEngine : MonocleSearchEngine
+ (BOOL)vendsSingleEngine;
- (void)applyDefaultEngineProperties;
- (void)performSearchForQuery:(NSString *)query;
- (NSDictionary *)properties;
@end
