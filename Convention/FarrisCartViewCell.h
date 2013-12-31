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

- (void)initializeWith:(Product *)product cart:(Cart *)cart tag:(NSInteger)tag ProductCellDelegate:(id <ProductCellDelegate>)productCellDelegate;

- (void)initializeForDiscountWithProduct:(Product *)product quantity:(NSString *)ITEMQuantity price:(NSNumber *)price tag:(NSInteger)tag ProductCellDelegate:(id <ProductCellDelegate>)productCellDelegate;
@end