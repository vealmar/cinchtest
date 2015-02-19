//
// Created by David Jafari on 2/13/15.
// Copyright (c) 2015 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Order;
@class LineItem;
@protocol CISlidingProductDetailViewControllerDelegate;

@interface CIProductDetailViewController : UIViewController

@property (weak) id<CISlidingProductDetailViewControllerDelegate> presenterDelegate;

- (id)init;

- (void)prepareForDisplay:(Order *)order lineItem:(LineItem *)lineItem;

@end