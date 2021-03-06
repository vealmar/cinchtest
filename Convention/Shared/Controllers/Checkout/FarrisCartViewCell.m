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
#import "Product.h"
#import "Product+Extensions.h"
#import "LineItem.h"
#import "LineItem+Extensions.h"
#import "Order.h"

@interface FarrisCartViewCell () {
    LineItem *lineItem;
}
@end

@implementation FarrisCartViewCell {

}
@synthesize descr;
@synthesize descr1;
@synthesize descr2;
@synthesize min;
@synthesize quantity;
@synthesize qtyLbl;
@synthesize price2;
@synthesize price1;

- (void)initializeWithDiscount:(LineItem *)discount tag:(NSInteger)tag ProductCellDelegate:(id <ProductCellDelegate>)productCellDelegate {
    [self applyViewStyles];

    UIFont *discountFont = [UIFont boldFontOfSize:14];
    self.InvtID.text = @"Discount";
    [self setDescription:discount.description1 withSubtext:discount.description2];
    Product *product = discount.productId ? [Product findProduct:discount.productId] : nil;
    self.min.text = product && product.min != nil ? [product.min stringValue] : @"";
    self.qtyLbl.text = discount.quantity;
    self.quantity.hidden = YES;
    self.qtyLbl.font = discountFont;
    self.qtyLbl.hidden = NO;
    self.price2.text = [NumberUtil formatDollarAmount:discount.price];
    self.price1.text = @"";
    self.price2.font = discountFont;
    self.delegate = productCellDelegate;
    self.tag = tag;
    self.min.hidden = YES; //Bill Hicks demo is using the Farris Header and we have decided to hide the Min column for now since they do not use it.
    self.backgroundColor = [UIColor whiteColor];//since we are using same cell for products and discounts, if a product cell is being reused, it might have a green/red background. We display discounts with white background always.
    self.numOfShipDates.text = @"";
    self.descr.font = [UIFont semiboldFontOfSize:14.0];
    self.descr1.font = [UIFont semiboldFontOfSize:14.0];
    self.descr2.font = [UIFont semiboldFontOfSize:14.0];

    [self updateErrorsView:nil];
}

- (void)initializeWithCart:(LineItem *)lineItemInitial tag:(NSInteger)tag ProductCellDelegate:(id <ProductCellDelegate>)productCellDelegate {
    [self applyViewStyles];

    lineItem = lineItemInitial;

    self.InvtID.text = lineItem.product.invtid;

    [self setDescription:(lineItemInitial.description1 ? lineItemInitial.description1 : lineItem.product.descr) withSubtext:(lineItemInitial.description2 ? lineItemInitial.description2 : lineItem.product.descr2)];
    NSNumber *minNumber = (NSNumber *) [NilUtil nilOrObject:lineItem.product.min];
    self.min.text = minNumber ? [minNumber stringValue] : @"";

    if (lineItem.order.discountPercentage.doubleValue != 0) {
        self.price1.numberOfLines = 2;
        self.price2.numberOfLines = 2;
        self.price1.attributedText = [self priceOverride:lineItem.price by:lineItem.order.discountPercentage];
        self.price2.attributedText = [self priceOverride:lineItem.subtotalNumber by:lineItem.order.discountPercentage];
    } else {
        self.price1.text = [NumberUtil formatDollarAmount:lineItem.price];
        self.price2.text = [NumberUtil formatDollarAmount:lineItem.subtotalNumber];
    }

    self.delegate = productCellDelegate;
    self.tag = tag;
    self.min.hidden = YES; //Bill Hicks demo is using the Farris Header and we have decided to hide the Min column for now since they do not use it.
    self.numOfShipDates.text = lineItem.shipDates && lineItem.shipDates.count > 0 ? [NSString stringWithFormat:@"%d", lineItem.shipDates.count] : @"";
    if (lineItem.product.editable && lineItem.product.editable.intValue == 1) {
        self.price1.text = [NumberUtil formatDollarAmount:lineItem.price];
    }
    self.qtyLbl.text = [NSString stringWithFormat:@"%i", lineItem.totalQuantity];
    self.quantity.hidden = YES;
    self.qtyLbl.hidden = NO;

    [self updateErrorsView:lineItem];
}

- (NSMutableAttributedString *)priceOverride:(NSNumber *)price by:(NSNumber *)percentage {
    NSNumber *overrideNumber = @(price.doubleValue - (percentage.doubleValue * price.doubleValue / 100));

    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] init];
    [string appendAttributedString:[[NSAttributedString alloc] initWithString:[NumberUtil formatDollarAmount:price] attributes:@{
                NSFontAttributeName: [UIFont regularFontOfSize:14],
                NSStrikethroughStyleAttributeName: @(NSUnderlineStyleSingle | NSUnderlinePatternSolid)
        }]];
    [string appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
    [string appendAttributedString:[[NSAttributedString alloc] initWithString:[NumberUtil formatDollarAmount:overrideNumber] attributes:@{
                NSFontAttributeName: [UIFont boldFontOfSize:14]
        }]];

    return string;
}

- (void)applyViewStyles {
    self.InvtID.adjustsFontSizeToFitWidth = YES;
    self.InvtID.minimumScaleFactor = 9.0f / self.InvtID.font.pointSize;

    self.descr.adjustsFontSizeToFitWidth = NO;
    self.descr.lineBreakMode = NSLineBreakByTruncatingTail;
    self.descr.autoresizingMask = UIViewAutoresizingNone;

    self.descr1.adjustsFontSizeToFitWidth = NO;
    self.descr1.lineBreakMode = NSLineBreakByTruncatingTail;
    self.descr1.autoresizingMask = UIViewAutoresizingNone;

    self.descr2.adjustsFontSizeToFitWidth = NO;
    self.descr2.lineBreakMode = NSLineBreakByTruncatingTail;
    self.descr2.autoresizingMask = UIViewAutoresizingNone;

    self.price1.numberOfLines = 1;
    self.price2.numberOfLines = 2;
}

- (void)setDescription:(NSString *)description1 withSubtext:(NSString *)description2 {
    NSString *d1 = description1 && ![description1 isKindOfClass:[NSNull class]] ? [description1 stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] : @"";
    NSString *d2 = description2 && ![description2 isKindOfClass:[NSNull class]] ? [description2 stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] : nil;

    if (d2 == nil || d2.length == 0) {
        self.descr.hidden = FALSE;
        self.descr1.hidden = TRUE;
        self.descr2.hidden = TRUE;
        self.descr.text = d1;
    } else {
        self.descr.hidden = TRUE;
        self.descr1.hidden = FALSE;
        self.descr2.hidden = FALSE;
        self.descr1.text = d1;
        self.descr2.text = d2;
    }
}

- (IBAction)quantityChanged:(id)sender {
    if (lineItem) {
        [lineItem setQuantity:self.quantity.text];
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSInteger numberOfMatches = 0;
    if (textField == self.quantity && string.length != 0) {
        NSError *error;
        NSRegularExpression *numbersOnly = [NSRegularExpression regularExpressionWithPattern:@"[0-9]+" options:NSRegularExpressionCaseInsensitive error:&error];
        numberOfMatches = [numbersOnly numberOfMatchesInString:string options:0 range:NSMakeRange(0, string.length)];
        return numberOfMatches == 1;
    } else
        return YES;
}

@end