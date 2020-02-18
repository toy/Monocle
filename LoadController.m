#import <WebKit/WebKit.h>

#import "LoadController.h"
#import "HTMLLikeTag.h"
#import "HTML5Parser.h"
#import "MonocleReorderableArrayController.h"
#import "MonocleEngineArrayController.h"
#import "MonocleController.h"
#import "MonocleGlassIconDrawing.h"

#import "MonocleEncoding.h"

#define MagicWord			@"MAGIC"
#define EmbEnc(X)			[NSNumber numberWithInt:(X)]
#define UnbEnc(X)			[(X) intValue]
#define StrOrNil(X)			((X) ? (X) : @"")

#define MonocleSearchEngineDiscoveryAltItemTag	4000
#define MonocleSearchEngineDiscoveryInitialPage	[NSURL URLWithString:@"about:blank"]

#define MonocleDiscoveryTryToSniffSubmittedForms	0

@interface NSURL (DiscoveryVerboten)
- (BOOL)isOkayForDiscovery;
@end

@implementation NSURL (DiscoveryVerboten)
- (BOOL)isOkayForDiscovery {
	if ([[[[self host] lowercaseString] componentsSeparatedByString:@"googlesyndication.com"] count] > 1) {
		return NO;
	}
	return YES;
}
@end


@implementation LoadController

+ (void)initialize {
	[self setKeys:[NSArray arrayWithObject:@"discoveredEngines"] triggerChangeNotificationsForDependentKey:@"anyEnginesDetected"];
}

- (void)webView:(WebView *)sender didReceiveIcon:(NSImage *)image forFrame:(WebFrame *)frame {
//	NSLog(@"did receive icon");
	[pageIcon setImage:image];
	
	/*
	
	if ([[[[frame dataSource] initialRequest] URL] isEqualTo:MonocleSearchEngineDiscoveryInitialPage])
		blankImage = [image copy];*/
}

- (void)webView:(WebView *)sender willPerformClientRedirectToURL:(NSURL *)URL delay:(NSTimeInterval)seconds fireDate:(NSDate *)date forFrame:(WebFrame *)frame {
	// NSLog(@"before (client) redirecting to %@, try to discover", URL);
	[self tryToDiscoverSearchEngineForFrame:frame];
}

- (void)webView:(WebView *)sender didFailProvisionalLoadWithError:(NSError *)error forFrame:(WebFrame *)frame {
/*	[(NSSegmentedCell *)[stopReload cell] setEnabled:NO forSegment:0];	
	[(NSSegmentedCell *)[stopReload cell] setEnabled:YES forSegment:1];*/
	[stopMenuItem setEnabled:NO];
	[reloadMenuItem setEnabled:YES];
//	NSLog(@"enable reload, disable stop");
}

- (void)webView:(WebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame {
/*	[(NSSegmentedCell *)[stopReload cell] setEnabled:NO forSegment:0];		
	[(NSSegmentedCell *)[stopReload cell] setEnabled:YES forSegment:1];*/
	[stopMenuItem setEnabled:NO];
	[reloadMenuItem setEnabled:YES];
//	NSLog(@"enable reload, disable stop");
}

- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame {
	// NSLog(@"provisional load started, try to discover");
//	[(NSSegmentedCell *)[stopReload cell] setEnabled:YES forSegment:0];
//	NSLog(@"enable stop");
	
	if (frame == [sender mainFrame]) {
		if (currentURL != nil && [[[currentURL host] lowercaseString] isNotEqualTo:[[[[[frame provisionalDataSource] request] URL] host] lowercaseString]]) {
			[pageIcon setImage:blankImage];
		}
	}
	
	[stopMenuItem setEnabled:YES];
	[self tryToDiscoverSearchEngineForFrame:frame];	
}

- (void)webView:(WebView *)sender didReceiveServerRedirectForProvisionalLoadForFrame:(WebFrame *)frame {
//	// NSLog(@"server redirecting, try to discover");
//	[self tryToDiscoverSearchEngineForFrame:frame];
}

- (void)webView:(WebView *)sender decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id<WebPolicyDecisionListener>)listener {
//	NSLog(@"decide policy for navigation action: %@", actionInformation);
	int type = [[actionInformation objectForKey:WebActionNavigationTypeKey] intValue];
	if (type == WebNavigationTypeFormSubmitted) {
//		NSLog(@"form submission! request: %@, action: %@", request, actionInformation); 
#if		MonocleDiscoveryTryToSniffSubmittedForms
		BOOL x = [self tryToDiscoverSearchEngineFromSubmittedForm:actionInformation request:request frame:frame];
//		NSLog(@"could we discover from submitted form data? %@", (x ? @"yep" : @"no"));
		if (x) { [listener ignore]; return; }
#endif
		[self tryToDiscoverSearchEngineForFrame:frame];
	}
	[listener use];
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
	
/*	NSSegmentedCell *c = (NSSegmentedCell *)[backNext cell];
	[c setEnabled:[webView canGoBack] forSegment:0];
	[c setEnabled:[webView canGoForward] forSegment:1];*/
/*	c = (NSSegmentedCell *)[stopReload cell];
	[c setEnabled:([webView estimatedProgress] != 1.0) forSegment:0];
	[c setEnabled:YES forSegment:1];*/
	[stopMenuItem setEnabled:([webView estimatedProgress] != 1.0)];
	[reloadMenuItem setEnabled:YES];
//	NSLog(@"%@ reload, enable stop", ([webView estimatedProgress] != 1.0) ? @"enable" : @"disable");
	// NSLog(@"after finishing loading, try to discover");
	[self tryToDiscoverSearchEngineForFrame:frame];
	
	if (frame == [sender mainFrame]) {
		[currentURL release];
		currentURL = [[[[[webView mainFrame] dataSource] response] URL] copy];
	}
}

- (NSStringEncoding)stringEncodingForTextStringEncodingName:(NSString *)enc {
	CFStringEncoding cfenc = CFStringConvertIANACharSetNameToEncoding((CFStringRef)enc);
	NSStringEncoding nsenc = CFStringConvertEncodingToNSStringEncoding(cfenc);
	return nsenc;
}

