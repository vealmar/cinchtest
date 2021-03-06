//
//  IBCoreTextLabel.m
//  iBoostCatalog
//
//  Created by John Blanco on 9/3/10.
//  Copyright 2010 Effective UI. All rights reserved.
//

#import "IBCoreTextLabel.h"
#import <CoreText/CoreText.h>
#import "Macros.h"

@interface IBCoreTextLabel (PRIVATE)

- (NSString *)catalogTagsInText;
- (NSMutableAttributedString *)createAttributesStringFromCatalog:(NSString *)str;
- (NSMutableAttributedString *)createMutableAttributedStringFromText;

@end

@implementation IBCoreTextLabel

@synthesize text;
@synthesize textColor;

- (id)initWithFrame:(CGRect)frame {
	if ((self = [super initWithFrame:frame])) {
		_boldRanges = [[NSMutableArray alloc] init];
		_italicRanges = [[NSMutableArray alloc] init];
		_fontRanges = [[NSMutableArray alloc] init];
		
		self.textColor = [UIColor blackColor];
	}
	
	return self;
}


- (void)drawRect:(CGRect)rect {
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	
	// bounds
	UIBezierPath *textPath = [UIBezierPath bezierPathWithRect:self.bounds];
	
	// clear
	[textColor setStroke];
	[[UIColor whiteColor] setFill];
	CGContextFillRect(ctx, self.bounds);	

	if (_attrStr) {
		// create the frame
		CTFramesetterRef frameSetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)_attrStr);
		CTFrameRef frame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, 0), textPath.CGPath, NULL);
		
		CFRelease(frameSetter);
		
		if (frame) {
			// flip text rightways up
			CGContextTranslateCTM(ctx, 0, textPath.bounds.origin.y);
			CGContextScaleCTM(ctx, 1, -1);
			CGContextTranslateCTM(ctx, 0, -(textPath.bounds.origin.y + textPath.bounds.size.height));
			
			CTFrameDraw(frame, ctx);
			CFRelease(frame);
		}
	}
}

- (void)setTextColor:(UIColor *)value {
	_textColor = value;

	if (_text) {
		NSMutableAttributedString *attrStr = [self createMutableAttributedStringFromText];
        SAFE_RELEASE(_attrStr);
		_attrStr = attrStr;
	}
	
	[self setNeedsDisplay];
}

- (void)setText:(NSString *)value {
	_text = value;

	[_boldRanges removeAllObjects];
	[_italicRanges removeAllObjects];
	[_fontRanges removeAllObjects];
	
	if (_text) {
		NSMutableAttributedString *attrStr = [self createMutableAttributedStringFromText];
        SAFE_RELEASE(_attrStr);
		_attrStr = attrStr;
	}
	
	[self setNeedsDisplay];
}

- (NSMutableAttributedString *)createMutableAttributedStringFromText {
	NSString *str = [self catalogTagsInText];
	return [self createAttributesStringFromCatalog:str];
}

- (NSString *)catalogTagsInText {
	NSScanner *scanner = [NSScanner scannerWithString:_text];
	[scanner setCharactersToBeSkipped:nil];
	NSMutableString *scannedStr = [NSMutableString string];		
	NSString *scanStr = nil;
	NSInteger scanIndex = -1;
	NSInteger medicalLoss = 0;
	
	while ([scanner scanUpToString:@"<" intoString:&scanStr]) {
		scanIndex = [scanner scanLocation];
		[scannedStr appendString:scanStr];
		
		if ([scanner scanString:@"<b>" intoString:nil]) {
			// bold
			[scanner scanUpToString:@"</b>" intoString:&scanStr];
			[scannedStr appendString:scanStr];
			[_boldRanges addObject:[NSValue valueWithRange:NSMakeRange(scanIndex - medicalLoss, scanStr.length)]];

			[scanner scanString:@"</b>" intoString:nil];
			medicalLoss += 7;
		} else if ([scanner scanString:@"<i>" intoString:nil]) {
			// italic
			[scanner scanUpToString:@"</i>" intoString:&scanStr];
			[scannedStr appendString:scanStr];
			[_italicRanges addObject:[NSValue valueWithRange:NSMakeRange(scanIndex - medicalLoss, scanStr.length)]];

			[scanner scanString:@"</i>" intoString:nil];
			medicalLoss += 7;
		} else if ([scanner scanString:@"<font " intoString:nil]) {
			[scanner scanUpToString:@">" intoString:&scanStr];
			NSString *fontName = [scanStr copy];
			[scanner scanString:@">" intoString:nil];
			
			// font
			[scanner scanUpToString:@"</font>" intoString:&scanStr];
			[scannedStr appendString:scanStr];
			[_fontRanges addObject:[NSValue valueWithRange:NSMakeRange(scanIndex - medicalLoss, scanStr.length)]];
			[_fontRanges addObject:fontName];
			
			[scanner scanString:@"</font>" intoString:nil];
			medicalLoss += 14 + fontName.length;
		}
	}
	
	return scannedStr;
}

- (NSMutableAttributedString *)createAttributesStringFromCatalog:(NSString *)str {
	NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:str];
	
	[attrString addAttribute:(NSString *)kCTForegroundColorAttributeName value:(id)_textColor.CGColor range:NSMakeRange(0, str.length)];
	
	for (NSValue *iValue in _boldRanges) {
		[attrString addAttribute:(NSString *)(kCTStrokeWidthAttributeName) value:BOX_FLOAT(-3.0) range:iValue.rangeValue];
	}

	for (NSValue *iValue in _italicRanges) {
		CTFontRef font = CTFontCreateWithName((__bridge CFStringRef)([UIFont italicSystemFontOfSize:12.0].fontName), 12.0, nil);
		[attrString addAttribute:(NSString *)(kCTFontAttributeName) value:(__bridge id)font range:iValue.rangeValue];
	}

	for (NSInteger i=0; i < _fontRanges.count; i += 2) {
		NSValue *iValue = (NSValue *)[_fontRanges objectAtIndex:i];
		NSString *iFontName = (NSString *)[_fontRanges objectAtIndex:i+1];

		CTFontRef font = CTFontCreateWithName((__bridge CFStringRef)iFontName, 12.0, nil);
		[attrString addAttribute:(NSString *)(kCTFontAttributeName) value:(__bridge id)font range:iValue.rangeValue];
	}
	
	return attrString;
}


@end
