//
//  DrawingExtras.h
//
//  Created by Jesper on 2006-06-12.
//

#import <Cocoa/Cocoa.h>

@interface NSBezierPath (CocoaDevCategory)
+ (NSBezierPath *)bezierPathWithJaggedOvalInRect:(NSRect)r spacing:(float)spacing;
+ (NSBezierPath *)bezierPathWithJaggedPillInRect:(NSRect)r spacing:(float)spacing;
+ (NSBezierPath *)bezierPathWithRoundRectInRect:(NSRect)aRect radius:(float)radius;
+ (NSBezierPath *)bezierPathWithTriangleInRect:(NSRect)r edge:(NSRectEdge)edge;
@end