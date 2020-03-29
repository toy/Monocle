//
//  MonocleEncoding.h
//  Monocle
//
//  Created by Jesper on 2007-03-07.
//  Copyright 2007 waffle software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define MonocleSearchEngineDefaultEncoding @"UTF-8"

@interface NSString (MonocleNSStringEncodingHelpers)
+ (NSStringEncoding)stringEncodingForIANA:(NSString *)iana;
+ (NSString *)IANAForStringEncoding:(NSStringEncoding)iana;

+ (BOOL)isIANAValidEncoding:(NSString *)iana;
@end

@interface MonocleEncodingList : NSObject
+ (NSArray *)encodingNames;
@end