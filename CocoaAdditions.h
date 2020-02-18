//
//  CocoaAdditions.h
//  Monocle
//
//  Created by Jesper on 2008-01-05.
//  Copyright 2008 waffle software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSString (EscapeHTMLEntitiesExtension)
- (NSString *) stringByHTMLEntityEscaping;
@end