- (BOOL)tryToDiscoverSearchEngineFromSubmittedForm:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame {
	
//	DOMNode *origNode = [[actionInformation objectForKey:WebActionElementKey] objectForKey:WebElementDOMNodeKey];
	DOMHTMLFormElement *formNode = nil;
//	NSLog(@"original node: %@", origNode);
	/*	if (origNode) {
	formNode = [origNode form];
	if (!formNode) { NSLog(@"no form node!"); return; }
	NSLog(@"form node: %@", formNode);
	} else {
		
		
}*/
	
	DOMDocument *d = [frame DOMDocument];
	DOMNodeList *nl = [d getElementsByTagName:@"form"];
	unsigned long forms = [nl length];
//	NSLog(@"got forms! %u forms", forms);
	if (forms == 0) { /*NSLog(@"no forms!? crapping out.");*/ return NO; }
	unsigned long i = 0;
	NSURL *originalURL = [actionInformation objectForKey:WebActionOriginalURLKey];
	NSString *originalAbs = [originalURL absoluteString];
//	NSLog(@"original abs: %@", originalAbs);
	NSURL *origwoGET = nil;
	if ([originalURL query] && [[originalURL query] isNotEqualTo:@""]) {
		origwoGET = [NSURL URLWithString:[[originalAbs componentsSeparatedByString:[NSString stringWithFormat:@"?%@", [originalURL query]]] objectAtIndex:0]];
//		NSLog(@"original without GET: %@", origwoGET);
	}
	for (i = 0; i < forms; i++) { 
		formNode = (DOMHTMLFormElement *)[nl item:i];
//		NSLog(@"form %u, %@", i, formNode);
		
		NSURLResponse *resp = [[frame dataSource] response];
		
		//NSLog(@"text encoding name: %@; translated into int: %d", [resp textEncodingName], [NSString stringEncodingForIANA:[resp textEncodingName]]);
		
		NSURL *actionURL = [NSURL URLWithString:[formNode action] relativeToURL:[resp URL]];
		NSString *meth = [[formNode method] lowercaseString];
		
//		NSLog(@"action url: %@, meth: %@", [actionURL absoluteString], meth);
		
		if (!([meth isEqualToString:@"post"])) {
			if ([[origwoGET absoluteString] isNotEqualTo:[actionURL absoluteString]]) {
//				NSLog(@"not our man, please continue");
				continue;
			}
		}
		
		NSMutableDictionary *texts = [NSMutableDictionary dictionary];
		NSMutableDictionary *fields = [NSMutableDictionary dictionary];
		
		DOMNodeList *elements = [formNode getElementsByTagName:@"input"];
		if (!elements) { /*NSLog(@"no inputs!");*/ } else {
			unsigned long numEl = [elements length];
//			NSLog(@"input elements: %u", numEl);
			if (numEl > 0) {
				unsigned long j = 0;
				for (j = 0; j < numEl; j++) {
					DOMHTMLInputElement *input = (DOMHTMLInputElement *)[elements item:j];
//					NSLog(@"input %u, %@", j, input);
					NSString *type = [[[input type] lowercaseString] stringByTrimmingWhitespace];
					if (([type isNotEqualTo:@"file"]) &&
						([type isNotEqualTo:@"radio"]) &&
						([type isNotEqualTo:@"check"]) && 
						([type isNotEqualTo:@"checkbox"]) && 
						([type isNotEqualTo:@"password"]) && 
						([type isNotEqualTo:@"submit"]) &&
						([type isNotEqualTo:@"image"]) &&
						([type isNotEqualTo:@"reset"]) && 
						([type isNotEqualTo:@"button"]) && 
						([type isNotEqualTo:@"hidden"])) {
						
//						NSLog(@"is text or search type: %@", type);
//						NSLog(@"has value: %@", [input value]);
						
						if ([[[input value] stringByTrimmingWhitespace] isNotEqualTo:@""]) {
							[texts setObject:[input value] forKey:input];
						}
						
					}
					[fields setObject:[input value] forKey:[input name]];
				}
			}
		}
		elements = [formNode getElementsByTagName:@"textarea"];
		if (!elements) { /*NSLog(@"no textareas!");*/ } else {
			unsigned long numEl = [elements length];
//			NSLog(@"textarea elements: %u", numEl);
			if (numEl > 0) {
				unsigned long j = 0;
				for (j = 0; j < numEl; j++) {
					DOMHTMLTextAreaElement *txta = (DOMHTMLTextAreaElement *)[elements item:j];
//					NSLog(@"textarea %u, %@", j, txta);
//					NSLog(@"has value: %@", [txta value]);
					
					if ([[[txta value] stringByTrimmingWhitespace] isNotEqualTo:@""]) {
						[texts setObject:[txta value] forKey:txta];
					}
					[fields setObject:[txta value] forKey:[txta name]];
				}
			}
		}
		
//		NSLog(@"texts: (%i) %@", [texts count], texts);
		if ([texts count] == 0) continue;
		
		if ([texts count] == 1) {
			
			NSString *inp = [[[texts allKeys] objectAtIndex:0] name];
			NSString *word = [[texts allValues] objectAtIndex:0];
//			NSString *encWord = [[[word stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] componentsSeparatedByString:@"%20"] componentsJoinedByString:@"+"];
			
//			NSLog(@"input name: %@, value: %@, encoded value: %@", inp, word, encWord);
			
			NSString *qu = [originalURL query];
			NSString *newqu = @"";
			NSArray *GETkvps = [qu componentsSeparatedByString:@"&"];
			NSEnumerator *GETkvEnumerator = [GETkvps objectEnumerator];
			NSString *GETkv;
			while (GETkv = [GETkvEnumerator nextObject]) {
				NSArray *GETkvp = [GETkv componentsSeparatedByString:@"="];
				if ([[GETkvp objectAtIndex:0] isEqualToString:inp]) {
					newqu = [newqu stringByAppendingFormat:@"%@=%@", inp, @"%@"];
				} else {
					newqu = [newqu stringByAppendingString:GETkv];						
				}
				newqu = [newqu stringByAppendingString:@"&"];
			} 
//			NSLog(@"before! (newqu: %@, length: %i)", newqu, [newqu length]);
			if ([newqu length] > 2)
				newqu = [newqu substringToIndex:[newqu length]-2];
//			NSLog(@"after!");
			
			NSString *correctURL = [[[originalURL absoluteString] componentsSeparatedByString:[NSString stringWithFormat:@"?%@", qu]] componentsJoinedByString:[NSString stringWithFormat:@"?%@", newqu]];
			
			NSString *encoding = [self ianaEncodingForFrame:frame];
			NSString *formEncoding = [formNode acceptCharset];
			if (formEncoding && [[formEncoding stringByTrimmingWhitespace] isNotEqualTo:@""]) {
				if ([NSString isIANAValidEncoding:[formEncoding stringByTrimmingWhitespace]])
					encoding = [formEncoding stringByTrimmingWhitespace];
			}
			
			if ([[request HTTPMethod] isEqualToString:@"GET"]) {
				
					[self addDiscoveredEngine:[NSString stringWithFormat:@"%@ [searched for %@]", [self figureOutEngineName:[searchEngine stringValue]], word]
										 icon:[[[pageIcon image] copy] autorelease] 
										  url:correctURL
									 postData:nil
									 ianaEncoding:encoding];
					return YES;
			} else {
				if ([[request HTTPBody] isNotEqualTo:[NSData data]]) {
			// NSLog(@"POST; HTTP headers: %@", [req allHTTPHeaderFields]);
			// NSLog(@"text encoding name: %@", [[frame dataSource] textEncodingName]);
					NSSet *encodings = [NSSet setWithObjects:EmbEnc(NSUTF8StringEncoding), EmbEnc(NSASCIIStringEncoding), EmbEnc(NSISOLatin1StringEncoding), EmbEnc(NSShiftJISStringEncoding), EmbEnc(NSWindowsCP1252StringEncoding), EmbEnc(NSISO2022JPStringEncoding), EmbEnc(NSJapaneseEUCStringEncoding), nil];
					NSString *body;
					NSEnumerator *encEnumerator = [encodings objectEnumerator];
					int enc;
					while (enc = UnbEnc([encEnumerator nextObject])) {
						body = [[[NSString alloc] initWithData:[request HTTPBody] encoding:enc] autorelease];
							
							NSMutableDictionary *postData = [[NSDictionary dictionary] mutableCopy];
							
							NSArray *POSTkvps = [body componentsSeparatedByString:@"&"];
							NSEnumerator *POSTkvEnumerator = [POSTkvps objectEnumerator];
							NSString *POSTkv;
							while (POSTkv = [POSTkvEnumerator nextObject]) {
								NSArray *POSTkvp = [POSTkv componentsSeparatedByString:@"="];
								if ([[POSTkvp objectAtIndex:0] isEqualToString:inp]) {
//									qu = [qu stringByAppendingFormat:@"%@=%@", inp, @"%@"];
									[postData setObject:@"%@" forKey:[POSTkvp objectAtIndex:0]];
								} else {
									NSMutableArray *kvs = [[POSTkvp mutableCopy] autorelease];
									[kvs removeObjectAtIndex:0];
									NSString *val = [kvs componentsJoinedByString:@"="];
									[postData setObject:val forKey:[POSTkvp objectAtIndex:0]];
//									qu = [qu stringByAppendingString:POSTkv];						
								}
//								qu = [qu stringByAppendingString:@"&"];
							} 
//							qu = [qu substringToIndex:[qu length]-2];
							
//							NSLog(@"POST Search URL: %@ Data: %@", correctURL, postData);
							[self addDiscoveredEngine:[NSString stringWithFormat:@"%@ [searched for %@]", [self figureOutEngineName:[searchEngine stringValue]], word]
												 icon:[[[pageIcon image] copy] autorelease] 
												  url:correctURL
											 postData:postData
											 ianaEncoding:encoding];
							return YES;
					} 
				} else {
//					NSLog(@"empty post");
				}
			}	
			
		}
	}
	
	return NO;
	
}

