//
//  MonocleWashDrawing.h
//  Monocle
//
//  Created by Jesper on 2007-02-08.
//  Copyright 2007 waffle software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class CTGradient;

@interface MonocleWashDrawing : NSObject {
}
+ (void)drawCurrentWashInRect:(NSRect)rect;
+ (void)drawBackgroundWash:(CTGradient *)gradient inFrame:(NSRect)rect;
+ (void)drawBackgroundWash:(CTGradient *)gradient inFrame:(NSRect)rect sheen:(BOOL)hasSheen;

+ (CTGradient *)primaryWash;
+ (void)getPrimaryWash:(CTGradient **)color hasSheen:(BOOL *)sheen;
@end
