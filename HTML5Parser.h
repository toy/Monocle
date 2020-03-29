//
//  HTML5Parser.h
//  html5parser
//
//  Created by Jesper on 2006-04-26.
//  Copyright 2006 waffle software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class HTML5Document, HTMLLikeTag;

typedef enum _ContentModelFlag {
  PCDataContentModel,
  RCDataContentModel,
  CDataContentModel,
  PlainTextContentModel,
} ContentModelFlag;

typedef enum _HTML5ParseState {

  NoState = -1,

  DataState,
  EntityDataState,
  TagOpenState,
  CloseTagOpenState,

  MarkedSectionOpenState,
  TagNameState,

  CommentState,
  CommentDashState,
  CommentEndState,
  BogusCommentState,

  DOCTYPEState,
  BeforeDOCTYPENameState,
  DOCTYPENameState,
  AfterDOCTYPENameState,
  BogusDOCTYPEState,

  BeforeAttributeNameState,
  AttributeNameState,
  AfterAttributeNameState,

  BeforeAttributeValueState,
  AttributeValueUQState, /* unquoted */
  AttributeValueSQState, /* single quotes */
  AttributeValueDQState, /* double quotes */

  EntityInAttributeValueState,

} HTML5ParseState;

@interface HTML5Parser : NSObject {
  ContentModelFlag contentModel;
  HTML5ParseState parseState;
  HTML5ParseState secondaryParseState;
  BOOL isAtEOF;

  unsigned int currentLocation;
  NSString *currentString;
  NSString *charAtPos;

  NSString *outputString;

  unsigned int tickCounter;

  NSString *currentToken;
  NSString *latestTag;
  NSMutableDictionary *currentTokenInfo;

  HTML5Document *doc;

  NSMutableArray *currentDocument;
  NSString *currentTagName;
  NSDictionary *currentAttributes;

  NSDate *startDate;
  NSDate *endDate;

  SEL answerSel;
  id answerTar;

  NSArray *_synchronousResult;

  IBOutlet NSTextView *emitted;
  IBOutlet NSTextView *parseFodder;
  IBOutlet NSTextField *ticks;
  IBOutlet NSSlider *tickRoof;
  IBOutlet NSTextField *tickRoofLabel;
  IBOutlet NSProgressIndicator *pi;
}
- (NSString *)characterAtPosition;
- (void)consume;
- (void)parse:(NSString *)string;

- (void)parse:(NSString *)string answerSelector:(SEL)selector target:(id)target;
- (NSArray *)parseSynchronously:(NSString *)str;

// private:
- (NSString *)consumeEntity:(NSString *)str;
- (void)doEOFCleanup;

//- (IBAction)reparse:(id)sender;

- (void)emitString:(NSString *)str;
- (void)emitStringButDoNotAdvance:(NSString *)str;
//- (void)emitCurrentToken;

//- (BOOL)areWeAtEOF;
- (void)parseError;

- (void)advance;
- (void)advanceBy:(int)i;
- (void)retreat;
- (void)retreatBy:(int)i;

//- (BOOL)canScanCharactersInSet:(NSCharacterSet *)cs inString:(NSString *)str;
//- (BOOL)canScanTabLFVertabFFSpaceInString:(NSString *)str;
@end

@interface NSString (HTML5Additions)
- (NSString *)stringByTrimmingWhitespace;
@end

@interface NSArray (HTML5Additions)

- (NSArray *)itemsStartingAt:(id)firstObject;
//- (NSArray *)itemsEndingWith:(id)firstObject;
- (NSArray *)itemsBetween:(id)firstObject and:(id)secondObject;
- (HTMLLikeTag *)closingTagFor:(HTMLLikeTag *)openingTag;
//- (HTMLLikeTag *)openingTagFor:(HTMLLikeTag *)closingTag;
- (NSArray *)kidItemsOf:(HTMLLikeTag *)openingTag;

@end

@interface HTMLString : NSObject {
  NSString *_string;
}
+ (id)htmlStringWithString:(NSString *)str;
- (NSString *)stringValue;
@end
