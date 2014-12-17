//
// Created by David Jafari on 12/15/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface CIKeyboardUtil : NSObject

+ (void)keyboardWillShow:(NSNotification *)notification adjustView:(UIView *)view;

+ (void)keyboardWillShow:(NSNotification *)notification adjustConstraint:(NSLayoutConstraint *)constraint in:(UIView *)view;

+ (void)keyboardWillHide:(NSNotification *)notification adjustConstraint:(NSLayoutConstraint *)constraint in:(UIView *)view;

@end