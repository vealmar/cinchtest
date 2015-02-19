//
//  CIFinalCustomerFormViewController.h
//  Convention
//
//  Created by Bogdan Covaci on 31.10.2014.
//  Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CIModalFormViewController.h"

@class Order;
@protocol CIFinalCustomerDelegate;

@interface CIFinalCustomerFormViewController : CIModalFormViewController

@property (strong, nonatomic) Order *order;
@property(nonatomic, assign) id <CIFinalCustomerDelegate> delegate;

@end
