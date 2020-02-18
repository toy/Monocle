//
//  HTMLLikeTag.h
//  html5parser
//
//  Created by Jesper on 2006-05-13.
//  Copyright 2006 waffle software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface HTMLLikeTag : NSObject {
	NSDictionary *attributes;
	NSString *tagName;
	BOOL closeTag;
}
- (NSDictionary *)attributes;
//- (NSDictionary *)dictRepresentation;
- (NSString *)name;
- (BOOL)isCloseTag;

+ (id)tagWithName:(NSString *)name attributes:(NSDictionary *)attrs;
+ (id)closeTagWithName:(NSString *)name;
+ (id)tagWithName:(NSString *)name attributes:(NSDictionary *)attrs isCloseTag:(BOOL)ct;
- (id)initWithName:(NSString *)name attributes:(NSDictionary *)attrs isCloseTag:(BOOL)ct;
//+ (id)tagWithDictRepresentation:(NSDictionary *)dict;

@end
