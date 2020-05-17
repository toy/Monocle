//
//	HTML5Parser.m
//	html5parser
//
//	Created by Jesper on 2006-04-26.
//	Copyright 2006 waffle software. All rights reserved.
//

/** HTML5Parser, a shot at writing an HTML5 parser according to section 8
*** of "Web Applications 1.0", published by the WHATWG.
***
*** This version based on http://www.whatwg.org/specs/web-apps/current-work/
*** as of 2006-04-26.
**/

#import "HTML5Parser.h"
#import "HTMLLikeTag.h"

@interface HTMLString (Private)
- (void)_setPrimitiveString:(NSString *)str;
@end

/*@interface Tag : NSObject {
  NSDictionary *attributes;
  NSString *tagName;
  NSString *content;
}
- (NSDictionary *)attributes;
- (NSDictionary *)dictRepresentation;
- (NSString *)content;
- (NSString *)name;
- (BOOL)isEmpty;
+ (id)tagWithName:(NSString *)name attributes:(NSDictionary *)attrs content:(NSString *)co;
+ (id)tagWithDictRepresentation:(NSDictionary *)dict;
@end*/

#define HTMLEntitiesToNumbers                                                 \
  [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:0x00C6], \
                @"AElig",                                                     \
                [NSNumber numberWithInt:0x00C1],                              \
                @"Aacute",                                                    \
                [NSNumber numberWithInt:0x00C2],                              \
                @"Acirc",                                                     \
                [NSNumber numberWithInt:0x00C0],                              \
                @"Agrave",                                                    \
                [NSNumber numberWithInt:0x0391],                              \
                @"Alpha",                                                     \
                [NSNumber numberWithInt:0x00C5],                              \
                @"Aring",                                                     \
                [NSNumber numberWithInt:0x00C3],                              \
                @"Atilde",                                                    \
                [NSNumber numberWithInt:0x00C4],                              \
                @"Auml",                                                      \
                [NSNumber numberWithInt:0x0392],                              \
                @"Beta",                                                      \
                [NSNumber numberWithInt:0x00C7],                              \
                @"Ccedil",                                                    \
                [NSNumber numberWithInt:0x03A7],                              \
                @"Chi",                                                       \
                [NSNumber numberWithInt:0x2021],                              \
                @"Dagger",                                                    \
                [NSNumber numberWithInt:0x0394],                              \
                @"Delta",                                                     \
                [NSNumber numberWithInt:0x00D0],                              \
                @"ETH",                                                       \
                [NSNumber numberWithInt:0x00C9],                              \
                @"Eacute",                                                    \
                [NSNumber numberWithInt:0x00CA],                              \
                @"Ecirc",                                                     \
                [NSNumber numberWithInt:0x00C8],                              \
                @"Egrave",                                                    \
                [NSNumber numberWithInt:0x0395],                              \
                @"Epsilon",                                                   \
                [NSNumber numberWithInt:0x0397],                              \
                @"Eta",                                                       \
                [NSNumber numberWithInt:0x00CB],                              \
                @"Euml",                                                      \
                [NSNumber numberWithInt:0x0393],                              \
                @"Gamma",                                                     \
                [NSNumber numberWithInt:0x00CD],                              \
                @"Iacute",                                                    \
                [NSNumber numberWithInt:0x00CE],                              \
                @"Icirc",                                                     \
                [NSNumber numberWithInt:0x00CC],                              \
                @"Igrave",                                                    \
                [NSNumber numberWithInt:0x0399],                              \
                @"Iota",                                                      \
                [NSNumber numberWithInt:0x00CF],                              \
                @"Iuml",                                                      \
                [NSNumber numberWithInt:0x039A],                              \
                @"Kappa",                                                     \
                [NSNumber numberWithInt:0x039B],                              \
                @"Lambda",                                                    \
                [NSNumber numberWithInt:0x039C],                              \
                @"Mu",                                                        \
                [NSNumber numberWithInt:0x00D1],                              \
                @"Ntilde",                                                    \
                [NSNumber numberWithInt:0x039D],                              \
                @"Nu",                                                        \
                [NSNumber numberWithInt:0x0152],                              \
                @"OElig",                                                     \
                [NSNumber numberWithInt:0x00D3],                              \
                @"Oacute",                                                    \
                [NSNumber numberWithInt:0x00D4],                              \
                @"Ocirc",                                                     \
                [NSNumber numberWithInt:0x00D2],                              \
                @"Ograve",                                                    \
                [NSNumber numberWithInt:0x03A9],                              \
                @"Omega",                                                     \
                [NSNumber numberWithInt:0x039F],                              \
                @"Omicron",                                                   \
                [NSNumber numberWithInt:0x00D8],                              \
                @"Oslash",                                                    \
                [NSNumber numberWithInt:0x00D5],                              \
                @"Otilde",                                                    \
                [NSNumber numberWithInt:0x00D6],                              \
                @"Ouml",                                                      \
                [NSNumber numberWithInt:0x03A6],                              \
                @"Phi",                                                       \
                [NSNumber numberWithInt:0x03A0],                              \
                @"Pi",                                                        \
                [NSNumber numberWithInt:0x2033],                              \
                @"Prime",                                                     \
                [NSNumber numberWithInt:0x03A8],                              \
                @"Psi",                                                       \
                [NSNumber numberWithInt:0x03A1],                              \
                @"Rho",                                                       \
                [NSNumber numberWithInt:0x0160],                              \
                @"Scaron",                                                    \
                [NSNumber numberWithInt:0x03A3],                              \
                @"Sigma",                                                     \
                [NSNumber numberWithInt:0x00DE],                              \
                @"THORN",                                                     \
                [NSNumber numberWithInt:0x03A4],                              \
                @"Tau",                                                       \
                [NSNumber numberWithInt:0x0398],                              \
                @"Theta",                                                     \
                [NSNumber numberWithInt:0x00DA],                              \
                @"Uacute",                                                    \
                [NSNumber numberWithInt:0x00DB],                              \
                @"Ucirc",                                                     \
                [NSNumber numberWithInt:0x00D9],                              \
                @"Ugrave",                                                    \
                [NSNumber numberWithInt:0x03A5],                              \
                @"Upsilon",                                                   \
                [NSNumber numberWithInt:0x00DC],                              \
                @"Uuml",                                                      \
                [NSNumber numberWithInt:0x039E],                              \
                @"Xi",                                                        \
                [NSNumber numberWithInt:0x00DD],                              \
                @"Yacute",                                                    \
                [NSNumber numberWithInt:0x0178],                              \
                @"Yuml",                                                      \
                [NSNumber numberWithInt:0x0396],                              \
                @"Zeta",                                                      \
                [NSNumber numberWithInt:0x00E1],                              \
                @"aacute",                                                    \
                [NSNumber numberWithInt:0x00E2],                              \
                @"acirc",                                                     \
                [NSNumber numberWithInt:0x00B4],                              \
                @"acute",                                                     \
                [NSNumber numberWithInt:0x00E6],                              \
                @"aelig",                                                     \
                [NSNumber numberWithInt:0x00E0],                              \
                @"agrave",                                                    \
                [NSNumber numberWithInt:0x2135],                              \
                @"alefsym",                                                   \
                [NSNumber numberWithInt:0x03B1],                              \
                @"alpha",                                                     \
                [NSNumber numberWithInt:0x0026],                              \
                @"amp",                                                       \
                [NSNumber numberWithInt:0x0026],                              \
                @"AMP",                                                       \
                [NSNumber numberWithInt:0x2227],                              \
                @"and",                                                       \
                [NSNumber numberWithInt:0x2220],                              \
                @"ang",                                                       \
                [NSNumber numberWithInt:0x0027],                              \
                @"apos",                                                      \
                [NSNumber numberWithInt:0x00E5],                              \
                @"aring",                                                     \
                [NSNumber numberWithInt:0x2248],                              \
                @"asymp",                                                     \
                [NSNumber numberWithInt:0x00E3],                              \
                @"atilde",                                                    \
                [NSNumber numberWithInt:0x00E4],                              \
                @"auml",                                                      \
                [NSNumber numberWithInt:0x201E],                              \
                @"bdquo",                                                     \
                [NSNumber numberWithInt:0x03B2],                              \
                @"beta",                                                      \
                [NSNumber numberWithInt:0x00A6],                              \
                @"brvbar",                                                    \
                [NSNumber numberWithInt:0x2022],                              \
                @"bull",                                                      \
                [NSNumber numberWithInt:0x2229],                              \
                @"cap",                                                       \
                [NSNumber numberWithInt:0x00E7],                              \
                @"ccedil",                                                    \
                [NSNumber numberWithInt:0x00B8],                              \
                @"cedil",                                                     \
                [NSNumber numberWithInt:0x00A2],                              \
                @"cent",                                                      \
                [NSNumber numberWithInt:0x03C7],                              \
                @"chi",                                                       \
                [NSNumber numberWithInt:0x02C6],                              \
                @"circ",                                                      \
                [NSNumber numberWithInt:0x2663],                              \
                @"clubs",                                                     \
                [NSNumber numberWithInt:0x2245],                              \
                @"cong",                                                      \
                [NSNumber numberWithInt:0x00A9],                              \
                @"copy",                                                      \
                [NSNumber numberWithInt:0x00A9],                              \
                @"COPY",                                                      \
                [NSNumber numberWithInt:0x21B5],                              \
                @"crarr",                                                     \
                [NSNumber numberWithInt:0x222A],                              \
                @"cup",                                                       \
                [NSNumber numberWithInt:0x00A4],                              \
                @"curren",                                                    \
                [NSNumber numberWithInt:0x21D3],                              \
                @"dArr",                                                      \
                [NSNumber numberWithInt:0x2020],                              \
                @"dagger",                                                    \
                [NSNumber numberWithInt:0x2193],                              \
                @"darr",                                                      \
                [NSNumber numberWithInt:0x00B0],                              \
                @"deg",                                                       \
                [NSNumber numberWithInt:0x03B4],                              \
                @"delta",                                                     \
                [NSNumber numberWithInt:0x2666],                              \
                @"diams",                                                     \
                [NSNumber numberWithInt:0x00F7],                              \
                @"divide",                                                    \
                [NSNumber numberWithInt:0x00E9],                              \
                @"eacute",                                                    \
                [NSNumber numberWithInt:0x00EA],                              \
                @"ecirc",                                                     \
                [NSNumber numberWithInt:0x00E8],                              \
                @"egrave",                                                    \
                [NSNumber numberWithInt:0x2205],                              \
                @"empty",                                                     \
                [NSNumber numberWithInt:0x2003],                              \
                @"emsp",                                                      \
                [NSNumber numberWithInt:0x2002],                              \
                @"ensp",                                                      \
                [NSNumber numberWithInt:0x03B5],                              \
                @"epsilon",                                                   \
                [NSNumber numberWithInt:0x2261],                              \
                @"equiv",                                                     \
                [NSNumber numberWithInt:0x03B7],                              \
                @"eta",                                                       \
                [NSNumber numberWithInt:0x00F0],                              \
                @"eth",                                                       \
                [NSNumber numberWithInt:0x00EB],                              \
                @"euml",                                                      \
                [NSNumber numberWithInt:0x20AC],                              \
                @"euro",                                                      \
                [NSNumber numberWithInt:0x2203],                              \
                @"exist",                                                     \
                [NSNumber numberWithInt:0x0192],                              \
                @"fnof",                                                      \
                [NSNumber numberWithInt:0x2200],                              \
                @"forall",                                                    \
                [NSNumber numberWithInt:0x00BD],                              \
                @"frac12",                                                    \
                [NSNumber numberWithInt:0x00BC],                              \
                @"frac14",                                                    \
                [NSNumber numberWithInt:0x00BE],                              \
                @"frac34",                                                    \
                [NSNumber numberWithInt:0x2044],                              \
                @"frasl",                                                     \
                [NSNumber numberWithInt:0x03B3],                              \
                @"gamma",                                                     \
                [NSNumber numberWithInt:0x2265],                              \
                @"ge",                                                        \
                [NSNumber numberWithInt:0x003E],                              \
                @"gt",                                                        \
                [NSNumber numberWithInt:0x003E],                              \
                @"GT",                                                        \
                [NSNumber numberWithInt:0x21D4],                              \
                @"hArr",                                                      \
                [NSNumber numberWithInt:0x2194],                              \
                @"harr",                                                      \
                [NSNumber numberWithInt:0x2665],                              \
                @"hearts",                                                    \
                [NSNumber numberWithInt:0x2026],                              \
                @"hellip",                                                    \
                [NSNumber numberWithInt:0x00ED],                              \
                @"iacute",                                                    \
                [NSNumber numberWithInt:0x00EE],                              \
                @"icirc",                                                     \
                [NSNumber numberWithInt:0x00A1],                              \
                @"iexcl",                                                     \
                [NSNumber numberWithInt:0x00EC],                              \
                @"igrave",                                                    \
                [NSNumber numberWithInt:0x2111],                              \
                @"image",                                                     \
                [NSNumber numberWithInt:0x221E],                              \
                @"infin",                                                     \
                [NSNumber numberWithInt:0x222B],                              \
                @"int",                                                       \
                [NSNumber numberWithInt:0x03B9],                              \
                @"iota",                                                      \
                [NSNumber numberWithInt:0x00BF],                              \
                @"iquest",                                                    \
                [NSNumber numberWithInt:0x2208],                              \
                @"isin",                                                      \
                [NSNumber numberWithInt:0x00EF],                              \
                @"iuml",                                                      \
                [NSNumber numberWithInt:0x03BA],                              \
                @"kappa",                                                     \
                [NSNumber numberWithInt:0x21D0],                              \
                @"lArr",                                                      \
                [NSNumber numberWithInt:0x03BB],                              \
                @"lambda",                                                    \
                [NSNumber numberWithInt:0x2329],                              \
                @"lang",                                                      \
                [NSNumber numberWithInt:0x00AB],                              \
                @"laquo",                                                     \
                [NSNumber numberWithInt:0x2190],                              \
                @"larr",                                                      \
                [NSNumber numberWithInt:0x2308],                              \
                @"lceil",                                                     \
                [NSNumber numberWithInt:0x201C],                              \
                @"ldquo",                                                     \
                [NSNumber numberWithInt:0x2264],                              \
                @"le",                                                        \
                [NSNumber numberWithInt:0x230A],                              \
                @"lfloor",                                                    \
                [NSNumber numberWithInt:0x2217],                              \
                @"lowast",                                                    \
                [NSNumber numberWithInt:0x25CA],                              \
                @"loz",                                                       \
                [NSNumber numberWithInt:0x200E],                              \
                @"lrm",                                                       \
                [NSNumber numberWithInt:0x2039],                              \
                @"lsaquo",                                                    \
                [NSNumber numberWithInt:0x2018],                              \
                @"lsquo",                                                     \
                [NSNumber numberWithInt:0x003C],                              \
                @"lt",                                                        \
                [NSNumber numberWithInt:0x003C],                              \
                @"LT",                                                        \
                [NSNumber numberWithInt:0x00AF],                              \
                @"macr",                                                      \
                [NSNumber numberWithInt:0x2014],                              \
                @"mdash",                                                     \
                [NSNumber numberWithInt:0x00B5],                              \
                @"micro",                                                     \
                [NSNumber numberWithInt:0x00B7],                              \
                @"middot",                                                    \
                [NSNumber numberWithInt:0x2212],                              \
                @"minus",                                                     \
                [NSNumber numberWithInt:0x03BC],                              \
                @"mu",                                                        \
                [NSNumber numberWithInt:0x2207],                              \
                @"nabla",                                                     \
                [NSNumber numberWithInt:0x00A0],                              \
                @"nbsp",                                                      \
                [NSNumber numberWithInt:0x2013],                              \
                @"ndash",                                                     \
                [NSNumber numberWithInt:0x2260],                              \
                @"ne",                                                        \
                [NSNumber numberWithInt:0x220B],                              \
                @"ni",                                                        \
                [NSNumber numberWithInt:0x00AC],                              \
                @"not",                                                       \
                [NSNumber numberWithInt:0x2209],                              \
                @"notin",                                                     \
                [NSNumber numberWithInt:0x2284],                              \
                @"nsub",                                                      \
                [NSNumber numberWithInt:0x00F1],                              \
                @"ntilde",                                                    \
                [NSNumber numberWithInt:0x03BD],                              \
                @"nu",                                                        \
                [NSNumber numberWithInt:0x00F3],                              \
                @"oacute",                                                    \
                [NSNumber numberWithInt:0x00F4],                              \
                @"ocirc",                                                     \
                [NSNumber numberWithInt:0x0153],                              \
                @"oelig",                                                     \
                [NSNumber numberWithInt:0x00F2],                              \
                @"ograve",                                                    \
                [NSNumber numberWithInt:0x203E],                              \
                @"oline",                                                     \
                [NSNumber numberWithInt:0x03C9],                              \
                @"omega",                                                     \
                [NSNumber numberWithInt:0x03BF],                              \
                @"omicron",                                                   \
                [NSNumber numberWithInt:0x2295],                              \
                @"oplus",                                                     \
                [NSNumber numberWithInt:0x2228],                              \
                @"or",                                                        \
                [NSNumber numberWithInt:0x00AA],                              \
                @"ordf",                                                      \
                [NSNumber numberWithInt:0x00BA],                              \
                @"ordm",                                                      \
                [NSNumber numberWithInt:0x00F8],                              \
                @"oslash",                                                    \
                [NSNumber numberWithInt:0x00F5],                              \
                @"otilde",                                                    \
                [NSNumber numberWithInt:0x2297],                              \
                @"otimes",                                                    \
                [NSNumber numberWithInt:0x00F6],                              \
                @"ouml",                                                      \
                [NSNumber numberWithInt:0x00B6],                              \
                @"para",                                                      \
                [NSNumber numberWithInt:0x2202],                              \
                @"part",                                                      \
                [NSNumber numberWithInt:0x2030],                              \
                @"permil",                                                    \
                [NSNumber numberWithInt:0x22A5],                              \
                @"perp",                                                      \
                [NSNumber numberWithInt:0x03C6],                              \
                @"phi",                                                       \
                [NSNumber numberWithInt:0x03C0],                              \
                @"pi",                                                        \
                [NSNumber numberWithInt:0x03D6],                              \
                @"piv",                                                       \
                [NSNumber numberWithInt:0x00B1],                              \
                @"plusmn",                                                    \
                [NSNumber numberWithInt:0x00A3],                              \
                @"pound",                                                     \
                [NSNumber numberWithInt:0x2032],                              \
                @"prime",                                                     \
                [NSNumber numberWithInt:0x220F],                              \
                @"prod",                                                      \
                [NSNumber numberWithInt:0x221D],                              \
                @"prop",                                                      \
                [NSNumber numberWithInt:0x03C8],                              \
                @"psi",                                                       \
                [NSNumber numberWithInt:0x0022],                              \
                @"quot",                                                      \
                [NSNumber numberWithInt:0x0022],                              \
                @"QUOT",                                                      \
                [NSNumber numberWithInt:0x21D2],                              \
                @"rArr",                                                      \
                [NSNumber numberWithInt:0x221A],                              \
                @"radic",                                                     \
                [NSNumber numberWithInt:0x232A],                              \
                @"rang",                                                      \
                [NSNumber numberWithInt:0x00BB],                              \
                @"raquo",                                                     \
                [NSNumber numberWithInt:0x2192],                              \
                @"rarr",                                                      \
                [NSNumber numberWithInt:0x2309],                              \
                @"rceil",                                                     \
                [NSNumber numberWithInt:0x201D],                              \
                @"rdquo",                                                     \
                [NSNumber numberWithInt:0x211C],                              \
                @"real",                                                      \
                [NSNumber numberWithInt:0x00AE],                              \
                @"reg",                                                       \
                [NSNumber numberWithInt:0x00AE],                              \
                @"REG",                                                       \
                [NSNumber numberWithInt:0x230B],                              \
                @"rfloor",                                                    \
                [NSNumber numberWithInt:0x03C1],                              \
                @"rho",                                                       \
                [NSNumber numberWithInt:0x200F],                              \
                @"rlm",                                                       \
                [NSNumber numberWithInt:0x203A],                              \
                @"rsaquo",                                                    \
                [NSNumber numberWithInt:0x2019],                              \
                @"rsquo",                                                     \
                [NSNumber numberWithInt:0x201A],                              \
                @"sbquo",                                                     \
                [NSNumber numberWithInt:0x0161],                              \
                @"scaron",                                                    \
                [NSNumber numberWithInt:0x22C5],                              \
                @"sdot",                                                      \
                [NSNumber numberWithInt:0x00A7],                              \
                @"sect",                                                      \
                [NSNumber numberWithInt:0x00AD],                              \
                @"shy",                                                       \
                [NSNumber numberWithInt:0x03C3],                              \
                @"sigma",                                                     \
                [NSNumber numberWithInt:0x03C2],                              \
                @"sigmaf",                                                    \
                [NSNumber numberWithInt:0x223C],                              \
                @"sim",                                                       \
                [NSNumber numberWithInt:0x2660],                              \
                @"spades",                                                    \
                [NSNumber numberWithInt:0x2282],                              \
                @"sub",                                                       \
                [NSNumber numberWithInt:0x2286],                              \
                @"sube",                                                      \
                [NSNumber numberWithInt:0x2211],                              \
                @"sum",                                                       \
                [NSNumber numberWithInt:0x2283],                              \
                @"sup",                                                       \
                [NSNumber numberWithInt:0x00B9],                              \
                @"sup1",                                                      \
                [NSNumber numberWithInt:0x00B2],                              \
                @"sup2",                                                      \
                [NSNumber numberWithInt:0x00B3],                              \
                @"sup3",                                                      \
                [NSNumber numberWithInt:0x2287],                              \
                @"supe",                                                      \
                [NSNumber numberWithInt:0x00DF],                              \
                @"szlig",                                                     \
                [NSNumber numberWithInt:0x03C4],                              \
                @"tau",                                                       \
                [NSNumber numberWithInt:0x2234],                              \
                @"there4",                                                    \
                [NSNumber numberWithInt:0x03B8],                              \
                @"theta",                                                     \
                [NSNumber numberWithInt:0x03D1],                              \
                @"thetasym",                                                  \
                [NSNumber numberWithInt:0x2009],                              \
                @"thinsp",                                                    \
                [NSNumber numberWithInt:0x00FE],                              \
                @"thorn",                                                     \
                [NSNumber numberWithInt:0x02DC],                              \
                @"tilde",                                                     \
                [NSNumber numberWithInt:0x00D7],                              \
                @"times",                                                     \
                [NSNumber numberWithInt:0x2122],                              \
                @"trade",                                                     \
                [NSNumber numberWithInt:0x21D1],                              \
                @"uArr",                                                      \
                [NSNumber numberWithInt:0x00FA],                              \
                @"uacute",                                                    \
                [NSNumber numberWithInt:0x2191],                              \
                @"uarr",                                                      \
                [NSNumber numberWithInt:0x00FB],                              \
                @"ucirc",                                                     \
                [NSNumber numberWithInt:0x00F9],                              \
                @"ugrave",                                                    \
                [NSNumber numberWithInt:0x00A8],                              \
                @"uml",                                                       \
                [NSNumber numberWithInt:0x03D2],                              \
                @"upsih",                                                     \
                [NSNumber numberWithInt:0x03C5],                              \
                @"upsilon",                                                   \
                [NSNumber numberWithInt:0x00FC],                              \
                @"uuml",                                                      \
                [NSNumber numberWithInt:0x2118],                              \
                @"weierp",                                                    \
                [NSNumber numberWithInt:0x03BE],                              \
                @"xi",                                                        \
                [NSNumber numberWithInt:0x00FD],                              \
                @"yacute",                                                    \
                [NSNumber numberWithInt:0x00A5],                              \
                @"yen",                                                       \
                [NSNumber numberWithInt:0x00FF],                              \
                @"yuml",                                                      \
                [NSNumber numberWithInt:0x03B6],                              \
                @"zeta",                                                      \
                [NSNumber numberWithInt:0x200D],                              \
                @"zwj",                                                       \
                [NSNumber numberWithInt:0x200C],                              \
                @"zwnj",                                                      \
                nil]

