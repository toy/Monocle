//
//  BSJSONAdditions
//
//  Created by Blake Seely on 2009/03/24.
//  Copyright 2006 Blake Seely - http://www.blakeseely.com  All rights reserved.
//  Permission to use this code:
//
//  Feel free to use this code in your software, either as-is or
//  in a modified form. Either way, please include a credit in
//  your software's "About" box or similar, mentioning at least
//  my name (Blake Seely).
//
//  Permission to redistribute this code:
//
//  You can redistribute this code, as long as you keep these
//  comments. You can also redistribute modified versions of the
//  code, as long as you add comments to say that you've made
//  modifications (keeping these original comments too).
//
//  If you do use or redistribute this code, an email would be
//  appreciated, just to let me know that people are finding my
//  code useful. You can reach me at blakeseely@mac.com

#import <Foundation/Foundation.h>

#ifndef NSINTEGER_DEFINED
#if __LP64__ || NS_BUILD_32_LIKE_64
typedef long NSInteger;
typedef unsigned long NSUInteger;
#else
typedef int NSInteger;
typedef unsigned int NSUInteger;
#endif
#define NSINTEGER_DEFINED 1
#define NOTCOMPILEDONLEOPARD 1
#endif

#import "NSDictionary+BSJSONAdditions.h"

@interface NSArray (BSJSONAdditions)

+ (NSArray *)arrayWithJSONString:(NSString *)jsonString;
- (NSString *)jsonStringValue;
- (NSString *)jsonStringValueWithIndentLevel:(NSInteger)level;

@end
