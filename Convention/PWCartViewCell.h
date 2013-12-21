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


@interface PWCartViewCell : CartViewCell
@property(weak, nonatomic) IBOutlet UILabel *numShipDates;
@property(weak, nonatomic) IBOutlet UILabel *qtyLbl;
@property(weak, nonatomic) IBOutlet UITextField *voucher;
@property(weak, nonatomic) IBOutlet UILabel *priceLbl;
@property(weak, nonatomic) IBOutlet UILabel *descr;
@property(weak, nonatomic) IBOutlet UILabel *shipDate1;
@property(weak, nonatomic) IBOutlet UILabel *shipDate2;
@property(weak, nonatomic) IBOutlet UILabel *CaseQty;
@property(weak, nonatomic) IBOutlet UIButton *qtyBtn;

- (IBAction)qtyTouch:(id)sender;

- (IBAction)voucherDidChange:(id)sender;

- (void)initializeWith:(BOOL)multiStore showPrice:(BOOL)showPrice product:(NSDictionary *)product tag:(NSInteger)tag
              quantity:(NSString *)quantity
                 price:(NSNumber *)price
               voucher:(NSNumber *)voucherPrice
             shipDates:(int)numOfShipDates
   productCellDelegate:(id <ProductCellDelegate>)productCellDelegate;
@end