#define HTML5ParserAdvance \
  { currentLocation++; }
#define HTML5ParserAdvanceBy(x) \
  { currentLocation += x; }
#define HTML5ParserRetreat \
  { currentLocation--; }
#define HTML5ParserRetreatBy(x) \
  { currentLocation -= x; }

#define HTML5ParserEmitCurrentToken                                                                                  \
  {                                                                                                                  \
    FOOLog(@"emit token: %@", currentTokenInfo);                                                                     \
    if ([[currentTokenInfo objectForKey:@"-mode"] isEqualToString:@"startTag"]) {                                    \
      NSString *_tn = [currentTagName stringByTrimmingWhitespace];                                                   \
      NSDictionary *_attributes = [currentTokenInfo objectForKey:@"-attributes"];                                    \
      HTMLLikeTag *t = [HTMLLikeTag tagWithName:_tn attributes:_attributes];                                         \
      [currentDocument addObject:t];                                                                                 \
      FOOLog(@"made tag %@, name %@, attrs %@", t, _tn, _attributes);                                                \
    } else if ([[currentTokenInfo objectForKey:@"-mode"] isEqualToString:@"closeTag"]) {                             \
      NSString *_tn = currentTagName;                                                                                \
      HTMLLikeTag *t = [HTMLLikeTag closeTagWithName:_tn];                                                           \
      [currentDocument addObject:t];                                                                                 \
      FOOLog(@"made close tag %@, name %@", t, _tn);                                                                 \
    } else if ([[currentTokenInfo objectForKey:@"-mode"] isEqualToString:@"comment"]) {                              \
      ;                                                                                                              \
    } else {                                                                                                         \
      if ([currentTokenInfo objectForKey:@"-plainText"]) {                                                           \
        [currentDocument addObject:[HTMLString htmlStringWithString:[currentTokenInfo objectForKey:@"-plainText"]]]; \
        [currentTokenInfo removeObjectForKey:@"-plainText"];                                                         \
      }                                                                                                              \
    }                                                                                                                \
    [currentTokenInfo release];                                                                                      \
    currentTagName = @"";                                                                                            \
    currentToken = nil;                                                                                              \
    currentTokenInfo = [[NSDictionary dictionary] mutableCopy];                                                      \
  }

