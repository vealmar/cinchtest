//
// Created by David Jafari on 2/10/15.
// Copyright (c) 2015 Urban Coding. All rights reserved.
//

#import "CIReversibleAnimationController.h"


@implementation CIReversibleAnimationController

- (id)init {
    if (self = [super init]) {
        self.duration = 1.0f;
    }
    return self;
}

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return self.duration;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *toView = toVC.view;
    UIView *fromView = fromVC.view;

    [self animateTransition:transitionContext fromVC:fromVC toVC:toVC fromView:fromView toView:toView];
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext fromVC:(UIViewController *)fromVC toVC:(UIViewController *)toVC fromView:(UIView *)fromView toView:(UIView *)toView {
}

@end