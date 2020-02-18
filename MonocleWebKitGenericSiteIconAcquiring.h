//
//  MonocleWebKitGenericSiteIconAcquiring.h
//  Monocle
//
//  Created by Jesper on 2007-02-10.
//  Copyright 2007 waffle software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>


@interface MonocleWebKitGenericSiteIconAcquiring : NSObject {
	WebView *wv;
	NSImage *icon;
}
- (void)start;
+ (void)startAcquiringImage;
+ (NSImage *)icon;
- (NSImage *)icon;
@end