#define HTML5ParserAddAttribute                                                                            \
  {                                                                                                        \
    NSMutableDictionary *pattrs = [currentTokenInfo objectForKey:@"-attributes"];                          \
    if (!pattrs) pattrs = [[NSDictionary dictionary] mutableCopy];                                         \
    NSString *attr = @"";                                                                                  \
    NSString *attrVal = @"";                                                                               \
    if ([currentTokenInfo objectForKey:@"-currAttrValue"])                                                 \
      attrVal = [currentTokenInfo objectForKey:@"-currAttrValue"];                                         \
    if ([currentTokenInfo objectForKey:@"-currAttr"]) attr = [currentTokenInfo objectForKey:@"-currAttr"]; \
    FOOLog(@"add attribute: %@ with value %@", attr, attrVal);                                             \
    attr = [attr stringByTrimmingWhitespace];                                                              \
    attrVal = [attrVal stringByTrimmingWhitespace];                                                        \
    if ([attr isNotEqualTo:@""]) [pattrs setObject:attrVal forKey:attr];                                   \
    [currentTokenInfo removeObjectForKey:@"-currAttrValue"];                                               \
    [currentTokenInfo removeObjectForKey:@"-currAttr"];                                                    \
    [currentTokenInfo setObject:pattrs forKey:@"-attributes"];                                             \
  }

