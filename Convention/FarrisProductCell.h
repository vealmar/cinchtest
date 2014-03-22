//
//  FarrisProductCell.h
//  Convention
//
//  Created by Kerry Sanders on 1/20/13.
//  Copyright (c) 2013 MotionMobs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ProductCellDelegate.h"
#import "ProductCell.h"

@class Cart;
@class Product;
@class AProduct;

@interface FarrisProductCell : ProductCell

@property(weak, nonatomic) IBOutlet UILabel *itemNumber;
@property(weak, nonatomic) IBOutlet UILabel *descr1;
@property(weak, nonatomic) IBOutlet UILabel *descr2;
@property(weak, nonatomic) IBOutlet UILabel *min;
@property(weak, nonatomic) IBOutlet UITextField *quantity;
@property(weak, nonatomic) IBOutlet UILabel *regPrice;
@property(weak, nonatomic) IBOutlet UILabel *showPrice;
@property(weak, nonatomic) IBOutlet UILabel *qtyLbl;
@property(weak, nonatomic) IBOutlet UILabel *descr;
@property(weak, nonatomic) IBOutlet UILabel *numOfShipDates;
@property(weak, nonatomic) IBOutlet UITextField *editableShowPrice;

- (IBAction)quantityChanged:(id)sender;

- (IBAction)showPriceChanged:(id)sender;

@property(nonatomic, assign) id <ProductCellDelegate> delegate;

- (void)setDescription:(NSString *)description1 withSubtext:(NSString *)description2;

- (void)initializeWithAProduct:(AProduct *)product cart:(Cart *)cart tag:(NSInteger)tag ProductCellDelegate:(id <ProductCellDelegate>)productCellDelegate;
@end
