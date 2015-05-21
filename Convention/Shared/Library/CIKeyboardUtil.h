//
// Created by David Jafari on 12/15/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface CIKeyboardUtil : NSObject

/**
* constraint should be the vertical distance constraint that defines a distance of 0 between the bottom of the screen and the view that should be pushed up so it is not covered by the keyboard.
*/
+ (void)keyboardWillShow:(NSNotification *)notification adjustConstraint:(NSLayoutConstraint *)constraint in:(UIView *)view;

/**
* constraint should be the vertical distance constraint that defines a distance of 0 between the bottom of the screen and the view that was pushed up so it would not covered by the keyboard.
*/
+ (void)keyboardWillHide:(NSNotification *)notification adjustConstraint:(NSLayoutConstraint *)constraint in:(UIView *)view;
@end