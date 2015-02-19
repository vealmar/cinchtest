//
// Created by David Jafari on 2/12/15.
// Copyright (c) 2015 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface LayoutUtil : NSObject

+ (CGRect)fitTextWidthTo:(UILabel *)label;
+ (CGRect)fitTextHeightTo:(UITextView *)textView;
+ (CGFloat)textHeightIn:(UITextView *)textView;

@end