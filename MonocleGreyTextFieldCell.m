#import "MonocleGreyTextFieldCell.h"

@implementation MonocleGreyTextFieldCell
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {

	NSColor *drawColor = ([self isHighlighted] ? [[NSColor alternateSelectedControlTextColor] colorWithAlphaComponent:0.8f] : [NSColor controlShadowColor]);
	[self setTextColor:drawColor];
	
	[super drawWithFrame:cellFrame inView:controlView];
	
	[self setTextColor:[NSColor textColor]];
	
}
/*
- (NSText *)setUpFieldEditorAttributes:(NSText *)textObj {
	
	[textObj setTextColor:[NSColor textColor]];
	return textObj;
}*/
@end
