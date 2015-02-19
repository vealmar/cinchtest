//
// Created by David Jafari on 3/17/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "CIProductDetailTableViewController.h"

@class CIProductViewController;

@protocol CISlidingProductDetailViewControllerDelegate

-(void)close;

@end

@interface CISlidingProductDetailViewController : UIViewController <CISlidingProductDetailViewControllerDelegate, UIGestureRecognizerDelegate>

- (id)initWithTopViewController:(CIProductViewController *)productViewController;

-(void)open:(Order *)order lineItem:(LineItem *)lineItem;
-(void)close;

@end