#define HTML5ParserCanScan(x, y) ([[NSScanner scannerWithString:y] scanCharactersFromSet:x intoString:nil])
/*
 - (BOOL)canScan/CharactersInSet:(NSCharacterSet *)cs inString:(NSString *)str {
   NSScanner *sc = [NSScanner scannerWithString:str];
   return [sc scanCharactersFromSet:cs intoString:nil];
 }*/

#define HTML5ParserAreWeAtEOF (([charAtPos isEqualToString:@""]) || (charAtPos == nil))
/*

 - (void)advance {
   currentLocation++;
 }

 - (void)advanceBy:(int)i {
   currentLocation+=i;
 }

 - (void)retreat {
   currentLocation--;
 }

 - (void)retreatBy:(int)i {
   currentLocation-=i;
 }

 */

BOOL canScanVariousWhitespace(NSString *str) {
  unichar x = [str characterAtIndex:0];
  return (BOOL)(x == 0x0009 || x == 0x000A || x == 0x000B || x == 0x000C || x == 0x0020);
}

@interface ParseError : NSError {
  BOOL isEasy;
}
- (void)setEasy:(BOOL)b;
- (BOOL)isEasy;
@end

@interface EasyParseError : ParseError
+ (EasyParseError *)easyParseErrorWithError:(NSError *)error;
@end

@interface HardParseError : ParseError
+ (HardParseError *)hardParseErrorWithError:(NSError *)error;
@end

@interface HTML5Document : NSObject {
  NSStringEncoding documentEncoding;
  NSData *documentData;
}
- (NSData *)documentData;
- (NSString *)documentSource;
- (NSString *)documentSourceUsingEncoding:(NSStringEncoding)enc;
@end

// crude NSLog/FOOLog find/replace to turn off.
#define FOOLog(...) \
  { ; }

// one pass in the tokenizer loop is a 'tick'.
#define MAX_AMOUNT_OF_TICKS 100000
//#define MAX_AMOUNT_OF_TICKS [tickRoof intValue]

@implementation HTML5Parser

- (void)awakeFromNib {
  //!	[tickRoof setIntValue:100000];
  //!	[tickRoofLabel setIntValue:100000];
}

/*- (IBAction)reparse:(id)sender {
  [self parse:[parseFodder string]];
}*/

- (id)init {
  if ((self == [super init])) {
    parseState = DataState;
    contentModel = PCDataContentModel;

    _synchronousResult = nil;

    return self;
  }
  return nil;
}

- (NSArray *)parseSynchronously:(NSString *)str {
  [self parse:str answerSelector:@selector(_catchSynchronousResults:) target:self];
  return _synchronousResult;
}

- (void)_catchSynchronousResults:(NSArray *)res {
  //	NSLog(@"_catchSynchronousResults");
  _synchronousResult = [res retain];
}

- (void)parse:(NSString *)string answerSelector:(SEL)selector target:(id)target {
  answerSel = selector;
  answerTar = target;
  [self parse:string];
}

- (void)parse:(NSString *)string {
  currentString = [string copy];
  currentLocation = 0;

  isAtEOF = NO;

  outputString = [@"" copy];

  currentToken = nil;
  currentTokenInfo = [[[NSDictionary dictionary] mutableCopy] retain];
  latestTag = nil;

  currentDocument = [[NSArray array] mutableCopy];
  currentTagName = @"";
  currentAttributes = [NSDictionary dictionary];

  tickCounter = 0;

  FOOLog(@"starting parsing");

  parseState = DataState;
  secondaryParseState = NoState;
  contentModel = PCDataContentModel;

  //!	[ticks setStringValue:@"Tokenizing..."];
  //!	[pi startAnimation:self];*/

  startDate = [NSDate date];

  [self consume];
}

- (NSString *)characterAtPosition {
  if ([currentString length] > currentLocation)
    return [currentString substringWithRange:NSMakeRange(currentLocation, 1)];
  else
    return nil;
}

- (NSString *)nextFewCharacters {
  unsigned int len = 30;
  if (latestTag) {
    len = [latestTag length] + 24;
  }
  if ([currentString length] < (currentLocation + len)) {
    len = [currentString length] - currentLocation;
  }
  return [currentString substringWithRange:NSMakeRange(currentLocation, len)];
}

- (NSString *)nextManyMoreCharacters {
  unsigned int len = 2048;
  if ([currentString length] < (currentLocation + len)) {
    len = [currentString length] - currentLocation;
  }
  return [currentString substringWithRange:NSMakeRange(currentLocation, len)];
}

