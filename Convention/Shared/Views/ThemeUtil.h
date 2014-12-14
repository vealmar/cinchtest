//
// Created by David Jafari on 12/13/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ThemeUtil : NSObject

/*
    Generates a title label based on the format parameter.

    @param format Format defining two tokens, %s the text, %b for bolded text.
 */
+ (UILabel *)navigationTitleFor:(NSString *)components, ... NS_REQUIRES_NIL_TERMINATION;

+ (NSDictionary *)navigationSearchLabelTextAttributes;

+ (NSDictionary *)navigationSearchLabelInputAttributes;

+ (NSDictionary *)navigationLeftActionButtonTextAttributes;

+ (NSDictionary *)navigationRightActionButtonTextAttributes;

+ (UIColor *)navigationBarTintColor;

@end