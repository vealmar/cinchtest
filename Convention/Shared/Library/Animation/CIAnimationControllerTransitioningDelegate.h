//
// Created by David Jafari on 2/10/15.
// Copyright (c) 2015 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CIReversibleAnimationController;


@interface CIAnimationControllerTransitioningDelegate : NSObject <UIViewControllerTransitioningDelegate>

- (instancetype)initWithAnimationController:(CIReversibleAnimationController *)animationController;

+ (instancetype)delegateWithAnimationController:(CIReversibleAnimationController *)animationController;

@end