- (void)consume {
  while (!isAtEOF) {
    charAtPos = [[self characterAtPosition] retain];
    if (charAtPos == nil) {
      isAtEOF = YES;
    }
    tickCounter++;

    FOOLog(@"TICK %i! char at pos: %i is '%@'", tickCounter, currentLocation, charAtPos);
    FOOLog(@"current pipeline token: %@", (currentToken ? currentToken : @"(none)"));

    BOOL didStart = NO;
    BOOL didEnd = NO;

    switch (parseState) {
      case DataState:
        FOOLog(@"STATE: DataState");
        if ([charAtPos isEqualToString:@"&"]) {
          if ((contentModel == RCDataContentModel) || (contentModel == PCDataContentModel)) {
            parseState = EntityDataState;
            HTML5ParserAdvance;
            break;
          } else {
            [self emitString:charAtPos];
          }
        } else if ([charAtPos isEqualToString:@"<"]) {
          if ((contentModel != PlainTextContentModel)) {
            parseState = TagOpenState;
            HTML5ParserAdvance;
            HTML5ParserEmitCurrentToken;
          } else {
            [self emitString:charAtPos];
          }
        } else if ((HTML5ParserAreWeAtEOF)) {
          isAtEOF = YES;
          break;
        } else {
          [self emitString:charAtPos];
        }
        break;
      case EntityDataState:
        FOOLog(@"STATE: EntityDataState");
        FOOLog(@"UNIMPL: Attempt to consume an entity. Emitting &, going to DataState.");
        NSString *entityDataEntity = [self consumeEntity:[self nextFewCharacters]];
        [self emitStringButDoNotAdvance:entityDataEntity];
        parseState = DataState;
        break;
      case TagOpenState:
        FOOLog(@"STATE: TagOpenState");
        if ((contentModel == RCDataContentModel) || (contentModel == CDataContentModel)) {
          if ([charAtPos isEqualToString:@"/"]) {
            HTML5ParserAdvance;
            parseState = CloseTagOpenState;
          } else {
            [self emitStringButDoNotAdvance:@"<"];
            parseState = DataState;
          }
        } else if ((contentModel == PCDataContentModel)) {
          HTML5ParserAdvance;
          if ([charAtPos isEqualToString:@"!"]) {
            parseState = MarkedSectionOpenState;
          } else if ([charAtPos isEqualToString:@"/"]) {
            parseState = CloseTagOpenState;
          } else if (HTML5ParserCanScan([NSCharacterSet uppercaseLetterCharacterSet], charAtPos)) {
            currentToken = [NSString
              stringWithFormat:@"START TAG TOKEN [initially uppercase]: name: %@", [charAtPos lowercaseString]];
            [currentTokenInfo setObject:@"startTag" forKey:@"-mode"];
            latestTag = [charAtPos lowercaseString];
            currentTagName = [charAtPos lowercaseString];
            parseState = TagNameState;
          } else if (HTML5ParserCanScan([NSCharacterSet lowercaseLetterCharacterSet], charAtPos)) {
            currentToken = [NSString stringWithFormat:@"START TAG TOKEN [initially lowercase]: name: %@", charAtPos];
            [currentTokenInfo setObject:@"startTag" forKey:@"-mode"];
            latestTag = charAtPos;
            currentTagName = charAtPos;
            parseState = TagNameState;
          } else if ([charAtPos isEqualToString:@">"]) {
            [self parseError];
            [self emitStringButDoNotAdvance:@"<>"];
            parseState = DataState;
          } else if ([charAtPos isEqualToString:@"?"]) {
            [self parseError];
            parseState = BogusCommentState;
          } else if ((HTML5ParserAreWeAtEOF)) {
            [self parseError];
            isAtEOF = YES;
            [self emitStringButDoNotAdvance:@"<"];
            break;
          } else {
            [self parseError];
            HTML5ParserRetreat;
            [self emitStringButDoNotAdvance:@"<"];
            parseState = DataState;
          }
        }
        break;

      case CloseTagOpenState:
        FOOLog(@"STATE: CloseTagOpenState");
        if ((contentModel == RCDataContentModel) || (contentModel == CDataContentModel)) {
          NSString *nextFew = [[self nextFewCharacters] lowercaseString];
          if (![nextFew hasPrefix:latestTag]) {  // XXX should check for followed by special chars
            [self parseError];
            HTML5ParserEmitCurrentToken;
            [self emitStringButDoNotAdvance:@"</"];
            parseState = DataState;
            break;
          }
        }
        if ((contentModel != PlainTextContentModel)) {
          HTML5ParserAdvance;
          if (HTML5ParserCanScan([NSCharacterSet uppercaseLetterCharacterSet], charAtPos)) {
            currentToken = [NSString
              stringWithFormat:@"CLOSE TAG TOKEN [initially uppercase]: name: %@", [charAtPos lowercaseString]];
            [currentTokenInfo setObject:@"closeTag" forKey:@"-mode"];
            currentTagName = [charAtPos lowercaseString];
            parseState = TagNameState;
          } else if (HTML5ParserCanScan([NSCharacterSet lowercaseLetterCharacterSet], charAtPos)) {
            currentToken = [NSString stringWithFormat:@"CLOSE TAG TOKEN [initially lowercase]: name: %@", charAtPos];
            [currentTokenInfo setObject:@"closeTag" forKey:@"-mode"];
            currentTagName = charAtPos;
            parseState = TagNameState;
          } else if ([charAtPos isEqualToString:@">"]) {
            [self parseError];
            parseState = DataState;
          } else if ((HTML5ParserAreWeAtEOF)) {
            [self parseError];
            isAtEOF = YES;
            HTML5ParserEmitCurrentToken;
            [self emitStringButDoNotAdvance:@"</"];
          } else {
            [self parseError];
            parseState = BogusCommentState;
          }
        }
        break;

      case TagNameState:
        FOOLog(@"STATE: TagNameState");
        HTML5ParserAdvance;
        if (canScanVariousWhitespace(charAtPos)) {
          parseState = BeforeAttributeNameState;
        } else if ([charAtPos isEqualToString:@">"]) {
          HTML5ParserEmitCurrentToken;
          parseState = DataState;
        } else if (HTML5ParserCanScan([NSCharacterSet uppercaseLetterCharacterSet], charAtPos)) {
          currentToken = [currentToken stringByAppendingFormat:@"%@", [charAtPos lowercaseString]];
          currentTagName = [currentTagName stringByAppendingString:[charAtPos lowercaseString]];
          latestTag = [latestTag stringByAppendingString:[charAtPos lowercaseString]];
        } else if ([charAtPos isEqualToString:@"<"]) {
          [self parseError];
          HTML5ParserEmitCurrentToken;
          HTML5ParserRetreat;
          parseState = DataState;
        } else if ([charAtPos isEqualToString:@"/"]) {
          [self parseError];
          parseState = BeforeAttributeNameState;
        } else if ((HTML5ParserAreWeAtEOF)) {
          [self parseError];
          isAtEOF = YES;
          HTML5ParserEmitCurrentToken;
        } else {
          currentToken = [currentToken stringByAppendingFormat:@"%@", charAtPos];
          latestTag = [latestTag stringByAppendingString:charAtPos];
          currentTagName = [currentTagName stringByAppendingString:charAtPos];
        }
        break;

      case BeforeAttributeNameState:
        FOOLog(@"STATE: BeforeAttributeNameState");
        HTML5ParserAdvance;
        didStart = NO;
        NSString *fc;
        if (canScanVariousWhitespace(charAtPos)) {
          parseState = BeforeAttributeNameState;  // noop
        } else if ([charAtPos isEqualToString:@">"]) {
          HTML5ParserEmitCurrentToken;
          parseState = DataState;
        } else if (HTML5ParserCanScan([NSCharacterSet uppercaseLetterCharacterSet], charAtPos)) {
          currentToken = [currentToken stringByAppendingFormat:@" attr[uc]:%@", [charAtPos lowercaseString]];
          didStart = YES;
          fc = [charAtPos lowercaseString];
          parseState = AttributeNameState;
        } else if ([charAtPos isEqualToString:@"/"]) {
          [self parseError];
          parseState = BeforeAttributeNameState;  // noop
        } else if ([charAtPos isEqualToString:@"<"]) {
          [self parseError];
          HTML5ParserEmitCurrentToken;
          HTML5ParserRetreat;
          parseState = DataState;
        } else if ((HTML5ParserAreWeAtEOF)) {
          [self parseError];
          isAtEOF = YES;
          HTML5ParserEmitCurrentToken;
        } else {
          currentToken = [currentToken stringByAppendingFormat:@" attr[lc]:%@", charAtPos];
          didStart = YES;
          fc = charAtPos;
          parseState = AttributeNameState;
        }

        if (didStart) {
          [currentTokenInfo setObject:fc forKey:@"-currAttr"];
          didStart = NO;
        }

        break;

      case AttributeNameState:
        FOOLog(@"STATE: AttributeNameState");
        HTML5ParserAdvance;
        didEnd = NO;
        NSString *currAttr =
          ([currentTokenInfo objectForKey:@"-currAttr"] ? [currentTokenInfo objectForKey:@"-currAttr"] : @"");
        if (canScanVariousWhitespace(charAtPos)) {
          parseState = AfterAttributeNameState;
          didEnd = YES;
        } else if ([charAtPos isEqualToString:@"\""]) {  // Bullshit, made up rule
          parseState = AttributeValueDQState;
          currentToken = [currentToken stringByAppendingFormat:@"=value:", charAtPos];
          didEnd = YES;
        } else if ([charAtPos isEqualToString:@"\'"]) {  // Bullshit, made up rule
          parseState = AttributeValueSQState;
          currentToken = [currentToken stringByAppendingFormat:@"=value:", charAtPos];
          didEnd = YES;
        } else if ([charAtPos isEqualToString:@"="]) {
          parseState = BeforeAttributeValueState;
          didEnd = YES;
        } else if ([charAtPos isEqualToString:@">"]) {
          didEnd = YES;
          [currentTokenInfo
            setObject:([currentTokenInfo objectForKey:@"-currAttr"] ? [currentTokenInfo objectForKey:@"-currAttr"]
                                                                    : @"")
               forKey:@"-currAttrValue"];
          HTML5ParserAddAttribute;
          HTML5ParserEmitCurrentToken;
          parseState = DataState;
        } else if (HTML5ParserCanScan([NSCharacterSet uppercaseLetterCharacterSet], charAtPos)) {
          currentToken = [currentToken stringByAppendingFormat:@"%@", [charAtPos lowercaseString]];
          [currentTokenInfo setObject:[currAttr stringByAppendingFormat:@"%@", [charAtPos lowercaseString]]
                               forKey:@"-currAttr"];
        } else if ([charAtPos isEqualToString:@"/"]) {
          [self parseError];
          parseState = BeforeAttributeNameState;
        } else if ([charAtPos isEqualToString:@"<"]) {
          [self parseError];
          HTML5ParserEmitCurrentToken;
          HTML5ParserRetreat;
          parseState = DataState;
        } else if ((HTML5ParserAreWeAtEOF)) {
          [self parseError];
          isAtEOF = YES;
          HTML5ParserEmitCurrentToken;
        } else {
          currentToken = [currentToken stringByAppendingFormat:@"%@", charAtPos];
          [currentTokenInfo setObject:[currAttr stringByAppendingFormat:@"%@", charAtPos] forKey:@"-currAttr"];
        }

        if (didEnd) {
          //					[currentTokenInfo setObject:fc forKey:@"-currAttr"];
          didEnd = NO;
        }

        break;

      case AfterAttributeNameState:
        FOOLog(@"STATE: AfterAttributeNameState");
        HTML5ParserAdvance;
        didEnd = NO;
        didStart = NO;
        NSString *aafc;
        if (canScanVariousWhitespace(charAtPos)) {
          parseState = AfterAttributeNameState;  // noop
        } else if ([charAtPos isEqualToString:@"="]) {
          parseState = BeforeAttributeValueState;
          didEnd = YES;
        } else if ([charAtPos isEqualToString:@">"]) {
          HTML5ParserEmitCurrentToken;
          parseState = DataState;
        } else if (HTML5ParserCanScan([NSCharacterSet uppercaseLetterCharacterSet], charAtPos)) {
          currentToken = [currentToken stringByAppendingFormat:@" attr[uc]:%@", [charAtPos lowercaseString]];
          didStart = YES;
          aafc = [charAtPos lowercaseString];
          parseState = AttributeNameState;
        } else if ([charAtPos isEqualToString:@"/"]) {
          [self parseError];
          parseState = BeforeAttributeNameState;
        } else if ([charAtPos isEqualToString:@"<"]) {
          [self parseError];
          HTML5ParserEmitCurrentToken;
          HTML5ParserRetreat;
          parseState = DataState;
        } else if ((HTML5ParserAreWeAtEOF)) {
          [self parseError];
          isAtEOF = YES;
          HTML5ParserEmitCurrentToken;
        } else {
          currentToken = [currentToken stringByAppendingFormat:@" attr[lc]:%@", charAtPos];
          didStart = YES;
          aafc = charAtPos;
          parseState = AttributeNameState;
        }

        if (didStart) {
          [currentTokenInfo setObject:aafc forKey:@"-currAttr"];
          didStart = NO;
        }
        break;

      case BeforeAttributeValueState:
        FOOLog(@"STATE: BeforeAttributeValueState");
        HTML5ParserAdvance;
        didStart = NO;
        didEnd = NO;
        if (canScanVariousWhitespace(charAtPos)) {
          parseState = BeforeAttributeValueState;  // noop
        } else if ([charAtPos isEqualToString:@"\""]) {
          parseState = AttributeValueDQState;
          currentToken = [currentToken stringByAppendingFormat:@"=value:", charAtPos];
        } else if ([charAtPos isEqualToString:@"&"]) {
          HTML5ParserRetreat;
          parseState = AttributeValueUQState;
          currentToken = [currentToken stringByAppendingFormat:@"=value:", charAtPos];
        } else if ([charAtPos isEqualToString:@"'"]) {
          parseState = AttributeValueSQState;
          currentToken = [currentToken stringByAppendingFormat:@"=value:", charAtPos];
        } else if ([charAtPos isEqualToString:@">"]) {
          didEnd = YES;
          [currentTokenInfo
            setObject:([currentTokenInfo objectForKey:@"-currAttr"] ? [currentTokenInfo objectForKey:@"-currAttr"]
                                                                    : @"")
               forKey:@"-currAttrValue"];

          HTML5ParserAddAttribute;

          HTML5ParserEmitCurrentToken;
          didEnd = NO;
          parseState = DataState;
        } else if ([charAtPos isEqualToString:@"<"]) {
          [self parseError];
          HTML5ParserEmitCurrentToken;
          HTML5ParserRetreat;
          parseState = DataState;
        } else if ((HTML5ParserAreWeAtEOF)) {
          [self parseError];
          isAtEOF = YES;
          HTML5ParserEmitCurrentToken;
        } else {
          didStart = YES;
          currentToken = [currentToken stringByAppendingFormat:@"=value:%@", charAtPos];
          parseState = AttributeValueUQState;
        }

        if (didStart) {
          [currentTokenInfo setObject:charAtPos forKey:@"-currAttrValue"];
          didStart = NO;
        }

        break;

      case AttributeValueDQState:
        FOOLog(@"STATE: AttributeValueDQState");
        HTML5ParserAdvance;
        didEnd = NO;
        NSString *currAttrDQValue =
          ([currentTokenInfo objectForKey:@"-currAttrValue"] ? [currentTokenInfo objectForKey:@"-currAttrValue"] : @"");
        if ([charAtPos isEqualToString:@"\""]) {
          parseState = BeforeAttributeNameState;
          didEnd = YES;
          HTML5ParserAddAttribute;
          didEnd = NO;
        } else if ([charAtPos isEqualToString:@"&"]) {
          secondaryParseState = parseState;
          parseState = EntityInAttributeValueState;
        } else if ((HTML5ParserAreWeAtEOF)) {
          [self parseError];
          isAtEOF = YES;
          HTML5ParserEmitCurrentToken;
        } else {
          currentToken = [currentToken stringByAppendingFormat:@"%@", charAtPos];
          [currentTokenInfo setObject:[currAttrDQValue stringByAppendingFormat:@"%@", charAtPos]
                               forKey:@"-currAttrValue"];
        }
        break;

      case AttributeValueSQState:
        FOOLog(@"STATE: AttributeValueSQState");
        HTML5ParserAdvance;
        NSString *currAttrSQValue =
          ([currentTokenInfo objectForKey:@"-currAttrValue"] ? [currentTokenInfo objectForKey:@"-currAttrValue"] : @"");
        if ([charAtPos isEqualToString:@"'"]) {
          parseState = BeforeAttributeNameState;
          didEnd = YES;
          HTML5ParserAddAttribute;
          didEnd = NO;
        } else if ([charAtPos isEqualToString:@"&"]) {
          secondaryParseState = parseState;
          parseState = EntityInAttributeValueState;
        } else if ((HTML5ParserAreWeAtEOF)) {
          [self parseError];
          isAtEOF = YES;
          didEnd = YES;
          HTML5ParserAddAttribute;
          didEnd = NO;
          HTML5ParserEmitCurrentToken;
        } else {
          currentToken = [currentToken stringByAppendingFormat:@"%@", charAtPos];
          [currentTokenInfo setObject:[currAttrSQValue stringByAppendingFormat:@"%@", charAtPos]
                               forKey:@"-currAttrValue"];
        }
        break;

      case AttributeValueUQState:
        FOOLog(@"STATE: AttributeValueUQState");
        HTML5ParserAdvance;
        NSString *currAttrUQValue =
          ([currentTokenInfo objectForKey:@"-currAttrValue"] ? [currentTokenInfo objectForKey:@"-currAttrValue"] : @"");
        if (canScanVariousWhitespace(charAtPos)) {
          parseState = BeforeAttributeNameState;
          didEnd = YES;
          HTML5ParserAddAttribute;
          didEnd = NO;
        } else if ([charAtPos isEqualToString:@"&"]) {
          secondaryParseState = parseState;
          parseState = EntityInAttributeValueState;
        } else if ([charAtPos isEqualToString:@">"]) {
          didEnd = YES;
          HTML5ParserAddAttribute;
          didEnd = NO;
          HTML5ParserEmitCurrentToken;
          parseState = DataState;
        } else if ([charAtPos isEqualToString:@"<"]) {
          [self parseError];
          didEnd = YES;
          HTML5ParserAddAttribute;
          didEnd = NO;
          HTML5ParserEmitCurrentToken;
          HTML5ParserRetreat;
          parseState = DataState;
        } else if ((HTML5ParserAreWeAtEOF)) {
          [self parseError];
          isAtEOF = YES;
          didEnd = YES;
          HTML5ParserAddAttribute;
          didEnd = NO;
          HTML5ParserEmitCurrentToken;
        } else {
          currentToken = [currentToken stringByAppendingFormat:@"%@", charAtPos];
          [currentTokenInfo setObject:[currAttrUQValue stringByAppendingFormat:@"%@", charAtPos]
                               forKey:@"-currAttrValue"];
        }
        break;

      case EntityInAttributeValueState:
        FOOLog(@"STATE: EntityInAttributeValueState");
        FOOLog(
          @"UNIMPL: Attempt to consume an entity inside an attribute. Emitting &, going back to correct attribute state.");
        NSString *entityInAttributeValueEntity = [self consumeEntity:[self nextFewCharacters]];
        currentToken = [currentToken stringByAppendingFormat:@"%@", entityInAttributeValueEntity];
        NSString *eiavCurrAttrVal =
          ([currentTokenInfo objectForKey:@"-currAttrValue"] ? [currentTokenInfo objectForKey:@"-currAttrValue"] : @"");
        [currentTokenInfo setObject:[eiavCurrAttrVal stringByAppendingFormat:@"%@", entityInAttributeValueEntity]
                             forKey:@"-currAttrValue"];
        parseState = secondaryParseState;
        secondaryParseState = NoState;
        break;

      case BogusCommentState:
        FOOLog(@"STATE: BogusCommentState");
        NSString *bogusC =
          (NSString *)[[[self nextManyMoreCharacters] componentsSeparatedByString:@">"] objectAtIndex:0];
        HTML5ParserAdvanceBy([bogusC length] + 1);
        currentToken = [NSString stringWithFormat:@"BOGUS COMMENT: %@", bogusC];
        [currentTokenInfo setObject:@"comment" forKey:@"-mode"];
        parseState = DataState;
        if ((HTML5ParserAreWeAtEOF)) {
          isAtEOF = YES;
        }
        HTML5ParserEmitCurrentToken;
        break;

      case MarkedSectionOpenState:
        FOOLog(@"STATE: MarkedSectionOpenState");
        if ([[self nextFewCharacters] hasPrefix:@"--"]) {
          HTML5ParserAdvanceBy(2);
          currentToken = @"COMMENT: ";
          [currentTokenInfo setObject:@"comment" forKey:@"-mode"];
          parseState = CommentState;
        } else if ([[[[self nextFewCharacters] substringToIndex:8] uppercaseString] hasPrefix:@"DOCTYPE"]) {
          parseState = DOCTYPEState;
        } else {
          [self parseError];
          parseState = BogusCommentState;
        }
        break;

      case CommentState:
        FOOLog(@"STATE: CommentState");
        HTML5ParserAdvance;
        if ([charAtPos isEqualToString:@"-"]) {
          parseState = CommentDashState;
        } else if ((HTML5ParserAreWeAtEOF)) {
          [self parseError];
          isAtEOF = YES;
          HTML5ParserEmitCurrentToken;
        } else {
          currentToken = [currentToken stringByAppendingString:charAtPos];
        }
        break;

      case CommentDashState:
        FOOLog(@"STATE: CommentDashState");
        HTML5ParserAdvance;
        if ([charAtPos isEqualToString:@"-"]) {
          parseState = CommentEndState;
        } else if ((HTML5ParserAreWeAtEOF)) {
          [self parseError];
          isAtEOF = YES;
          HTML5ParserEmitCurrentToken;
        } else {
          currentToken = [currentToken stringByAppendingFormat:@"-%@", charAtPos];
          parseState = CommentState;
        }
        break;

      case CommentEndState:
        FOOLog(@"STATE: CommentEndState");
        HTML5ParserAdvance;
        if ([charAtPos isEqualToString:@"-"]) {
          [self parseError];
          currentToken = [currentToken stringByAppendingString:@"-"];
        } else if ([charAtPos isEqualToString:@">"]) {
          HTML5ParserEmitCurrentToken;
          parseState = DataState;
        } else if ((HTML5ParserAreWeAtEOF)) {
          [self parseError];
          isAtEOF = YES;
          HTML5ParserEmitCurrentToken;
        } else {
          currentToken = [currentToken stringByAppendingFormat:@"--%@", charAtPos];
          parseState = CommentState;
        }
        break;

      case DOCTYPEState:
        FOOLog(@"STATE: DOCTYPEState");
        HTML5ParserAdvance;
        if (canScanVariousWhitespace(charAtPos)) {
          parseState = BeforeDOCTYPENameState;
        } else {
          [self parseError];
          HTML5ParserRetreat;
          parseState = BeforeDOCTYPENameState;
        }
        break;

      case BeforeDOCTYPENameState:
        FOOLog(@"STATE: BeforeDOCTYPENameState");
        HTML5ParserAdvance;
        if (canScanVariousWhitespace(charAtPos)) {
          parseState = BeforeDOCTYPENameState;  // noop
        } else if (HTML5ParserCanScan([NSCharacterSet lowercaseLetterCharacterSet], charAtPos)) {
          currentToken =
            [NSString stringWithFormat:@"DOCTYPE TOKEN [initially lowercase] %@", [charAtPos uppercaseString]];
          [currentTokenInfo setObject:@"comment" forKey:@"-mode"];
          parseState = DOCTYPENameState;
        } else if ([charAtPos isEqualToString:@">"]) {
          [self parseError];
          currentToken = @"DOCTYPE TOKEN [errorneous] [empty]";
          [currentTokenInfo setObject:@"comment" forKey:@"-mode"];
          HTML5ParserEmitCurrentToken;
          parseState = DataState;
        } else if ((HTML5ParserAreWeAtEOF)) {
          [self parseError];
          isAtEOF = YES;
          currentToken = @"DOCTYPE TOKEN [errorneous] [empty]";
          [currentTokenInfo setObject:@"comment" forKey:@"-mode"];
          HTML5ParserEmitCurrentToken;
        } else {
          currentToken = [NSString stringWithFormat:@"DOCTYPE TOKEN %@", charAtPos];
          [currentTokenInfo setObject:@"comment" forKey:@"-mode"];
          parseState = DOCTYPENameState;
        }
        break;

      case DOCTYPENameState:
        FOOLog(@"STATE: DOCTYPENameState");
        HTML5ParserAdvance;
        if (canScanVariousWhitespace(charAtPos)) {
          parseState = AfterDOCTYPENameState;
        } else if ([charAtPos isEqualToString:@">"]) {
          HTML5ParserEmitCurrentToken;
          parseState = DataState;
        } else if (HTML5ParserCanScan([NSCharacterSet lowercaseLetterCharacterSet], charAtPos)) {
          currentToken = [currentToken stringByAppendingFormat:@"%@", [charAtPos uppercaseString]];
        } else if ((HTML5ParserAreWeAtEOF)) {
          [self parseError];
          isAtEOF = YES;
          HTML5ParserEmitCurrentToken;
        } else {
          currentToken = [currentToken stringByAppendingString:charAtPos];
        }
        break;

      case AfterDOCTYPENameState:
        FOOLog(@"STATE: AfterDOCTYPENameState");
        HTML5ParserAdvance;
        if (canScanVariousWhitespace(charAtPos)) {
          parseState = AfterDOCTYPENameState;
        } else if ([charAtPos isEqualToString:@">"]) {
          HTML5ParserEmitCurrentToken;
          parseState = DataState;
        } else if ((HTML5ParserAreWeAtEOF)) {
          [self parseError];
          isAtEOF = YES;
          HTML5ParserEmitCurrentToken;
        } else {
          [self parseError];
          parseState = BogusDOCTYPEState;
        }
        break;

      case BogusDOCTYPEState:
        FOOLog(@"STATE: BogusDOCTYPEState");
        HTML5ParserAdvance;
        if ([charAtPos isEqualToString:@">"]) {
          HTML5ParserEmitCurrentToken;
          parseState = DataState;
        } else if ((HTML5ParserAreWeAtEOF)) {
          [self parseError];
          isAtEOF = YES;
          HTML5ParserEmitCurrentToken;
        } else {
          parseState = BogusDOCTYPEState;
        }
        break;
    }

    if (tickCounter > MAX_AMOUNT_OF_TICKS) {
      [self doEOFCleanup];
      FOOLog(@"We're now at %i, stopping this madness...", MAX_AMOUNT_OF_TICKS);
      //!		[ticks setStringValue:[NSString stringWithFormat:@"Tokenized; exhausted after %i ticks.", tickCounter]];
      return;
    }

    [charAtPos release];
  }
  FOOLog(@"We're at EOF, stopping this madness...");
  [self doEOFCleanup];
}

