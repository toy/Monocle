//
//  HTMLLikeTag.m
//  html5parser
//
//  Created by Jesper on 2006-05-13.
//  Copyright 2006 waffle software. All rights reserved.
//

#import "HTMLLikeTag.h"


@implementation HTMLLikeTag

- (id) init {
	self = [super init];
	if (self != nil) {
		attributes = [[NSDictionary dictionary] retain];
		tagName = @"";
		closeTag = NO;
	}
	return self;
}

- (NSDictionary *)attributes {
	return [[attributes copy] autorelease];
}

- (NSString *)name {
	return tagName;
}

- (BOOL)isCloseTag {
	return closeTag;
}

- (NSString *)description {
	return [NSString stringWithFormat:@"%@ %@", 
		[super description], 
		(closeTag ? [NSString stringWithFormat:@"close tag: %@", (tagName ? tagName : @"(null)")] : [NSString stringWithFormat:@"tag: %@, attrs: %@", tagName, (attributes ? attributes : @"(null)")])
		];
}

+ (id)tagWithName:(NSString *)name attributes:(NSDictionary *)attrs {
	return [HTMLLikeTag tagWithName:name attributes:attrs isCloseTag:NO];
}

+ (id)closeTagWithName:(NSString *)name {
	return [HTMLLikeTag tagWithName:name attributes:nil isCloseTag:YES];
}

+ (id)tagWithName:(NSString *)name attributes:(NSDictionary *)attrs isCloseTag:(BOOL)ct {
	HTMLLikeTag *tag = [[self alloc] initWithName:name
									   attributes:attrs
										  isCloseTag:ct];
	return [tag autorelease];
}

- (id)initWithName:(NSString *)name attributes:(NSDictionary *)attrs isCloseTag:(BOOL)ct {
	self = [super init];
	if (self != nil) {
		tagName = name;
		attributes = attrs;
		closeTag = ct;
	}
	return self;
}

@end