- (NSString *)ianaEncodingForFrame:(WebFrame *)frame {
	
	WebDataSource *ds = [frame dataSource];
	
	//NSLog(@"about to do text encoding jig ianaEncodingForFrame!");
	if (nil != [frame DOMDocument]) {
		DOMDocument *dd = [frame DOMDocument];
		DOMNodeList *metas = [(DOMHTMLDocument *)dd getElementsByTagName:@"meta"];
		//NSLog(@"metas: %@", metas);
		unsigned long ml = [metas length];
		unsigned long i = 0;
		//NSLog(@"length: %u", ml);
		NSString *metaCharSet = nil;
		for (i = 0; i < ml; i++) {
			DOMNode *n = [metas item:i];
			//NSLog(@"meta-node: %@, class: %@, node name: %@, node value: %@, node type: %d", n, NSStringFromClass([n class]), [n nodeName], [n nodeValue], [n nodeType]);
			DOMHTMLMetaElement *m = (DOMHTMLMetaElement *)n;
			//NSLog(@"meta: %@ tagname: %@ http-equiv: %@, name: %@, content: %@", m, [m tagName], [m httpEquiv], [m name], [m content]);
			if ([[[m httpEquiv] lowercaseString] isEqualToString:@"content-type"]) {
				NSArray *contentTypeComponents = [[m content] componentsSeparatedByString:@"charset"];
				NSString *contentType = [[contentTypeComponents lastObject] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" \t="]];  
				if (contentType != nil && [[contentType stringByTrimmingWhitespace] isNotEqualTo:@""])
					metaCharSet = contentType;
			}
		}
		//NSLog(@"meta tag encoding name: %@", metaCharSet);
		if (metaCharSet != nil)
			return metaCharSet;
	}
	if (nil != [ds mainResource]) {
		//NSLog(@"main resource encoding name: %@", [[ds mainResource] textEncodingName]);
		if (nil != [[ds mainResource] textEncodingName])
			return [[ds mainResource] textEncodingName];
	}
	if (nil != [ds response]) {
		//NSLog(@"response encoding name: %@", [[ds response] textEncodingName]);
		if (nil != [[ds response] textEncodingName])
			return [[ds response] textEncodingName];
		//NSLog(@"response headers: %@", [(NSHTTPURLResponse *)[ds response] allHeaderFields]);
	}
	//NSLog(@"data source encoding name: %@", [ds textEncodingName]);
	if (nil != [[ds mainResource] textEncodingName]) {
		//NSLog(@"text encoding name: %@", [[ds mainResource] textEncodingName]);
		if (nil != [[ds mainResource] textEncodingName])
			return [[ds mainResource] textEncodingName];
//		NSLog(@"translated into int: %d", [NSString stringEncodingForIANA:[[ds mainResource] textEncodingName]]);
	}
	return MonocleSearchEngineDefaultEncoding;
}