- (void)parseError {
  FOOLog(@"PARSE ERROR!!!!!!!!!1");
}

- (void)doEOFCleanup {
  endDate = [NSDate date];
  //	NSTimeInterval ti = [endDate timeIntervalSinceDate:startDate];
  //!	[ticks setStringValue:[NSString stringWithFormat:@"Tokenized; done after %i ticks, %f s.", tickCounter, ti]];
  //!	[pi stopAnimation:self];

  NSEnumerator *tokenEnumerator = [currentDocument objectEnumerator];
  id token;
  NSMutableString *reconst = [[@"" mutableCopy] autorelease];
  while (token = [tokenEnumerator nextObject]) {
    if ([token isKindOfClass:[HTMLString class]]) {  // plain text
      [reconst appendString:[token stringValue]];
    } else if ([token isKindOfClass:[HTMLLikeTag class]]) {
      HTMLLikeTag *lt = (HTMLLikeTag *)token;
      if ([lt isCloseTag]) {
        [reconst appendFormat:@"</%@>", [lt name]];
      } else {
        [reconst appendFormat:@"<%@", [lt name]];
        NSDictionary *attrs = [lt attributes];
        if (attrs && ([attrs count] > 0)) {
          NSEnumerator *attrEnumerator = [attrs keyEnumerator];
          NSString *attr;
          while (attr = [attrEnumerator nextObject]) {
            NSString *attrval = [attrs objectForKey:attr];
            if (!attrval) attrval = @"";
            if ([attrval isNotEqualTo:@""]) {
              attrval = [[attrval componentsSeparatedByString:@"&"] componentsJoinedByString:@"&amp;"];
              attrval = [[attrval componentsSeparatedByString:@"\""] componentsJoinedByString:@"&quot;"];
            }
            /*if ([attrval isNotEqualTo:@""]) {
              attrval = (NSString *)CFXMLCreateStringByEscapingEntities(kCFAllocatorNull,(CFStringRef)attrval,NULL);
            }*/
            [reconst appendFormat:@" %@=\"%@\"", attr, attrval];
          }
        }
        [reconst appendString:@">"];
      }
    } else {
      FOOLog(@"unknown token class: %@", [token className]);
    }
  }

  if (answerTar) {
    [answerTar performSelector:answerSel withObject:[NSArray arrayWithObjects:currentDocument, reconst, nil]];
    answerTar = nil;
    answerSel = NULL;
  }

  //	FOOLog(@"all tokens: %@", currentDocument);
  //	FOOLog(@"reconstructed document: %@", reconst);
  //!	[emitted setString:reconst];
}

