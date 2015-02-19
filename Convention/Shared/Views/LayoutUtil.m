//
// Created by David Jafari on 2/12/15.
// Copyright (c) 2015 Urban Coding. All rights reserved.
//

#import "LayoutUtil.h"

@implementation LayoutUtil

+ (CGRect)fitTextWidthTo:(UILabel *)label {
    NSRange range;
    NSDictionary *attributes;
    if (label.attributedText && label.attributedText.length > 0) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[label.attributedText attributesAtIndex:0 effectiveRange:&range]];
        // This seems like an iOS bug, but when you ask for the attributes, it gives you
        // a literal representation of what was passed in when the attributed text was created.
        // On labels, the font property still takes effect.
        [dict setValue:label.font forKey:NSFontAttributeName];
        attributes = [NSDictionary dictionaryWithDictionary:dict];
    }
    if (!attributes || attributes.count == 0) {
        attributes = @{ NSFontAttributeName: label.font };
    }

    CGRect totalHeightRect = [label.text boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, label.frame.size.height)
                                                      options:NSStringDrawingUsesLineFragmentOrigin
                                                   attributes:attributes
                                                      context:nil];

    label.frame = CGRectMake(label.frame.origin.x, label.frame.origin.y, totalHeightRect.size.width, label.frame.size.height);

    return label.frame;
}

+ (CGRect)fitTextHeightTo:(UITextView *)textView {
    textView.frame = CGRectMake(textView.frame.origin.x, textView.frame.origin.y, textView.frame.size.width, [self textHeightIn:textView]);
    return textView.frame;
}

+ (CGFloat)textHeightIn:(UITextView *)textView {
    NSRange range;
    NSDictionary *attributes;
    if (textView.attributedText && textView.attributedText.length > 0) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[textView.attributedText attributesAtIndex:0 effectiveRange:&range]];
        // This seems like an iOS bug, but when you ask for the attributes, it gives you
        // a literal representation of what was passed in when the attributed text was created.
        // On labels, the font property still takes effect.
        [dict setValue:textView.font forKey:NSFontAttributeName];
        attributes = [NSDictionary dictionaryWithDictionary:dict];
    }
    if (!attributes || attributes.count == 0) {
        attributes = @{ NSFontAttributeName: textView.font };
    }

    CGRect totalHeightRect = [textView.text boundingRectWithSize:CGSizeMake(textView.frame.size.width, CGFLOAT_MAX)
                                                         options:NSStringDrawingUsesLineFragmentOrigin
                                                      attributes:attributes
                                                         context:nil];

    return totalHeightRect.size.height;
}

@end