//
// Created by septerr on 9/2/13.
// Copyright (c) 2013 Convention Innovations. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "FarrisCartViewCell.h"
#import "ProductCellDelegate.h"
#import "config.h"
#import "NumberUtil.h"
#import "ALineItem.h"


@implementation FarrisCartViewCell {

}
@synthesize descr;
@synthesize descr1;
@synthesize descr2;
@synthesize min;
@synthesize quantity;
@synthesize qtyLbl;
@synthesize regPrice;
@synthesize showPrice;

- (void)initializeWith:(NSDictionary *)product item:(ALineItem *)item tag:(NSInteger)tag ProductCellDelegate:(id <ProductCellDelegate>)productCellDelegate {
    BOOL isDiscount = [item.category isEqualToString:@"discount"];
    UIFont *discountFont = [UIFont italicSystemFontOfSize:14];
    self.InvtID.text = isDiscount ? @"Discount" : [product objectForKey:@"invtid"];
    [self setDescription:item.desc withSubtext:item.desc2];
    self.min.text = [[product objectForKey:@"min"] stringValue];
    if (!isDiscount) {
        self.quantity.text = item.quantity;
        self.quantity.hidden = NO;
        self.qtyLbl.hidden = YES;
    }
    else {
        NSString *qty = item.quantity;
        self.qtyLbl.text = qty;
        self.quantity.hidden = YES;
        self.qtyLbl.font = discountFont;
        self.qtyLbl.hidden = NO;
    }
    self.regPrice.text = isDiscount ? @"" : [NumberUtil formatDollarAmount:[product objectForKey:kProductRegPrc]];
    self.showPrice.text = isDiscount ? [NumberUtil formatDollarAmount:item.price] : [NumberUtil formatDollarAmount:[product objectForKey:kProductShowPrice]];
    if (isDiscount)self.showPrice.font = discountFont;
    self.delegate = productCellDelegate;
    self.tag = tag;
}

- (void)setDescription:(NSString *)description1 withSubtext:(NSString *)description2 {
    if (description2 == nil || [description2 isKindOfClass:[NSNull class]]) {
        self.descr.hidden = FALSE;
        self.descr1.hidden = TRUE;
        self.descr2.hidden = TRUE;
        self.descr.text = description1;
    } else {
        self.descr.hidden = TRUE;
        self.descr1.hidden = FALSE;
        self.descr2.hidden = FALSE;
        self.descr1.text = description1;
        self.descr2.text = description2;
    }
}

- (IBAction)quantityChanged:(id)sender {
    if (self.delegate) {
        [self.delegate QtyChange:[self.quantity.text doubleValue] forIndex:self.tag];
    }
}
@end