/*
- (void)emitCurrentToken {
//	if (currentTokenInfo != nil) {
//	[self emitStringButDoNotAdvance:[NSString stringWithFormat:@"<<TOKEN: %@ :TOKEN>>\n", currentToken]];

  FOOLog(@"emitting token of type %@", [currentTokenInfo objectForKey:@"-mode"]);
  if ([[currentTokenInfo objectForKey:@"-mode"] isEqualToString:@"startTag"]) {
    NSString *_tn = currentTagName;
    NSDictionary *_attributes = [currentTokenInfo objectForKey:@"-attributes"];

    HTMLLikeTag *t = [HTMLLikeTag tagWithName:_tn attributes:_attributes];

    [currentDocument addObject:t];
    FOOLog(@"made tag %@, name %@, attrs %@", t, _tn, _attributes);
  } else if ([[currentTokenInfo objectForKey:@"-mode"] isEqualToString:@"closeTag"]) {
    NSString *_tn = currentTagName;

    HTMLLikeTag *t = [HTMLLikeTag closeTagWithName:_tn];

    [currentDocument addObject:t];
    FOOLog(@"made close tag %@, name %@", t, _tn);
  } else if ([[currentTokenInfo objectForKey:@"-mode"] isEqualToString:@"comment"]) {
    ; // noop
  } else {
    if ([currentTokenInfo objectForKey:@"-plainText"]) {
      [currentDocument addObject:[HTMLString htmlStringWithString:[currentTokenInfo objectForKey:@"-plainText"]]];
      [currentTokenInfo removeObjectForKey:@"-plainText"];
    }
  }
//	}

  currentTagName = @"";

  currentToken = nil;
  currentTokenInfo = [[[NSDictionary dictionary] mutableCopy] retain];
}*/

