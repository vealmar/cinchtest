//
// Created by septerr on 9/2/13.
// Copyright (c) 2013 Convention Innovations. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>
#import "CartViewCell.h"

@protocol ProductCellDelegate;
@class Product;
@class LineItem;

@interface FarrisCartViewCell : CartViewCell
@property(weak, nonatomic) IBOutlet UILabel *descr;
@property(weak, nonatomic) IBOutlet UILabel *descr1;
@property(weak, nonatomic) IBOutlet UILabel *descr2;
@property(weak, nonatomic) IBOutlet UILabel *min;
@property(weak, nonatomic) IBOutlet UITextField *quantity;
@property(weak, nonatomic) IBOutlet UILabel *qtyLbl;
@property(weak, nonatomic) IBOutlet UILabel *price1;
@property(weak, nonatomic) IBOutlet UILabel *price2;
@property(weak, nonatomic) IBOutlet UILabel *numOfShipDates;

- (IBAction)quantityChanged:(id)sender;

- (void)initializeWithCart:(LineItem *)lineItemInitial tag:(NSInteger)tag ProductCellDelegate:(id <ProductCellDelegate>)productCellDelegate;

- (void)initializeWithDiscount:(LineItem *)discount tag:(NSInteger)tag ProductCellDelegate:(id <ProductCellDelegate>)productCellDelegate;
@end