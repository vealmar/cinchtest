//
// Created by David Jafari on 12/13/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import "ThemeUtil.h"
#import "StringManipulation.h"


@implementation ThemeUtil

+ (UIColor *)offBlackColor {
    return [UIColor colorWithRed:0.235 green:0.247 blue:0.251 alpha:1.000];
}

+ (UIColor *)blackColor {
    return [UIColor colorWithRed:0.157 green:0.173 blue:0.173 alpha:1.000];
}

+ (UIColor *)noteColor {
    return [UIColor colorWithRed:0.467 green:0.467 blue:0.500 alpha:1.000];
}

+ (UIColor *)orangeColor {
    return [UIColor colorWithRed:0.992 green:0.545 blue:0.145 alpha:1.000];
}

+ (UIColor *)darkBlueColor {
    return [UIColor colorWithRed:0.161 green:0.502 blue:0.725 alpha:1.000];
}

+ (UIColor *)lightBlueColor {
    return [UIColor colorWithRed:0.416 green:0.824 blue:0.922 alpha:1.000];
}

+ (UIColor *)lightBlueBorderColor {
    return [UIColor colorWithRed:0.122 green:0.725 blue:0.882 alpha:1.000];
}

+ (UIColor *)offWhiteColor {
    return [UIColor colorWithRed:0.945 green:0.953 blue:0.965 alpha:1.000];
}

+ (UIColor *)offWhiteBorderColor {
    return [UIColor colorWithRed:0.859 green:0.882 blue:0.910 alpha:1.000];
}

+ (UIColor *)lightGreenColor {
    return [UIColor colorWithRed:0.667 green:0.820 blue:0.471 alpha:1.000];
}

+ (UIColor *)lightGreenBorderColor {
    return [UIColor colorWithRed:0.490 green:0.722 blue:0.192 alpha:1.000];
}

+ (UIColor *)greenColor {
    return [UIColor colorWithRed:0.153 green:0.682 blue:0.376 alpha:1.000];
}

+ (UIColor *)tableAltRowColor {
    return [UIColor colorWithRed:0.976 green:0.976 blue:0.976 alpha:1];
}

+ (NSDictionary *)navigationTitleTextAttributes:(int)size {
    NSShadow *shadow = [NSShadow new];
    shadow.shadowColor = [UIColor blackColor];
    shadow.shadowOffset = CGSizeMake(0, 1.0f);
    return @{
        NSFontAttributeName: [UIFont regularFontOfSize:size],
        NSForegroundColorAttributeName: [UIColor whiteColor],
        NSShadowAttributeName: shadow
    };
}

/*
Generates a title label based on the format parameter.

@param format Format defining two tokens, %s the text, %l for light text, and %b for bolded text.
 */
+ (NSAttributedString *)titleTextWithFontSize:(int)size format:(NSString *)format, ... {
    NSMutableAttributedString *builder = [[NSMutableAttributedString alloc] initWithString:format attributes:[ThemeUtil navigationTitleTextAttributes:size]];
    NSRange visibleTextRange = NSMakeRange(0, format.length);
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\%\\w" options:NSRegularExpressionCaseInsensitive error:nil];
    NSArray *matches = [regex matchesInString:format options:NSMatchingReportProgress range:visibleTextRange];

    va_list args;
    va_start(args, format);
    int offset = 0;
    for (NSTextCheckingResult *match in matches) {
        NSRange matchRange = match.range;
        NSString* content = va_arg(args, NSString*);
        NSDictionary *attrs = [ThemeUtil navigationTitleTextAttributes:size];
        if ([[format substringWithRange:matchRange] contains:@"b"]) {
            NSMutableDictionary *boldAttrs = [NSMutableDictionary dictionaryWithDictionary:attrs];
            boldAttrs[NSFontAttributeName] = [UIFont semiboldFontOfSize:size];
            attrs = boldAttrs;
        } else if ([[format substringWithRange:matchRange] contains:@"l"]) {
            NSMutableDictionary *lightAttrs = [NSMutableDictionary dictionaryWithDictionary:attrs];
            lightAttrs[NSFontAttributeName] = [UIFont lightFontOfSize:size];
            attrs = lightAttrs;
        }
        NSAttributedString *attributedContent = [[NSAttributedString alloc] initWithString:content attributes:attrs];
        [builder replaceCharactersInRange:NSMakeRange(matchRange.location + offset, matchRange.length) withAttributedString:attributedContent];
        offset += content.length - matchRange.length;
    }
    va_end(args);

    return builder;
}

+ (NSDictionary *)navigationSearchLabelTextAttributes {
    return @{
        NSFontAttributeName: [UIFont regularFontOfSize:14],
        NSForegroundColorAttributeName: [UIColor colorWithRed:153.0f/255.0f green:153.0f/255.0f blue:153.0f/255.0f alpha:1]
    };
}

+ (NSDictionary *)navigationSearchLabelInputAttributes {
    return @{ };
}

+ (NSDictionary *)navigationLeftActionButtonTextAttributes {
    return @{
        NSFontAttributeName: [UIFont iconFontOfSize:20],
        NSForegroundColorAttributeName: [UIColor whiteColor]
    };
}

+ (NSDictionary *)navigationRightActionButtonTextAttributes {
    return @{
        NSFontAttributeName: [UIFont iconFontOfSize:14],
        NSForegroundColorAttributeName: [UIColor whiteColor]
    };
}

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

@end