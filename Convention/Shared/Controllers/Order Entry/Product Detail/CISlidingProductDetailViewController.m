//
// Created by David Jafari on 3/17/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import "CISlidingProductDetailViewController.h"
#import "CIProductViewController.h"
#import "CIProductDetailViewController.h"
#import "CIAnimationControllerTransitioningDelegate.h"
#import "CIPanAnimationController.h"

@interface CISlidingProductDetailViewController ()

@property UITapGestureRecognizer *productViewTapRecognizer;
@property UITapGestureRecognizer *shipdateViewTapRecognizer;
@property (weak) CIProductViewController *productViewController;
@property CIProductDetailViewController *productDetailViewController;
@property CIReversibleAnimationController *animationController;
@property id<UIViewControllerTransitioningDelegate> transitioningDelegateRef;

@end

@implementation CISlidingProductDetailViewController

- (id)initWithTopViewController:(CIProductViewController *)productViewController {
    self = [super init];

    if (self) {
        self.view.frame = CGRectMake(0, 0, 400, 768);
        self.view.backgroundColor = [UIColor clearColor];
        self.view.layer.shadowColor = [UIColor colorWithWhite:0 alpha:1].CGColor;
        self.view.layer.shadowOffset = CGSizeMake(-5.0F, 0);
        self.productViewController = productViewController;
        self.productDetailViewController = [[CIProductDetailViewController alloc] init];
        self.productDetailViewController.presenterDelegate = self;
        [self addChildViewController:self.productDetailViewController];
        [self.view addSubview:self.productDetailViewController.view];
        [self initializeTransitions];
    }

    return self;
}

#pragma mark - Lifecycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.shipdateViewTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(shipdateViewTapped:)];
    self.shipdateViewTapRecognizer.numberOfTapsRequired = 1;
    self.shipdateViewTapRecognizer.cancelsTouchesInView = NO;
    self.productDetailViewController.view.userInteractionEnabled = YES;
    [self.productDetailViewController.view addGestureRecognizer:self.shipdateViewTapRecognizer];

    //listen for changes KVO
    [self.productViewController addObserver:self forKeyPath:NSStringFromSelector(@selector(order)) options:NSKeyValueObservingOptionNew context:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    self.productViewTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(productViewTapped:)];
    self.productViewTapRecognizer.numberOfTapsRequired = 1;
    self.productViewTapRecognizer.cancelsTouchesInView = NO;
    self.productViewTapRecognizer.delegate = self;
    self.view.window.userInteractionEnabled = YES;
    [self.view.window addGestureRecognizer:self.productViewTapRecognizer];
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    //remove KVO observers
    [self.productViewController removeObserver:self forKeyPath:NSStringFromSelector(@selector(order))];

    [self.view.window removeGestureRecognizer:self.productViewTapRecognizer];
    [self.productDetailViewController.view removeGestureRecognizer:self.shipdateViewTapRecognizer];
}

#pragma mark - Public Api

-(void)open:(Order *)order lineItem:(LineItem *)lineItem {
    [self.productDetailViewController prepareForDisplay:order lineItem:lineItem];
    //@todo is this while presented or only during the animation itself?
    if (!([self isBeingPresented] || self.view.window)) {
        self.animationController.reverse = NO;
        [self.productViewController presentViewController:self animated:YES completion:nil];
    }
}

-(void)close {
    [self.productDetailViewController.view endEditing:YES];
    if (!self.isBeingDismissed && self.view.window) {
        [self.productViewController deselectAllLines];
        self.animationController.reverse = YES;
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - Gesture Recognizers

//User is in middle of editing a quantity (so the keyboard is visible), then taps somewhere else on the screen - the keyboard should disappear.
- (void)productViewTapped:(UITapGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        CGPoint location = [recognizer locationInView:nil]; //Passing nil gives us coordinates in the window

        //Convert tap location into the local view's coordinate system. If outside, dismiss the view.
        if (![self.productDetailViewController.view pointInside:[self.productDetailViewController.view convertPoint:location fromView:self.view.window] withEvent:nil]) {
            [self close];
        }
    }
}

//- (void)onPanGesture:(UIPanGestureRecognizer *)recognizer {
//    if (self.currentTopViewPosition == ECSlidingViewControllerTopViewPositionAnchoredLeft) {
//        if (recognizer.state == UIGestureRecognizerStateBegan) {
//            [self.productDetailViewController.view endEditing:YES];
//            [self.productViewController.view endEditing:YES];
//        }
//    }
//
//    if (recognizer.state == UIGestureRecognizerStateEnded) {
//        CGFloat velocityX = [recognizer velocityInView:self.view].x;
//
//        // the animation will end in the sidepane being closed, we are moving in a positive X direction
//        // towards that side of the screen
//        if (velocityX > 0) {
//            [self deselectAllCarts];
//            self.panGesture.enabled = NO;
//        }
//    }
//}

//User is in middle of editing a quantity (so the keyboard is visible), then taps somewhere else on the screen - the keyboard should disappear.
- (void)shipdateViewTapped:(UITapGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        [self.productDetailViewController.view endEditing:YES];
    }
}

#pragma mark - Initialization

- (void)initializeTransitions {
    self.animationController = [CIPanAnimationController new];
    self.transitioningDelegateRef = [CIAnimationControllerTransitioningDelegate delegateWithAnimationController:self.animationController];
    self.modalPresentationStyle = UIModalPresentationCustom;
    self.transitioningDelegate = self.transitioningDelegateRef;

    // enable swiping on the top view
//    [productViewController.view addGestureRecognizer:self.panGesture];
//    // remove the ecsliding action so ours comes first - theirs triggers userInteractionEnabled = NO and we need to
//    // be able to endEditing on our views before this happens (without interaction, nothing will happen)
//    [self.panGesture addTarget:self action:@selector(onPanGesture:)];
//    // disable by default, we only let them slide the pane closed; we dont let them open without first selecting a line
//    self.panGesture.enabled = NO;
}

@end
