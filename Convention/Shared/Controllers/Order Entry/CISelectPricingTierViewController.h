//
// Created by David Jafari on 2/16/15.
// Copyright (c) 2015 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CIModalFormViewController.h"

@class Order;


@interface CISelectPricingTierViewController : CIModalFormViewController

-(void)prepareForDisplay:(Order *)order;

@end