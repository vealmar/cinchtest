//
// Created by David Jafari on 2/10/15.
// Copyright (c) 2015 Urban Coding. All rights reserved.
//

#import "CIPanAnimationController.h"

@implementation CIPanAnimationController

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext fromVC:(UIViewController *)fromVC toVC:(UIViewController *)toVC fromView:(UIView *)fromView toView:(UIView *)toView {

    self.duration = 0.20F;
    // Add the toView to the container
    if (!self.reverse) {
        UIView *containerView = [transitionContext containerView];
        [containerView addSubview:toView];
    }

    UIView *animatedView = self.reverse ? fromView : toView;

    CGFloat width = animatedView.frame.size.width;
    CGFloat height = animatedView.frame.size.height;
    CGFloat y = animatedView.frame.origin.y;
    CGFloat x = self.reverse ? animatedView.frame.origin.x : 1024;

    if (!self.reverse) {
        animatedView.layer.opacity = 0.2;
    }
    animatedView.frame = CGRectMake(x, y, width, height);

    CGFloat finalXPosition = self.reverse ? 1024 : 1024 - width;

//    self.reverse ? [containerView sendSubviewToBack:toView] : [containerView bringSubviewToFront:toView];

    // animate
    NSTimeInterval duration = [self transitionDuration:transitionContext];
    [UIView animateWithDuration:duration animations:^{
//        fromView.frame = CGRectMake(!self.reverse ? -160 : 320, fromView.frame.origin.y, fromView.frame.size.width, fromView.frame.size.height);
        animatedView.frame = CGRectMake(finalXPosition, y, width, height);
        if (self.reverse) {
            animatedView.layer.opacity = 0.2;
        } else {
            animatedView.layer.opacity = 1.0;
        }
    } completion:^(BOOL finished) {
        if ([transitionContext transitionWasCancelled]) {
//            toView.frame = CGRectMake(0, y, width, height);
            toView.frame = CGRectMake(toView.frame.origin.x, toView.frame.origin.y, toView.frame.size.width, toView.frame.size.height);
            fromView.frame = CGRectMake(fromView.frame.origin.x, fromView.frame.origin.y, fromView.frame.size.width, fromView.frame.size.height);
        } else {
            // reset from- view to its original state
            //[fromView removeFromSuperview];
//            toView.frame = CGRectMake(1024 - width, y, width, height);
            if (!self.reverse) {
                fromView.frame = CGRectMake(fromView.frame.origin.x, fromView.frame.origin.y, fromView.frame.size.width, fromView.frame.size.height);
                toView.frame = CGRectMake(toView.frame.origin.x, toView.frame.origin.y, toView.frame.size.width, toView.frame.size.height);
            }
        }
        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
    }];

}

- (UIViewAnimationCurve)completionCurve {
    return UIViewAnimationCurveEaseInOut;
}

- (void)startInteractiveTransition:(id <UIViewControllerContextTransitioning>)transitionContext {

}

- (CGFloat)completionSpeed {
    return self.duration;
}


@end