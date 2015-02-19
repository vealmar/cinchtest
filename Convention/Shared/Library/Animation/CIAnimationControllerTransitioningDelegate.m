//
// Created by David Jafari on 2/10/15.
// Copyright (c) 2015 Urban Coding. All rights reserved.
//

#import "CIAnimationControllerTransitioningDelegate.h"
#import "CIReversibleAnimationController.h"

@interface CIAnimationControllerTransitioningDelegate ()

@property CIReversibleAnimationController *animationController;

@end

@implementation CIAnimationControllerTransitioningDelegate

- (instancetype)initWithAnimationController:(CIReversibleAnimationController *)animationController {
    self = [super init];
    if (self) {
        self.animationController = animationController;
    }

    return self;
}

+ (instancetype)delegateWithAnimationController:(CIReversibleAnimationController *)animationController {
    return [[self alloc] initWithAnimationController:animationController];
}

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    return self.animationController;
}

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    return self.animationController;
}


@end