- (void)emitString:(NSString *)str {
  [self emitStringButDoNotAdvance:str];
  currentLocation += [str length];
}

- (void)emitStringButDoNotAdvance:(NSString *)str {
  NSString *pt = [currentTokenInfo objectForKey:@"-plainText"];
  if (!pt) {
    [currentTokenInfo setObject:@"" forKey:@"-plainText"];
    pt = @"";
  }
  pt = [pt stringByAppendingString:str];
  [currentTokenInfo setObject:pt forKey:@"-plainText"];

  //	FOOLog(@"\nEMIT: %@\n", str);
}

- (void)advance {
  currentLocation++;
}

- (void)advanceBy:(int)i {
  currentLocation += i;
}

- (void)retreat {
  currentLocation--;
}

- (void)retreatBy:(int)i {
  currentLocation -= i;
}

- (NSString *)consumeEntity:(NSString *)str {
  NSScanner *sc = [NSScanner scannerWithString:str];
  FOOLog(@"consume entity: %@", str);
  NSString *returnString = @"&";
  unsigned int number;
  BOOL hasNumber = NO;
  if ([sc scanString:@"#" intoString:nil]) {
    // Numbers!

    if ([sc scanCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"xX"] intoString:NULL]) {
      // Hexadecimal numbers!
      [sc scanHexInt:&number];
    } else {
      int intnumber;
      // Decimal numbers!
      [sc scanInt:&intnumber];
      number = (unsigned int)intnumber;
    }
    hasNumber = YES;
    FOOLog(@"we scanned an int: %i", number);
  } else {
    NSDictionary *ent = HTMLEntitiesToNumbers;
    NSString *charCode;
    [sc scanUpToCharactersFromSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet] intoString:&charCode];
    FOOLog(@"we scanned a substring: %@ of length: %i", charCode, [charCode length]);
    unsigned int length = [charCode length];
    int i;
    FOOLog(@"since it's a substring, loop %i times", length);
    for (i = length; i > 0; i--) {
      FOOLog(@"loop. length: %i", i);
      NSNumber *num = [ent objectForKey:[charCode substringToIndex:i]];
      if (!num) {
        FOOLog(@"entity %@ not found", [charCode substringToIndex:i]);
        continue;
      }
      number = [num unsignedIntValue];
      FOOLog(@"entity %@ found; number: %i", [charCode substringToIndex:i], number);
      hasNumber = YES;
      break;
    }
  }
  BOOL scannedSemi;
  //	int giveortake = -1;
  if (hasNumber) {
    if (![sc scanString:@";" intoString:nil]) {
      scannedSemi = NO;
      //			giveortake = 0;
    } else {
      scannedSemi = YES;
      //			giveortake = 1;
    }
    FOOLog(@"scanned semicolon? %@", (scannedSemi ? @"YES" : @"NO"));
    returnString = [NSString stringWithFormat:@"%C", number];
  }

  HTML5ParserAdvanceBy([sc scanLocation]);        //+giveortake];
  FOOLog(@"advancing by %i", [sc scanLocation]);  //+giveortake);
  FOOLog(@"returning %@", returnString);
  return returnString;
}

/*
- (BOOL)canScanTabLFVertabFFSpaceInString:(NSString *)str {
  unichar x = [str characterAtIndex:0];
  FOOLog(@"can scan various white space in '%@'?", str);
  if (x == 0x0009 || x == 0x000A || x == 0x000B || x == 0x000C || x == 0x0020) {
    FOOLog(@"yep");
    return YES;
  }
  return NO;
  FOOLog(@"can scan various white space in '%@'? %@)", [NSCharacterSet characterSetWithCharactersInString:[NSString
stringWithFormat:@"%C%C%C%C%C", 0x0009, 0x000A, 0x000B, 0x000C, 0x0020]], str, ([self
canScanCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:[NSString stringWithFormat:@"%C%C%C%C%C",
0x0009, 0x000A, 0x000B, 0x000C, 0x0020]] inString:str] ? @"YES" : @"NO")); return [self
canScanCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:[NSString stringWithFormat:@"%C%C%C%C%C",
0x0009, 0x000A, 0x000B, 0x000C, 0x0020]] inString:str];
}*/

@end

@implementation NSArray (HTML5Additions)

- (NSArray *)itemsStartingAt:(id)firstObject {
  if (![self containsObject:firstObject]) return nil;
  unsigned myi = [self indexOfObject:firstObject];
  return [self objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(myi, [self count] - (myi))]];
}

- (NSArray *)itemsBetween:(id)firstObject and:(id)secondObject {
  if (![self containsObject:firstObject]) return nil;
  if (![self containsObject:secondObject]) return nil;
  if (firstObject == secondObject) return [NSArray arrayWithObject:firstObject];

  NSIndexSet *is = [NSIndexSet indexSet];
  unsigned foi = [self indexOfObject:firstObject];
  unsigned soi = [self indexOfObject:secondObject];
  if (foi > soi) {
    is = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(soi + 1, ((foi - soi) - 1))];
  } else {
    is = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(foi + 1, ((soi - foi) - 1))];
  }

  return [self objectsAtIndexes:is];
}

- (HTMLLikeTag *)closingTagFor:(HTMLLikeTag *)openingTag {
  NSString *tagName = [openingTag name];
  int myTagsOpened = 1;

  Class likeTag = [HTMLLikeTag class];

  /*	NSArray *sItems = [self itemsStartingAt:openingTag];*/
  NSEnumerator *tagEnumerator = [self objectEnumerator];
  id tag;
  BOOL lookForCloseTag = NO;
  while (tag = [tagEnumerator nextObject]) {
    if (lookForCloseTag) {
      if (![tag isKindOfClass:likeTag]) continue;
      HTMLLikeTag *lt = (HTMLLikeTag *)tag;
      //		FOOLog(@"tag: %@ (my tags opened: %i)", lt, myTagsOpened);
      if ([[lt name] isEqualToString:tagName]) {
        if ([lt isCloseTag]) {
          myTagsOpened--;
          //				FOOLog(@"my tags opened changed (-) %i", myTagsOpened);
          if (myTagsOpened < 1) {
            FOOLog(@"found close tag: %@", lt);
            return lt;
          }
        } else {
          myTagsOpened++;
          //				FOOLog(@"my tags opened changed (+) %i", myTagsOpened);
        }
      }
    }
    if ([tag isEqualTo:openingTag]) lookForCloseTag = YES;
  }
  return nil;
}

- (NSArray *)kidItemsOf:(HTMLLikeTag *)openingTag {
  FOOLog(@"all items: %@", self);

  HTMLLikeTag *endTag = [self closingTagFor:openingTag];
  if (!endTag) return nil;

  FOOLog(@"has kid items (has opening and end tag)");

  NSArray *kids = [self itemsBetween:openingTag and:endTag];
  FOOLog(@"has %i kid items", [kids count]);

  return kids;
}

//- (HTMLLikeTag *)openingTagFor:(HTMLLikeTag *)closingTag;

@end

@implementation NSString (HTML5Additions)
- (NSString *)stringByTrimmingWhitespace {
  return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}
@end

@implementation HTMLString (Private)
- (void)_setPrimitiveString:(NSString *)str {
  if (_string == str) return;
  [_string release];
  _string = str;
  [_string retain];
}

- (void)dealloc {
  [_string release];
  [super dealloc];
}
@end

@implementation HTMLString : NSObject
+ (id)htmlStringWithString:(NSString *)str {
  HTMLString *st = [[self alloc] init];
  if (!st) return nil;
  [st _setPrimitiveString:str];
  return [st autorelease];
}

- (NSString *)stringValue {
  return _string;
}

- (NSString *)description {
  return [self stringValue];  //[[self stringValue] stringByAppendingFormat:@" <%@>", [super description]];
}

@end