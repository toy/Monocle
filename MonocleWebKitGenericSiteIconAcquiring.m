//
//  MonocleWebKitGenericSiteIconAcquiring.m
//  Monocle
//
//  Created by Jesper on 2007-02-10.
//  Copyright 2007 waffle software. All rights reserved.
//

#import "MonocleWebKitGenericSiteIconAcquiring.h"

static MonocleWebKitGenericSiteIconAcquiring *shared = nil;

@implementation MonocleWebKitGenericSiteIconAcquiring

+ (void)startAcquiringImage {
  shared = [[MonocleWebKitGenericSiteIconAcquiring alloc] init];
  [shared start];
}

- (id)init {
  if ((self = [super init]) != nil) {
    icon = nil;
  }
  return self;
}

- (void)start {
  wv = [[WebView alloc] initWithFrame:NSMakeRect(0.0, 0.0, 10.0, 10.0)];
  [wv setFrameLoadDelegate:self];
  [[wv mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]]];
  NSLog(@"start");
}

- (void)webView:(WebView *)sender didReceiveIcon:(NSImage *)image forFrame:(WebFrame *)frame {
  icon = [image copy];
  NSLog(@"icon: %@", image);
}

- (NSImage *)icon {
  return icon;
}

+ (NSImage *)icon {
  if (!shared) return nil;
  return [shared icon];
}

@end