- (void)tryToDiscoverSearchEngineForFrame:(WebFrame *)frame {
//	NSLog(@"trying");
	WebDataSource *ds = [frame provisionalDataSource];
	NSURLRequest *req;
	if (nil == ds) {
		//NSLog(@"trying to discover, using data source and request");
		ds = [frame dataSource];
		req = [ds request];
		//NSLog(@"initial headers: %@", [req allHTTPHeaderFields]);
	} else {
		// NSLog(@"trying to discover, using *provisional* data source and initialRequest");	
		req = [ds initialRequest];
	}
/*	NSSet *requests = [NSSet setWithObject:[ds request]];
	if ([[ds request] isNotEqualTo:[ds initialRequest]]) {
		requests = [NSSet setWithObjects:[ds initialRequest], [ds request], nil];
	}
	NSEnumerator *reqEnumerator = [requests objectEnumerator];
	NSURLRequest *req;
	while (req = [reqEnumerator nextObject]) {*/
	if (![[req URL] isOkayForDiscovery]) return;
		// NSLog(@"trying to discover, for request: %@", req);
		if ([[req HTTPMethod] isEqualToString:@"GET"]) {
			if ([[req URL] isOkayForDiscovery]) {
			if ([[[[req URL] description] componentsSeparatedByString:MagicWord] count] > 1) {
				// NSLog(@"Search URL: %@", [[[[req URL] description] componentsSeparatedByString:MagicWord] componentsJoinedByString:@"%@"]);
				
				[self addDiscoveredEngine:[self figureOutEngineName:[searchEngine stringValue]]
									 icon:[[[pageIcon image] copy] autorelease] 
									  url:[[[[req URL] description] componentsSeparatedByString:MagicWord] componentsJoinedByString:@"%@"]
								 postData:nil
							 ianaEncoding:[self ianaEncodingForFrame:frame]];
			}
			}
		} else {
			if ([[req HTTPBody] isNotEqualTo:[NSData data]]) {
			// NSLog(@"POST; HTTP headers: %@", [req allHTTPHeaderFields]);
			// NSLog(@"text encoding name: %@", [[frame dataSource] textEncodingName]);
				//NSLog(@"about to do text encoding jig! (POST)");
				if (nil != [[ds mainResource] textEncodingName]) {
					//NSLog(@"text encoding name: %@", [[ds mainResource] textEncodingName]);
					//NSLog(@"translated into int: %d", [NSString stringEncodingForIANA:[[ds mainResource] textEncodingName]]);
				}
			NSSet *encodings = [NSSet setWithObjects:EmbEnc(NSUTF8StringEncoding), EmbEnc(NSASCIIStringEncoding), EmbEnc(NSISOLatin1StringEncoding), EmbEnc(NSShiftJISStringEncoding), EmbEnc(NSWindowsCP1252StringEncoding), EmbEnc(NSISO2022JPStringEncoding), EmbEnc(NSJapaneseEUCStringEncoding), nil];
			NSString *body;
			NSEnumerator *encEnumerator = [encodings objectEnumerator];
			int enc;
			while (enc = UnbEnc([encEnumerator nextObject])) {
				body = [[[NSString alloc] initWithData:[req HTTPBody] encoding:enc] autorelease];
				if ([[body componentsSeparatedByString:MagicWord] count] > 1) {
					
					NSMutableDictionary *postData = [[NSDictionary dictionary] mutableCopy];
					NSArray *kvp = [[[body componentsSeparatedByString:MagicWord] componentsJoinedByString:@"%@"] componentsSeparatedByString:@"&"];
					NSEnumerator *kvpEnumerator = [kvp objectEnumerator];
					NSString *kv;
					while (kv = [kvpEnumerator nextObject]) {
						NSMutableArray *kvs = [[[kv componentsSeparatedByString:@"="] mutableCopy] autorelease];
						if ([kvs count] < 2) continue;
						NSString *key = [kvs objectAtIndex:0];
						[kvs removeObjectAtIndex:0];
						NSString *val = [kvs componentsJoinedByString:@"="];
						[postData setObject:val forKey:key];
					} 
					
//					NSLog(@"POST Search URL: %@ Data: %@", [[req URL] description], postData);
					[self addDiscoveredEngine:[self figureOutEngineName:[searchEngine stringValue]]
										 icon:[[[pageIcon image] copy] autorelease] 
										  url:[[[[req URL] description] componentsSeparatedByString:MagicWord] componentsJoinedByString:@"%@"]
									 postData:postData
								 ianaEncoding:[self ianaEncodingForFrame:frame]];
					break;
				}
			} 
			} else {
//				NSLog(@"empty post");
			}
		}	
//	} 
//	NSLog(@"done trying to discover");
}

- (NSString *)figureOutEngineName:(NSString *)title {
	NSArray *comps = [title componentsSeparatedByString:MagicWord];
	NSString *work = @"";
	NSEnumerator *compEnumerator = [comps objectEnumerator];
	NSString *comp;
	NSMutableCharacterSet *cs = [[NSCharacterSet whitespaceCharacterSet] mutableCopy];
	[cs formUnionWithCharacterSet:[NSCharacterSet punctuationCharacterSet]];
	while (comp = [compEnumerator nextObject]) {
		work = [work stringByAppendingString:[comp stringByTrimmingCharactersInSet:cs]];
	} 
	[cs release];
	return work; 
}

- (void)awakeFromNib {
	[discoveredEnginesArrayController addObserver:self forKeyPath:@"selection" options:NSKeyValueObservingOptionNew context:NULL];
	// http://bugs.webkit.org/show_bug.cgi?id=16296 says:
	// "Calling [WebIconDatabase sharedIconDatabase] is enough to instantiate the
	// global icon database, enable it, and result in icon loads.  Slapping that
	// one-liner into your - (void)setupIconDatabase; method made it work.
	//
	// It really sucks that the only way to enable part of the API is to use SPI
	// (granted, very stable SPI that's been around forever) but the alternative is to
	// have the overhead of icon loads and multithreading for *all* WebKit apps, which
	// is entirely unacceptable."
	@try {
		Class webIconDatabaseClass = NSClassFromString(@"WebIconDatabase");
		if (webIconDatabaseClass != Nil) {
			[webIconDatabaseClass performSelector:@selector(sharedIconDatabase)];
		}
	} @catch (NSException *exc) {
#pragma unused(exc)
	}
	
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (object == discoveredEnginesArrayController && [keyPath isEqualToString:@"selection"]) {
		[super willChangeValueForKey:@"canRemove"];
		[super didChangeValueForKey:@"canRemove"];		
	} else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}
		 
- (BOOL)canRemove {
	return ([discoveredEnginesArrayController selectionIndex] != NSNotFound);
}

