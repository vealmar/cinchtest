//
// Created by David Jafari on 3/17/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import "CISlidingProductViewController.h"
#import "CIProductViewController.h"
#import "CIShipDatesViewController.h"
#import "ShowConfigurations.h"

@interface CISlidingProductViewController ()

@property CIShipDatesViewController *shipDateController;

@end


@implementation CISlidingProductViewController

- (id)initWithTopViewController:(CIProductViewController *)productViewController {
    self = [super initWithTopViewController:productViewController];

    if (self) {
        productViewController.slidingProductViewControllerDelegate = self;

        if ([ShowConfigurations instance].shipDates) {
            self.shipDateController = [self initializeShipDateController:productViewController];
            self.underRightViewController = self.shipDateController;
        }

        // enable swiping on the top view
//        self.topViewAnchoredGesture = ECSlidingViewControllerAnchoredGestureTapping;
        [productViewController.view addGestureRecognizer:self.panGesture];
//        [productViewController.view addGestureRecognizer:self.resetTapGesture];

        UIView *productView = productViewController.view;
        UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:productView.bounds];
        productView.layer.masksToBounds = NO;
        productView.layer.shadowColor = [UIColor blackColor].CGColor;
        productView.layer.shadowOffset = CGSizeMake(5.0f, 5.0f);
        productView.layer.shadowOpacity = 0.4f;
        productView.layer.shadowPath = shadowPath.CGPath;
        productView.backgroundColor = [UIColor colorWithRed:57/255.0f green:59/255.0f blue:64/255.0f alpha:1];

        // configure anchored layout
        self.anchorRightPeekAmount  = 330.0;
        self.anchorLeftRevealAmount = 330.0;
    }

    return self;
}

- (UIViewController *)initializeShipDateController:(CIProductViewController *)productViewController {
    CIShipDatesViewController *shipDateController = [[CIShipDatesViewController alloc] initWithWorkingOrder:productViewController.coreDataOrder];

    //listen for changes KVO
    [productViewController addObserver:self forKeyPath:@"coreDataOrder" options:NSKeyValueObservingOptionNew context:nil];

    // configure under right view controller
    shipDateController.edgesForExtendedLayout = UIRectEdgeTop | UIRectEdgeBottom | UIRectEdgeRight; // don't go under the top view

    return shipDateController;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (@"coreDataOrder" == keyPath) {
        self.shipDateController.workingOrder = [change objectForKey:@"new"];
    }
}

#pragma mark slidingProductViewControllerDelegate

- (void)toggleShipDates {
    if (self.currentTopViewPosition == ECSlidingViewControllerTopViewPositionCentered) {
        [self anchorTopViewToLeftAnimated:true];
    } else if (self.currentTopViewPosition == ECSlidingViewControllerTopViewPositionAnchoredLeft) {
        [self resetTopViewAnimated:true];
    }
}

@end
