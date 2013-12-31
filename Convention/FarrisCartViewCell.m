//
// Created by septerr on 9/2/13.
// Copyright (c) 2013 Convention Innovations. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "FarrisCartViewCell.h"
#import "ProductCellDelegate.h"
#import "NumberUtil.h"
#import "NilUtil.h"
#import "Cart.h"
#import "Product.h"


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

- (void)initializeForDiscountWithProduct:(Product *)product quantity:(NSString *)itemQuantity price:(NSNumber *)price tag:(NSInteger)tag ProductCellDelegate:(id <ProductCellDelegate>)productCellDelegate {
    UIFont *discountFont = [UIFont italicSystemFontOfSize:14];
    self.InvtID.text = @"Discount";
    [self setDescription:product.descr withSubtext:product.descr2];
    self.min.text = [NilUtil objectOrDefaultString:product.min defaultObject:@""];
    NSString *qty = itemQuantity;
    self.qtyLbl.text = qty;
    self.quantity.hidden = YES;
    self.qtyLbl.font = discountFont;
    self.qtyLbl.hidden = NO;
    self.regPrice.text = @"";
    self.showPrice.text = [NumberUtil formatDollarAmount:price];
    self.showPrice.font = discountFont;
    self.delegate = productCellDelegate;
    self.tag = tag;
    self.min.hidden = YES; //Bill Hicks demo is using the Farris Header and we have decided to hide the Min column for now since they do not use it.
    [self updateErrorsView:[[NSSet alloc] init]];
}

- (void)initializeWith:(Product *)product cart:(Cart *)cart tag:(NSInteger)tag ProductCellDelegate:(id <ProductCellDelegate>)productCellDelegate {
    self.InvtID.text = product.invtid;
    [self setDescription:product.descr withSubtext:product.descr2];
    self.min.text = [NilUtil objectOrDefaultString:product.min defaultObject:@""];
    self.quantity.text = cart.editableQty;
    self.quantity.hidden = NO;
    self.qtyLbl.hidden = YES;
    self.regPrice.text = [NumberUtil formatCentsAsCurrency:product.regprc];
    self.showPrice.text = [NumberUtil formatCentsAsCurrency:product.showprc];
    self.delegate = productCellDelegate;
    self.tag = tag;
    self.min.hidden = YES; //Bill Hicks demo is using the Farris Header and we have decided to hide the Min column for now since they do not use it.
    [self updateErrorsView:cart.errors];
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
        [self.delegate QtyChange:[self.quantity.text intValue] forIndex:self.tag];
    }
}
@end