- (void) addDiscoveredEngine:(NSString *)title icon:(NSImage *)icon url:(NSString *)url postData:(NSDictionary *)postData ianaEncoding:(NSString *)enc {
	BOOL isPOST = (postData ? YES : NO);
//	NSLog(@"add discovered engine: %@, icon: %@, url: %@, post data: %@", title, icon, url, (postData ? postData : @"nil"));
	if (!icon) icon = [MonocleGlassIconDrawing imageForSize:NSMakeSize(16.0, 16.0) strokeColor:[NSColor blackColor]];
	
//	WebFrame *frame = [webView mainFrame];
//	WebDataSource *ds = [frame dataSource];
	
	if (![takenURLs containsObject:url]) {
		NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
			title, @"name",
			icon, @"icon",
			url, @"url",
			enc, @"encoding",
			[NSNumber numberWithInt:(isPOST ? 1 : 0)], @"isPOST",
			[NSNumber numberWithInt:++counter], @"uid",
			[NSNumber numberWithBool:NO], @"added",
			nil];
		if (isPOST) {
			NSMutableDictionary *mdict = [[dict mutableCopy] autorelease];
			[mdict setObject:postData forKey:@"postData"];
			dict = mdict;
		}
		[discoveredEngines addObject:dict];
		NSLog(@"added %@", dict);
/*		NSMenuItem *mi = [[NSMenuItem alloc] initWithTitle:[dict objectForKey:@"name"] action:@selector(viewEngineInfo:) keyEquivalent:@""];
		[mi setTarget:self];
		[mi setImage:[dict objectForKey:@"icon"]];
		[mi setRepresentedObject:dict];
		[mi setTag:[[dict objectForKey:@"uid"] intValue]];
		[[discoveredEnginesPopup menu] addItem:[mi autorelease]];*/
		[self rebuildDiscoveredEnginesPopup];
		[takenURLs addObject:url];
	} else {
		NSEnumerator *engineEnumerator = [discoveredEngines objectEnumerator];
		NSDictionary *dict; BOOL hasMatch = NO;
		while (dict = [engineEnumerator nextObject]) {
			if ([[dict objectForKey:@"url"] isEqualToString:url]) {
				hasMatch = YES;
				break;
			}
		} 
		if (hasMatch) {
			NSMutableDictionary *md = [dict mutableCopy];
			[md setObject:icon forKey:@"icon"];
			[md setObject:title forKey:@"name"];
			if (isPOST)
				[md setObject:postData forKey:@"postData"];
			[md setObject:[NSNumber numberWithBool:NO] forKey:@"added"];
			[md setObject:enc forKey:@"encoding"];
			[md setObject:[NSNumber numberWithInt:(isPOST ? 1 : 0)] forKey:@"isPOST"];
			NSLog(@"replaced %@ with %@", dict, md);
			[discoveredEngines replaceObjectAtIndex:[discoveredEngines indexOfObject:dict] withObject:[md autorelease]];
			[self rebuildDiscoveredEnginesPopup];
		}
	}
}

- (void) rebuildDiscoveredEnginesPopup {
	// NSLog(@"rebuildDiscoveredEnginesPopup...");
	/*
	unsigned sele = -1;
	if ([discoveredEnginesPopup numberOfItems] > 0) {
		sele = [discoveredEnginesPopup selectedTag];
		if (sele > MonocleSearchEngineDiscoveryAltItemTag)
			sele -= MonocleSearchEngineDiscoveryAltItemTag;
	}
	NSEnumerator *engineEnumerator = [discoveredEngines objectEnumerator];
	NSDictionary *dict;
	NSMenu *m = [[NSMenu alloc] initWithTitle:@""];
	NSMenuItem *mi;
	while (dict = [engineEnumerator nextObject]) {
		mi = [[NSMenuItem alloc] initWithTitle:[dict objectForKey:@"name"] action:@selector(viewEngineInfo:) keyEquivalent:@""];
		[mi setTarget:self];
		[mi setImage:[dict objectForKey:@"icon"]];
		[mi setRepresentedObject:dict];
		[mi setTag:[[dict objectForKey:@"uid"] intValue]];
		NSNumber *added = [dict objectForKey:@"added"];
		NSMutableAttributedString *att = [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@%@\n", [dict objectForKey:@"name"], ([added boolValue] ? @" (already added)" : @"")] attributes:[NSDictionary dictionaryWithObjectsAndKeys:
			[NSFont menuFontOfSize:[NSFont systemFontSize]], NSFontAttributeName, nil]] mutableCopy];
		[att appendAttributedString:[[NSAttributedString alloc] initWithString:[dict objectForKey:@"url"] attributes:[NSDictionary dictionaryWithObjectsAndKeys:
			[NSFont systemFontOfSize:[NSFont smallSystemFontSize]], NSFontAttributeName,
			[NSColor controlShadowColor], NSForegroundColorAttributeName,
			nil]]];

		[mi setEnabled:(!([added boolValue]))];
		[mi setAttributedTitle:[att autorelease]];
		// NSLog(@"constructing menu item with tag: %i", [[dict objectForKey:@"uid"] intValue]);
		[m addItem:[mi autorelease]];
	}
	[m setAutoenablesItems:NO];
	[discoveredEnginesPopup setMenu:[m autorelease]];
	// NSLog(@"about to select item %i", sele);
	if ((sele > -1) && ([discoveredEnginesPopup selectItemWithTag:sele])) {
		// NSLog(@"yes, that worked");
		[self viewEngineInfo:[discoveredEnginesPopup selectedItem]];
	} else {
		// NSLog(@"it didn't, so let's instead select %i", [discoveredEnginesPopup numberOfItems]-1);
		unsigned i = 0;
		for (i = 0; i < [discoveredEnginesPopup numberOfItems]; i++)
			if ([[discoveredEnginesPopup itemAtIndex:i] isEnabled]) {
				if ([[discoveredEnginesPopup itemAtIndex:i] tag] < MonocleSearchEngineDiscoveryAltItemTag)
					sele = i;
			}
		if (sele < [discoveredEnginesPopup numberOfItems])
			[discoveredEnginesPopup selectItemAtIndex:sele];
		[self viewEngineInfo:[discoveredEnginesPopup selectedItem]];
	}
	[addButton setEnabled:[[discoveredEnginesPopup selectedItem] isEnabled]];
	*/
	[self willChangeValueForKey:@"discoveredEngines"];
	[self didChangeValueForKey:@"discoveredEngines"];
}

- (BOOL)anyEnginesDetected {
	return ([discoveredEngines count] > 0);
}

- (IBAction)deleteSelectedEngines:(id)sender {
	NSIndexSet *selection = [discoveredEnginesArrayController selectionIndexes];
	[discoveredEngines removeObjectsAtIndexes:selection];
	[self rebuildDiscoveredEnginesPopup];
}

- (IBAction) viewEngineInfo:(id)sender {
	// NSLog(@"view engine info: %@ (sender)", sender);
	NSDictionary *dict;	
	if ([sender isNotEqualTo:[NSNull null]]) {
		dict = [sender representedObject];	
	} else {
		dict = [NSDictionary dictionary];
	}
	BOOL addenabled = NO;
	if ([dict objectForKey:@"added"])
		if (![[dict objectForKey:@"added"] boolValue])
			addenabled = YES;
	[addButton setEnabled:addenabled];
	[discPageIcon setImage:[dict objectForKey:@"icon"]];
	[discSearchEngine setStringValue:StrOrNil([dict objectForKey:@"name"])];
	[discVerbIndicator setStringValue:([[dict objectForKey:@"isPOST"] intValue] == 1 ? @"POST" : @"GET")];
	[discSearchURL setStringValue:StrOrNil([dict objectForKey:@"url"])];
}

