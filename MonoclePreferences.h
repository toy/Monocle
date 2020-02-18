//
//  MonoclePreferences.h
//  Monocle
//
//  Created by Jesper on 2007-02-14.
//  Copyright 2007 waffle software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MonoclePreferences : NSObject
+ (void)registerDefaultPreferences:(NSDictionary *)dict;

+ (void)setPreference:(id)preference forKey:(NSString *)key;

+ (id)preferenceForKey:(NSString *)key orDefault:(id)def;
+ (id)preferenceForKey:(NSString *)key;

+ (BOOL)boolForKey:(NSString *)key orDefault:(BOOL)def;
+ (BOOL)boolForKey:(NSString *)key;
+ (int)intForKey:(NSString *)key orDefault:(int)i;
+ (int)intForKey:(NSString *)key;

+ (NSString *)stringForKey:(NSString *)key orDefault:(NSString *)def;
+ (NSString *)stringForKey:(NSString *)key;

+ (NSArray *)arrayForKey:(NSString *)key orDefault:(NSArray *)def;
+ (NSArray *)arrayForKey:(NSString *)key;
@end
