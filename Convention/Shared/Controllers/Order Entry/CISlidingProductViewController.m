//
// Created by David Jafari on 3/17/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import "CISlidingProductViewController.h"
#import "CIProductViewController.h"
#import "ShowConfigurations.h"

@interface CISlidingProductViewController ()

@property UITapGestureRecognizer *productViewTapRecognizer;
@property UITapGestureRecognizer *shipdateViewTapRecognizer;

@end


@implementation CISlidingProductViewController

- (id)initWithTopViewController:(CIProductViewController *)productViewController {
    self = [super initWithTopViewController:productViewController];

    if (self) {
        if ([ShowConfigurations instance].shipDates) {
            self.shipDateController = [self initializeShipDateController:productViewController];
            self.underRightViewController = self.shipDateController;
        }

        // enable swiping on the top view
        [productViewController.view addGestureRecognizer:self.panGesture];
        // remove the ecsliding action so ours comes first - theirs triggers userInteractionEnabled = NO and we need to
        // be able to endEditing on our views before this happens (without interaction, nothing will happen)
        [self.panGesture removeTarget:self action:@selector(detectPanGestureRecognizer:)];
        [self.panGesture addTarget:self action:@selector(onPanGesture:)];
        [self.panGesture addTarget:self action:@selector(detectPanGestureRecognizer:)];
        // disable by default, we only let them slide the pane closed; we dont let them open without first selecting a line
        self.panGesture.enabled = NO;

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
    CIShipDatesViewController *shipDateController = [[CIShipDatesViewController alloc] initWithWorkingOrder:productViewController.order];

    // configure under right view controller
    shipDateController.edgesForExtendedLayout = UIRectEdgeTop | UIRectEdgeBottom | UIRectEdgeRight; // don't go under the top view

    return shipDateController;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    CIProductViewController *productViewController = (CIProductViewController *) self.topViewController;
    productViewController.slidingProductViewControllerDelegate = self;

    self.productViewTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(productViewTapped:)];
    self.productViewTapRecognizer.numberOfTapsRequired = 1;
    self.productViewTapRecognizer.cancelsTouchesInView = NO;
    self.topViewController.view.userInteractionEnabled = YES;
    [self.topViewController.view addGestureRecognizer:self.productViewTapRecognizer];

    self.shipdateViewTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(shipdateViewTapped:)];
    self.shipdateViewTapRecognizer.numberOfTapsRequired = 1;
    self.shipdateViewTapRecognizer.cancelsTouchesInView = NO;
    self.underRightViewController.view.userInteractionEnabled = YES;
    [self.underRightViewController.view addGestureRecognizer:self.shipdateViewTapRecognizer];

    //listen for changes KVO
    [productViewController addObserver:self forKeyPath:NSStringFromSelector(@selector(order)) options:NSKeyValueObservingOptionNew context:nil];

    // the child view will have viewWillAppear run first, so we want to capture any working order changes
    // since they won't trigger the above KVO handler as the handler is initialized in this parent view controller's
    // viewWillAppear
    self.shipDateController.workingOrder = productViewController.order;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    CIProductViewController *productViewController = (CIProductViewController *) self.topViewController;
    productViewController.slidingProductViewControllerDelegate = nil;

    //remove KVO observers
    [productViewController removeObserver:self forKeyPath:NSStringFromSelector(@selector(order))];

    [self.topViewController.view removeGestureRecognizer:self.productViewTapRecognizer];
    [self.underRightViewController.view removeGestureRecognizer:self.shipdateViewTapRecognizer];
}

- (void)viewDidLoad {
    [super viewDidLoad];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([NSStringFromSelector(@selector(order)) isEqualToString:keyPath]) {
        id newValue = [change objectForKey:@"new"];
        self.shipDateController.workingOrder = [[NSNull null] isEqual:newValue] ? nil : (Order *) newValue;
    }
}

//User is in middle of editing a quantity (so the keyboard is visible), then taps somewhere else on the screen - the keyboard should disappear.
- (void)productViewTapped:(UITapGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        [self reset];
    }
}

- (void)onPanGesture:(UIPanGestureRecognizer *)recognizer {
    if (self.currentTopViewPosition == ECSlidingViewControllerTopViewPositionAnchoredLeft) {
        if (recognizer.state == UIGestureRecognizerStateBegan) {
            [self.underRightViewController.view endEditing:YES];
            [self.topViewController.view endEditing:YES];
        }
    }
    
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        CGFloat velocityX = [recognizer velocityInView:self.view].x;

        // the animation will end in the sidepane being closed, we are moving in a positive X direction
        // towards that side of the screen
        if (velocityX > 0) {
            [self deselectAllCarts];
            self.panGesture.enabled = NO;
        }
    }
}

//User is in middle of editing a quantity (so the keyboard is visible), then taps somewhere else on the screen - the keyboard should disappear.
- (void)shipdateViewTapped:(UITapGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        [self.underRightViewController.view endEditing:YES];
    }
}

- (void)deselectAllCarts {
    CIProductViewController *productViewController = (CIProductViewController *)self.topViewController;
    [productViewController.selectedLineItems enumerateObjectsUsingBlock:^(LineItem *lineItem, BOOL *stop) {
        [productViewController toggleLineSelection:lineItem]; //disable selection
    }];
}

#pragma mark slidingProductViewControllerDelegate

- (void)toggleShipDates:(BOOL)shouldOpen {
    if (shouldOpen && self.currentTopViewPosition == ECSlidingViewControllerTopViewPositionCentered) {
        [self anchorTopViewToLeftAnimated:true];
        self.panGesture.enabled = YES;
    } else if (!shouldOpen && self.currentTopViewPosition == ECSlidingViewControllerTopViewPositionAnchoredLeft) {
        [self.underRightViewController.view endEditing:YES];
        [self resetTopViewAnimated:true];
    }
}

- (void)reset {
    [self deselectAllCarts];
    [self.underRightViewController.view endEditing:YES];
    [self.topViewController.view endEditing:YES];
    [self resetTopViewAnimated:YES];
    self.panGesture.enabled = NO;
}

@end