/*
-(NSURLRequest *)webView:(WebView *)sender resource:(id)identifier willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse fromDataSource:(WebDataSource *)dataSource {
//	// NSLog(@"HTTP headers: %@", [request allHTTPHeaderFields]);
	if ([[[[request URL] description] componentsSeparatedByString:MagicWord] count] > 1) {
		// NSLog(@"Search URL: %@", [[[[request URL] description] componentsSeparatedByString:MagicWord] componentsJoinedByString:@"%@"]);
	}
	
	return request;
}*/

- (void)webView:(WebView *)sender windowScriptObjectAvailable:(WebScriptObject *)windowScriptObject {
//	[windowScriptObject setValue:[NSDictionary dictionary] forKey:@"sidebar"];
	[windowScriptObject setValue:self forKey:@"_sidebar"];
	// Make wrapper object (the actual _sidebar shows up as a typeof function, breaking most scripts (like Mozilla's own) so we need to wrap it).
	[windowScriptObject evaluateWebScript:@"window.sidebar = {addSearchEngine: function(x,y,z,c){ window._sidebar.addSearchEngine(x,y,z,c); } };"];
//	NSLog(@"fixed");
}



- (void)startStuff {
	
	[cogMenuButton setBezelStyle:NSSmallSquareBezelStyle];
	[cogMenuButton setBordered:YES];
	[cogMenuButton setImagePosition:NSImageOnly];
//	[[cogMenuButton cell] setUsesItemFromMenu:NO];
	[[cogMenuButton cell] setArrowPosition:NSPopUpNoArrow];
	if ([[cogMenuButton cell] respondsToSelector:@selector(setImageScaling:)]) {
		[[cogMenuButton cell] setImageScaling:NSScaleProportionally];
	}
	NSString *cogSuffix = @"-small";
	if ([[self window] userSpaceScaleFactor] != 1.0) {
		cogSuffix = @"";
	}
//	NSLog(@"cogSuffix: %@", cogSuffix);
	NSImage *cog = [[NSImage alloc] initByReferencingFile:[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"cog-menu%@", cogSuffix] ofType:@"tiff"]];
	[cog setScalesWhenResized:YES];
//	NSLog(@"cog: %@", cog);
	[[[[cogMenuButton menu] itemArray] objectAtIndex:0] setImage:[cog autorelease]];
	
/*    [backNext setTarget:self];
    [backNext setAction:@selector(segControlClicked:)];*/
/*    [stopReload setTarget:self];
    [stopReload setAction:@selector(segControlClicked:)];*/
	
	NSMenu *m = [[[NSMenu alloc] initWithTitle:@""] autorelease];
	NSMenuItem *mi = [[[NSMenuItem alloc] initWithTitle:@"None yet" action:NULL keyEquivalent:@""] autorelease];
	[mi setEnabled:NO];
	[m addItem:mi];
	[discoveredEnginesPopup setMenu:m];
	[discoveredEnginesPopup display];
	[discoveredEnginesPopup removeAllItems];
	/*
	[discoveredEnginesPopup setBezelStyle:NSRecessedBezelStyle];
	[discoveredEnginesPopup setShowsBorderOnlyWhileMouseInside:YES];
	[discoveredEnginesPopup setBordered:YES];*/
	discoveredEngines = [[NSArray array] mutableCopy];
	takenURLs = [[NSSet set] mutableCopy];
	counter = 1000;
	
	[[webView mainFrame] loadRequest:[NSURLRequest requestWithURL:MonocleSearchEngineDiscoveryInitialPage]];
	
	 blankImage = [MonocleGlassIconDrawing imageForSize:NSMakeSize(16, 16) strokeColor:[NSColor blackColor]];
	 [blankImage retain];
}

+ (NSString *) webScriptNameForSelector:(SEL)sel {

	NSString *name = nil;
	
    if (sel == @selector(addMycroftSearchEngine:iconURL:name:category:))
		name = @"addSearchEngine";
/*	if (sel == @selector(addSearchEngine:))
		name = @"addSearchEngine";*/
	
    return name;
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)aSelector {
	return ([self webScriptNameForSelector:aSelector] == nil);
}

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

- (NSString *)tableView:(NSTableView *)aTableView toolTipForCell:(NSCell *)aCell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)row mouseLocation:(NSPoint)mouseLocation {
	NSString *u = [[discoveredEngines objectAtIndex:row] valueForKey:@"url"];
	return u;
}

- (void)closing {
	[discoveredEngines removeAllObjects];
	[self rebuildDiscoveredEnginesPopup];
}

- (void)saveEngines {
	NSEnumerator *engineEnumerator = [discoveredEngines objectEnumerator];
	NSDictionary *ed;
	NSMutableArray *enginesToAdd = [[NSMutableArray alloc] init];
	while (ed = [engineEnumerator nextObject]) {
		NSMutableDictionary *toPrefs = [[NSDictionary dictionary] mutableCopy];
		
		NSImage *icon = [ed objectForKey:@"icon"];
		if (icon == nil) {
			icon = [MonocleGlassIconDrawing imageForSize:NSMakeSize(16.0, 16.0) strokeColor:[NSColor blackColor]];
		}
		
		[toPrefs setObject:[ed objectForKey:@"name"] forKey:@"name"];
		[toPrefs setObject:[ed objectForKey:@"encoding"] forKey:@"encoding"];
		[toPrefs setObject:[ed objectForKey:@"url"] forKey:@"get_URL"];
		NSValueTransformer *vt = [NSValueTransformer valueTransformerForName:NSUnarchiveFromDataTransformerName];
		[toPrefs setObject:[vt reverseTransformedValue:[ed objectForKey:@"icon"]] forKey:@"icon"];
		[toPrefs setObject:[vt reverseTransformedValue:[[MonocleController controller] deducedColorForImage:[ed objectForKey:@"icon"]]] forKey:@"color"];
		
		BOOL isPOST = [[ed objectForKey:@"isPOST"] boolValue];
		[toPrefs setObject:(isPOST ? @"POST" : @"GET") forKey:@"type"];
		if (isPOST) {
			NSMutableArray *parr = [NSMutableArray array];
			NSDictionary *postData = [ed objectForKey:@"postData"];
			NSEnumerator *keyEnumerator = [postData keyEnumerator];
			NSString *key;
			while (key = [keyEnumerator nextObject]) {
				[parr addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								 key, @"key",
								 [postData objectForKey:key], @"value",
								 nil]];
			} 
			
			[toPrefs setObject:parr forKey:@"post_data"];
			
		}
		[enginesToAdd addObject:[toPrefs autorelease]];
	}

	if ([enginesToAdd count] > 0) {
		[engineController addObjects:enginesToAdd];
	}
	
	[enginesToAdd release];
}

