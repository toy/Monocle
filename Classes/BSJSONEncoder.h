//
//  BSJSONEncoder.h
//  BSJSONAdditions
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

@interface BSJSONEncoder : NSObject
+ (NSString *)jsonStringForValue:(id)value withIndentLevel:(NSInteger)level;
@end
