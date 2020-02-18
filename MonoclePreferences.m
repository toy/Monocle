//
//  MonoclePreferences.m
//  Monocle
//
//  Created by Jesper on 2007-02-14.
//  Copyright 2007 waffle software. All rights reserved.
//

#import "MonoclePreferences.h"


@implementation MonoclePreferences
+ (void)registerDefaultPreferences:(NSDictionary *)dict {
	[[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:dict];
}

+ (void)setPreference:(id)preference forKey:(NSString *)key {
	[[[NSUserDefaultsController sharedUserDefaultsController] values] setValue:preference forKey:key];
}

+ (id)preferenceForKey:(NSString *)key orDefault:(id)def {
	id val = [self preferenceForKey:key];
	if (nil == val) return def;
	return val;
}

+ (id)preferenceForKey:(NSString *)key {
	id val = [[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:key];
	return val;
}

+ (BOOL)boolForKey:(NSString *)key orDefault:(BOOL)def {
	id val = [self preferenceForKey:key];
	if (nil == val) return def;
	return [(NSNumber *)val boolValue];
}

+ (BOOL)boolForKey:(NSString *)key {
	NSNumber *n = [self preferenceForKey:key];
	return [n boolValue];
}

+ (int)intForKey:(NSString *)key orDefault:(int)i {
	id val = [self preferenceForKey:key];
	if (nil == val) return i;
	return [(NSNumber *)val intValue];	
}

+ (int)intForKey:(NSString *)key {
	NSNumber *n = [self preferenceForKey:key];
	return [n intValue];	
}

+ (NSString *)stringForKey:(NSString *)key orDefault:(NSString *)def {
	id val = [self preferenceForKey:key];
	if (nil == val) return def;
	return val;	
}

+ (NSString *)stringForKey:(NSString *)key {
	id val = [[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:key];
	return val;	
}


+ (NSArray *)arrayForKey:(NSString *)key orDefault:(NSArray *)def {
	id val = [self preferenceForKey:key];
	if (nil == val) return def;
	return val;
}

+ (NSArray *)arrayForKey:(NSString *)key {
	id val = [[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:key];
	return val;	
}


@end
