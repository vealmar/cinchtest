//
// Created by David Jafari on 3/17/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "ECSlidingViewController.h"

@class CIProductViewController;
@protocol CISlidingProductViewControllerDelegate;
@class Cart;

@interface CISlidingProductViewController : ECSlidingViewController <CISlidingProductViewControllerDelegate>

- (id)initWithTopViewController:(CIProductViewController *)productViewController;

@end

@protocol CISlidingProductViewControllerDelegate <NSObject>

@required

-(void)toggleShipDates;

@end