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
        [productViewController.view addGestureRecognizer:self.panGesture];

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

    // configure under right view controller
    shipDateController.edgesForExtendedLayout = UIRectEdgeTop | UIRectEdgeBottom | UIRectEdgeRight; // don't go under the top view

    return shipDateController;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    //listen for changes KVO
    CIProductViewController *productViewController = (CIProductViewController *) self.topViewController;
    [productViewController addObserver:self forKeyPath:NSStringFromSelector(@selector(coreDataOrder)) options:NSKeyValueObservingOptionNew context:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    //remove KVO observers
    CIProductViewController *productViewController = (CIProductViewController *) self.topViewController;
    [productViewController removeObserver:self forKeyPath:NSStringFromSelector(@selector(coreDataOrder))];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    UITapGestureRecognizer *productViewTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(productViewTapped:)];
    productViewTapRecognizer.numberOfTapsRequired = 1;
    productViewTapRecognizer.cancelsTouchesInView = NO;
    self.topViewController.view.userInteractionEnabled = YES;
    [self.topViewController.view addGestureRecognizer:productViewTapRecognizer];

    UITapGestureRecognizer *shipdateViewTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(shipdateViewTapped:)];
    shipdateViewTapRecognizer.numberOfTapsRequired = 1;
    shipdateViewTapRecognizer.cancelsTouchesInView = NO;
    self.underRightViewController.view.userInteractionEnabled = YES;
    [self.underRightViewController.view addGestureRecognizer:shipdateViewTapRecognizer];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (NSStringFromSelector(@selector(coreDataOrder)) == keyPath) {
        self.shipDateController.workingOrder = [change objectForKey:@"new"];
    }
}

//User is in middle of editing a quantity (so the keyboard is visible), then taps somewhere else on the screen - the keyboard should disappear.
- (void)productViewTapped:(UITapGestureRecognizer *)recognizer {
        if (recognizer.state == UIGestureRecognizerStateEnded) {
        CIProductViewController *productViewController = (CIProductViewController *)self.topViewController;
        [self resetTopViewAnimated:YES];
        [productViewController.view endEditing:YES];
        [productViewController.selectedCarts enumerateObjectsUsingBlock:^(Cart *cart, BOOL *stop) {
            [productViewController toggleCartSelection:cart]; //disable selection
        }];
    }
}

//User is in middle of editing a quantity (so the keyboard is visible), then taps somewhere else on the screen - the keyboard should disappear.
- (void)shipdateViewTapped:(UITapGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        [self.underRightViewController.view endEditing:YES];
    }
}

#pragma mark slidingProductViewControllerDelegate

- (void)toggleShipDates:(BOOL)shouldOpen {
    if (shouldOpen && self.currentTopViewPosition == ECSlidingViewControllerTopViewPositionCentered) {
        [self anchorTopViewToLeftAnimated:true];
    } else if (!shouldOpen && self.currentTopViewPosition == ECSlidingViewControllerTopViewPositionAnchoredLeft) {
        [self resetTopViewAnimated:true];
    }
}

@end
