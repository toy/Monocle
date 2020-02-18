//
//  MonocleEncoding.m
//  Monocle
//
//  Created by Jesper on 2007-03-07.
//  Copyright 2007 waffle software. All rights reserved.
//

#import "MonocleEncoding.h"

@implementation NSString (MonocleNSStringEncodingHelpers)
+ (NSStringEncoding)stringEncodingForIANA:(NSString *)iana {
	NSLog(@"finding string encoding for iana: %@", iana);
	CFStringEncoding cfenc = CFStringConvertIANACharSetNameToEncoding((CFStringRef)iana);
	NSLog(@"cf encoding: %d (invalid = %d, UTF-8 = %d)", cfenc, kCFStringEncodingInvalidId, kCFStringEncodingUTF8);
	NSStringEncoding nsenc = CFStringConvertEncodingToNSStringEncoding(cfenc);
	NSLog(@"ns encoding: %d (UTF-8 = %d)", nsenc, NSUTF8StringEncoding);
	return nsenc;
}

+ (NSString *)IANAForStringEncoding:(NSStringEncoding)iana {
	CFStringEncoding cfenc = CFStringConvertNSStringEncodingToEncoding(iana);
	NSString *enc = (NSString *)CFStringConvertEncodingToIANACharSetName(cfenc);
	return [enc autorelease];
}

+ (BOOL)isIANAValidEncoding:(NSString *)iana {
	CFStringEncoding cfenc = CFStringConvertIANACharSetNameToEncoding((CFStringRef)iana);
	return (kCFStringEncodingInvalidId != cfenc);
}
@end

@implementation MonocleEncodingList : NSObject
+ (NSArray *)encodingNames {
	NSMutableArray *arr = [[NSArray array] mutableCopy];
	const CFStringEncoding *encodings = CFStringGetListOfAvailableEncodings();
	int i = 0;
	while (encodings[i] != kCFStringEncodingInvalidId) {
		CFStringEncoding enc = encodings[i];
		[arr addObject:[(NSString *)CFStringConvertEncodingToIANACharSetName(enc) autorelease]];
		i++;
	}
	return [arr autorelease];
}
@end