- (void)addSearchEngine:(NSArray *)x {
//	NSLog(@"array: %@", x);
}

- (void)addMycroftSearchEngine:(NSString *)mycroftURL iconURL:(NSString *)iconURL name:(NSString *)name category:(NSString *)category {
//	NSLog(@"add mycroft search engine... url: %@, icon url: %@, name: %@, category: %@", mycroftURL, iconURL, name, category);
	
	cmycroftImageURL = [[NSURL URLWithString:iconURL] retain];
	cmycroftSearchURL = [[NSURL URLWithString:mycroftURL] retain];
	
	NSURL *ur = [NSURL URLWithString:mycroftURL];
	
//	NSString *mycroftSource = [NSString stringWithContentsOfURL:ur]; 
	NSString *xs;
/*	if (!mycroftSource || [[mycroftSource stringByTrimmingWhitespace] isEqualToString:@""]) {*/
		
		NSURLResponse *r;
		NSData *d;
		NSError *er;
		d = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:ur] returningResponse:&r error:&er];
		NSString *enc = [r textEncodingName];
		mycroftEncodingName = [enc copy];
		NSStringEncoding nsse;
//		NSLog(@"returning response: %@, error: %@", r, er);
		if ([r isKindOfClass:[NSHTTPURLResponse class]]) {
//			NSHTTPURLResponse *hr = (NSHTTPURLResponse *)r;
//			enc = [[hr allHeaderFields] objectForKey:@""];
//			NSLog(@"status code: %i", [hr statusCode]);
		}
		if (enc && ![enc isEqualToString:@""]) {
//			NSLog(@"supposed encoding: %@", enc);
			CFStringEncoding cfse = CFStringConvertIANACharSetNameToEncoding((CFStringRef)enc);
			nsse = CFStringConvertEncodingToNSStringEncoding(cfse);
			xs = [[[NSString alloc] initWithData:d encoding:nsse] autorelease];
		} else {
			
			NSString *ilt = [[[NSString alloc] initWithData:d encoding:NSISOLatin1StringEncoding] autorelease];
			NSString *wlt = [[[NSString alloc] initWithData:d encoding:NSWindowsCP1252StringEncoding] autorelease];
			NSString *u8 = [[[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding] autorelease];
//			NSString *u16 = [[NSString alloc] initWithData:d encoding:NSUnicodeStringEncoding];
/*			NSLog(@"omg no encoding");
			NSLog(@"ISO Latin: %@", ilt);
			NSLog(@"Win Latin: %@", wlt);
			NSLog(@"UTF8: %@", u8);*/
			if (([wlt length] >= [u8 length]) && ([wlt length] >= [ilt length]))
				xs = wlt;
			else if (([ilt length] >= [u8 length]) && ([ilt length] >= [wlt length]))
				xs = ilt;
			else
				xs = u8;
		}

		
	NSString *mycroftSource = xs;//[NSString stringWithContentsOfURL:[NSURL URLWithString:mycroftURL]];
//	}
	
	cmycroftImage = [[[NSImage alloc] initWithContentsOfURL:cmycroftImageURL] retain];
//	NSLog(@"mycroft source: %@", mycroftSource);
	NSArray *mycRows = [mycroftSource componentsSeparatedByString:@"\n"];
	NSEnumerator *rowEnumerator = [mycRows objectEnumerator];
	NSString *row;
	NSString *mycSanitized = @"";
	while (row = [rowEnumerator nextObject]) {
		if (![row hasPrefix:@"#"]) {
			mycSanitized = [mycSanitized stringByAppendingString:row];
		}
	} 
	[advancedParser parse:mycSanitized answerSelector:@selector(parserCalledBack:) target:self];
	
}

- (void)parserCalledBack:(NSArray *)collect {
	
	NSArray *document = (NSArray *)[collect objectAtIndex:0];
//	NSString *recon = [collect lastObject];
	NSEnumerator *tagEnumerator = [document objectEnumerator];
	id tag;
	HTMLLikeTag *searchOpenTag = nil;
	HTMLLikeTag *browserTag = nil;
	while (tag = [tagEnumerator nextObject]) {
		if ([tag isKindOfClass:[HTMLLikeTag class]]) {
			HTMLLikeTag *hlt = (HTMLLikeTag *)tag;
			if ([[hlt name] isEqualToString:@"search"]) {
				if (searchOpenTag == nil) {
					searchOpenTag = hlt;
				}
			}
			if ([[hlt name] isEqualToString:@"browser"]) {
				if (browserTag == nil) {
					browserTag = hlt;
				}
			}
		}
	}
	
	NSStringEncoding enc = [NSString stringEncodingForIANA:mycroftEncodingName];
	NSString *iana = mycroftEncodingName;
	
	NSString *seName = @"";
	NSString *url = @"";
	BOOL isPOSTq = NO;
	NSMutableDictionary *postData = nil;
	if (searchOpenTag) {
//		NSLog(@"open search tag: %@", searchOpenTag);
		NSArray *searchkids = [document itemsStartingAt:searchOpenTag]; // more liberal parsing. // kidItemsOf:searchOpenTag];
//		NSLog(@"kids of search tag: %@", searchkids);
		
		if ([[searchOpenTag attributes] objectForKey:@"name"])
			seName = [[searchOpenTag attributes] objectForKey:@"name"];
		if ([[searchOpenTag attributes] objectForKey:@"action"])
			url = [[searchOpenTag attributes] objectForKey:@"action"];
		if ([[searchOpenTag attributes] objectForKey:@"method"]) {
			if ([(NSString *)[[[searchOpenTag attributes] objectForKey:@"method"] uppercaseString] isEqualToString:@"POST"]) {
				isPOSTq = YES;
			}
		}
		
		BOOL hasStarted = NO;
		
		NSEnumerator *skEnumerator = [searchkids objectEnumerator];
		id sk;
		while (sk = [skEnumerator nextObject]) {
//			NSLog(@"enumerating searchkids, %@", sk);
			if ([sk isKindOfClass:[HTMLLikeTag class]]) {
				HTMLLikeTag *lt = (HTMLLikeTag *)sk;
//				NSLog(@" - is tag %@", lt);
				if ([[lt name] isEqualToString:@"input"]) {
//					NSLog(@" - - is input");					
					NSDictionary *d = [lt attributes];
					NSString *n = [d objectForKey:@"name"];
					NSString *u = [d objectForKey:@"user"];
					NSString *v = [d objectForKey:@"value"];
					if (!n || [(NSString *)n isEqualToString:@""]) continue;
					
					if (!isPOSTq) {
						if (hasStarted) url = [url stringByAppendingString:@"&"];
						if (!hasStarted) url = [url stringByAppendingString:@"?"];
						hasStarted = YES;
						
						if (u)
							url = [url stringByAppendingFormat:@"%@=%@", n, @"%@"];
						else
							url = [url stringByAppendingFormat:@"%@=%@", n, [v stringByAddingPercentEscapesUsingEncoding:enc]];
					} else {
						if (!postData) postData = [[NSDictionary dictionary] mutableCopy];
						[postData setObject:(u ? @"%@" : [v stringByAddingPercentEscapesUsingEncoding:enc]) forKey:n];
					}	
					
//					NSLog(@"appened argument %@", n);
//					NSLog(@"user argument? %@", ([u isEqualToString:@"user"] ? @"yup" : @"nope"));
					
				}
			}
		} 
	}
	
/*	if (browserTag) {
		NSString *newupdate
		if ([[browserTag attributes] objectForKey:@"updateicon"]) {
			
		}
	}*/
	
	[self addDiscoveredEngine:seName icon:cmycroftImage url:url postData:postData ianaEncoding:[iana autorelease]];
	
	[seName release];
	[cmycroftImage release];
	[url release];
	

//	NSLog(@"parser returned: %@", document);
//	NSLog(@"\n\n\n--\n\nreconstr: %@", recon);
}

