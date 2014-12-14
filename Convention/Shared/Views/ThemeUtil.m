//
// Created by David Jafari on 12/13/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import "ThemeUtil.h"
#import "StringManipulation.h"
#import "tgmath.h"


@implementation ThemeUtil

+ (NSDictionary *)navigationTitleTextAttributes {
    NSShadow *shadow = [NSShadow new];
    shadow.shadowColor = [UIColor blackColor];
    shadow.shadowOffset = CGSizeMake(0, 1.0f);
    return @{
        NSFontAttributeName: [UIFont regularFontOfSize:18],
        NSForegroundColorAttributeName: [UIColor whiteColor],
        NSShadowAttributeName: shadow
    };
}

/*
Generates a title label based on the format parameter.

@param format Format defining two tokens, %s the text, %b for bolded text.
 */
+ (UILabel *)navigationTitleFor:(NSString *)format, ... {
    NSMutableAttributedString *builder = [[NSMutableAttributedString alloc] initWithString:format];
    NSRange visibleTextRange = NSMakeRange(0, format.length);
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\%\\w" options:NSRegularExpressionCaseInsensitive error:nil];
    NSArray *matches = [regex matchesInString:format options:NSMatchingReportProgress range:visibleTextRange];

    va_list args;
    va_start(args, format);
    int offset = 0;
    for (NSTextCheckingResult *match in matches) {
        NSRange matchRange = match.range;
        NSString* content = va_arg(args, NSString*);
        NSDictionary *attrs = [ThemeUtil navigationTitleTextAttributes];
        if ([[format substringWithRange:matchRange] contains:@"b"]) {
            NSMutableDictionary *boldAttrs = [NSMutableDictionary dictionaryWithDictionary:attrs];
            boldAttrs[NSFontAttributeName] = [UIFont semiboldFontOfSize:18];
            attrs = boldAttrs;
        }
        NSAttributedString *attributedContent = [[NSAttributedString alloc] initWithString:content attributes:attrs];
        [builder replaceCharactersInRange:NSMakeRange(matchRange.location + offset, matchRange.length) withAttributedString:attributedContent];
        offset += content.length - matchRange.length;
    }
    va_end(args);

    CGRect totalHeightRect = [builder boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin context:nil];
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(512.0f - floor(totalHeightRect.size.width / 2.0f), 5.0f, totalHeightRect.size.width, totalHeightRect.size.height)];
    titleLabel.attributedText = builder;

    return titleLabel;
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

+ (UIColor *)navigationBarTintColor {
    return [UIColor colorWithRed:0.235 green:0.247 blue:0.251 alpha:1.000];

//    return [UIColor colorWithRed:60.0f/255.0f green:63.0f/255.0f blue:64.0f/255.0f alpha:1];
}

@end