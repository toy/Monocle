//
//  NSString+BSJSONAdditions.h
//  BSJSONAdditions
//
//  Created by Blake Seely (Air) on 3/24/09.
//  Copyright 2009 Apple Inc.. All rights reserved.
//

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

@interface NSString (BSJSONAdditions)

+ (NSString *)jsonIndentStringForLevel:(int)level;
- (NSString *)jsonStringValue;

@end