- (void)webView:(WebView *)sender runJavaScriptAlertPanelWithMessage:(NSString *)message {
//	NSLog(@"javascript alert: %@", message);
}

- (BOOL)webView:(WebView *)sender runJavaScriptConfirmPanelWithMessage:(NSString *)message {
//	NSLog(@"javascript confirm: %@", message);
	return YES;
}

- (IBAction)segControlClicked:(id)sender
{
/*    int clickedSegment = [sender selectedSegment];
    int clickedSegmentTag = [[sender cell] tagForSegment:clickedSegment];
	switch (clickedSegmentTag) {
		case EDGoBackTag:
			[webView goBack:self];
			break;
		case EDGoForwardTag:
			[webView goForward:self];
			break;
		case EDReloadTag:
			[webView stopLoading:self];
			[webView reload:self];
			break;
		case EDStopTag:
			[webView stopLoading:self];
			break;
	}*/
}
- (IBAction)addClicked:(id)sender {
//	[[[[discoveredEnginesPopup selectedItem] image] TIFFRepresentation] writeToFile:[@"~/Desktop/addedicon.tiff" stringByExpandingTildeInPath] atomically:YES];
	NSDictionary *ed = [[discoveredEnginesPopup selectedItem] representedObject];
//	NSLog(@"engine to add: %@", ed);
	
	NSMutableDictionary *toPrefs = [[NSDictionary dictionary] mutableCopy];
	
	NSImage *icon = [ed objectForKey:@"icon"];
	if (icon == nil) {
		icon = [MonocleGlassIconDrawing imageForSize:NSMakeSize(16.0, 16.0) strokeColor:[NSColor blackColor]];
	}
	
	[toPrefs setObject:[ed objectForKey:@"name"] forKey:@"name"];
	[toPrefs setObject:[ed objectForKey:@"encoding"] forKey:@"encoding"];
	[toPrefs setObject:[ed objectForKey:@"url"] forKey:@"get_URL"];
	NSValueTransformer *vt = [NSValueTransformer valueTransformerForName:NSUnarchiveFromDataTransformerName];
	[toPrefs setObject:[vt reverseTransformedValue:[ed objectForKey:@"icon"]] forKey:@"icon"];
	BOOL isPOST = [[ed objectForKey:@"isPOST"] boolValue];
	[toPrefs setObject:(isPOST ? @"POST" : @"GET") forKey:@"type"];
	if (isPOST) {
		NSMutableArray *parr = [NSMutableArray array];
		NSDictionary *postData = [ed objectForKey:@"postData"];
		NSEnumerator *keyEnumerator = [postData keyEnumerator];
		NSString *key;
		while (key = [keyEnumerator nextObject]) {
			[parr addObject:[NSDictionary dictionaryWithObjectsAndKeys:
				key, @"key",
				[postData objectForKey:key], @"value",
				nil]];
		} 
		
		[toPrefs setObject:parr forKey:@"post_data"];
		
	}
	
//	NSLog(@"to prefs: %@", toPrefs);
	
	[engineController addObject:[toPrefs autorelease]];
	
	NSEnumerator *engineEnumerator = [discoveredEngines objectEnumerator];
	NSDictionary *dict; BOOL hasMatch = NO;
	while (dict = [engineEnumerator nextObject]) {
		if ([[dict objectForKey:@"uid"] isEqualTo:[ed objectForKey:@"uid"]]) {
			hasMatch = YES;
			break;
		}
	} 
	if (hasMatch) {
		NSMutableDictionary *md = [dict mutableCopy];
		[md setObject:[NSNumber numberWithBool:YES] forKey:@"added"];
		[discoveredEngines replaceObjectAtIndex:[discoveredEngines indexOfObject:dict] withObject:[md autorelease]];
		[self rebuildDiscoveredEnginesPopup];
	}
}

- (IBAction)goToWebsite:(id)sender {
	if (![sender isKindOfClass:[NSTextField class]]) return;
	NSTextField *tf = (NSTextField *)sender;
	NSString *str = [tf stringValue];
//	if ([str isEqualToString:[[[[[webView mainFrame] dataSource] request] URL] absoluteString]]) return;
	if ([[str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""]) return;
	if (NSEqualRanges([str rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"."]],NSMakeRange(NSNotFound,0))) {
		str = [NSString stringWithFormat:@"www.%@.com", str];
	}
	if (!([str hasPrefix:@"http://"] || [str hasPrefix:@"https://"])) {
		str = [NSString stringWithFormat:@"http://%@%@", str, ([[str componentsSeparatedByString:@"/"] count] < 2) ? @"/" : @""];
	}
	[tf setStringValue:str];
	[webView takeStringURLFrom:tf]; 
	[[self window] makeFirstResponder:webView];
}

- (IBAction)showInstructions:(id)sender {
	[[webView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"instructions" ofType:@"html"]]]];
}

- (IBAction)selectLoc:(id)sender {
	[urlField selectText:self];
}

@end
