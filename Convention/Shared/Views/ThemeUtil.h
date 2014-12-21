//
// Created by David Jafari on 12/13/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ThemeUtil : NSObject

+ (UIColor *)offBlackColor;
+ (UIColor *)blackColor;
+ (UIColor *)noteColor;
+ (UIColor *)orangeColor;
+ (UIColor *)blueColor;
+ (UIColor *)greenColor;
+ (UIColor *)tableAltRowColor;

/*
    Generates a title label based on the format parameter.

    @param format Format defining two tokens, %s the text, %b for bolded text.
 */
+ (NSAttributedString *)titleTextWithFontSize:(int)size format:(NSString *)format, ... NS_REQUIRES_NIL_TERMINATION;

+ (NSDictionary *)navigationSearchLabelTextAttributes;

+ (NSDictionary *)navigationSearchLabelInputAttributes;

+ (NSDictionary *)navigationLeftActionButtonTextAttributes;

+ (NSDictionary *)navigationRightActionButtonTextAttributes;

@end