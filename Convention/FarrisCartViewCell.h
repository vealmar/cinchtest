//
// Created by septerr on 9/2/13.
// Copyright (c) 2013 Convention Innovations. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>
#import "CartViewCell.h"

@protocol ProductCellDelegate;
@class ALineItem;
@class Product;
@class DiscountLineItem;


@interface FarrisCartViewCell : CartViewCell
@property(weak, nonatomic) IBOutlet UILabel *descr;
@property(weak, nonatomic) IBOutlet UILabel *descr1;
@property(weak, nonatomic) IBOutlet UILabel *descr2;
@property(weak, nonatomic) IBOutlet UILabel *min;
@property(weak, nonatomic) IBOutlet UITextField *quantity;
@property(weak, nonatomic) IBOutlet UILabel *qtyLbl;
@property(weak, nonatomic) IBOutlet UILabel *regPrice;
@property(weak, nonatomic) IBOutlet UILabel *showPrice;

- (IBAction)quantityChanged:(id)sender;

- (void)initializeWithCart:(Cart *)cart tag:(NSInteger)tag ProductCellDelegate:(id <ProductCellDelegate>)productCellDelegate;

- (void)initializeWithDiscount:(DiscountLineItem *)discount tag:(NSInteger)tag ProductCellDelegate:(id <ProductCellDelegate>)productCellDelegate;
@end