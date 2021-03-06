//
// Created by David Jafari on 12/15/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import "CIKeyboardUtil.h"


@implementation CIKeyboardUtil

+ (void)keyboardWillShow:(NSNotification *)notification adjustView:(UIView *)view {
    NSDictionary *info = [notification userInfo];
    NSValue *kbFrame = [info objectForKey:UIKeyboardFrameEndUserInfoKey];
    NSTimeInterval animationDuration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    CGRect keyboardFrame = [kbFrame CGRectValue];

    CGFloat height = keyboardFrame.size.height;

    view.frame = CGRectMake(view.frame.origin.x, view.frame.origin.y, view.frame.size.width, view.frame.size.height - height);

    [UIView animateWithDuration:animationDuration animations:^{
        [view layoutIfNeeded];
    }];
}


+ (void)keyboardWillShow:(NSNotification *)notification adjustConstraint:(NSLayoutConstraint *)constraint in:(UIView *)view {
    NSDictionary *info = [notification userInfo];
    NSValue *kbFrame = [info objectForKey:UIKeyboardFrameEndUserInfoKey];
    NSTimeInterval animationDuration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    CGRect keyboardFrame = [kbFrame CGRectValue];

    // simulator doesn't provide correct height, doesn't account for orientation
    // regardless, the lesser of these two values is also correct as the alternate dimension will
    // be either the device's height or width which will be greater than ~350.0f.
    CGFloat height = MIN(keyboardFrame.size.width, keyboardFrame.size.height);

    // Because the "space" is actually the difference between the bottom lines of the 2 views,
    // we need to set a negative constant value here.
    constraint.constant = height;

    [UIView animateWithDuration:animationDuration animations:^{
        [view layoutIfNeeded];
    }];
}

+ (void)keyboardWillHide:(NSNotification *)notification adjustConstraint:(NSLayoutConstraint *)constraint in:(UIView *)view {
    NSTimeInterval animationDuration = 0;

    if (notification) {
        NSDictionary *info = [notification userInfo];
        animationDuration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    }

    constraint.constant = 0;
    [UIView animateWithDuration:animationDuration animations:^{
        [view layoutIfNeeded];
    }];
}

@end