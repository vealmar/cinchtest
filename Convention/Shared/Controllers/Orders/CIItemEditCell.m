//
//  CIItemEditCell.m
//  Convention
//
//  Created by Matthew Clark on 12/9/11.
//  Copyright (c) 2011 MotionMobs. All rights reserved.
//

#import "CIItemEditCell.h"
#import "JSONKit.h"
#import "ALineItem.h"
#import "ShowConfigurations.h"
#import "StringManipulation.h"
#import "Error.h"
#import "Product.h"
#import "Product+Extensions.h"

@interface CIItemEditCell ()
@property NSUInteger numOfShipDates;
@property ALineItem *lineItem;
@end

@implementation CIItemEditCell

- (void)updateErrorsView:(NSArray *)errors {
    if (errors && errors.count > 0) {
        //#todo convert this to color string and remove color from storyboard
        NSMutableString *bulletList = [NSMutableString stringWithCapacity:errors.count * 30];
        for (Error *error in errors) {
            [bulletList appendFormat:@"%@\n", error];
        }
        self.errorMessageView.text = bulletList;
        self.errorMessageView.hidden = NO;
        self.errorMessageHeightConstraint.constant = 59.0f;
        CGFloat contentHeight = self.errorMessageView.contentSize.height;
        if (contentHeight < 59.0f) {
            CGSize sizeThatShouldFitTheContent = [self.errorMessageView sizeThatFits:self.errorMessageView.frame.size];
            self.errorMessageHeightConstraint.constant = sizeThatShouldFitTheContent.height;
        }
    } else {
        self.errorMessageView.text = @"";
        self.errorMessageView.hidden = YES;
    }
}

- (void)updateTotal:(int)quantity {
    if (self.lineItem) {
        ShowConfigurations *config = [ShowConfigurations instance];
        double price = [self.lineItem.price doubleValue];
        double total = 0;
        if (config.shipDates && !config.isLineItemShipDatesType) {
            total = price * quantity * self.lineItem.shipDates.count;
        } else {
            total = price * quantity;
        }
        self.total.text = [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithDouble:(total)] numberStyle:NSNumberFormatterCurrencyStyle];
    }
}

- (IBAction)voucherEdit:(id)sender {
    if (self.delegate) {
        [self.delegate setVoucher:self.voucher.text atIndex:self.tag];
        [self.delegate UpdateTotal];
    }
}

- (IBAction)qtyEdit:(id)sender {
    [self updateTotal:self.qty.text.intValue];
    if (self.delegate) {
        [self.delegate setQuantity:self.qty.text atIndex:self.tag];
        [self.delegate UpdateTotal];
    }
}

- (IBAction)priceEdit:(id)sender {
    self.priceLbl.text = self.price.text;
    [self updateTotal:self.lineItem.totalQuantity];
    if (self.delegate) {
        [self.delegate setPrice:self.price.text atIndex:self.tag];
        [self.delegate UpdateTotal];
    }
}

- (IBAction)qtyTouch:(id)sender {
    if (self.delegate) {
        [self.delegate QtyTouchForIndex:self.tag];
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if (self.delegate) {
        [self.delegate setActiveField:textField];
        [self.delegate setSelectedRow:self.tag];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)setDescription:(NSString *)description1 withSubtext:(NSString *)description2 {
    NSString *d1 = description1 && ![description1 isKindOfClass:[NSNull class]] ? [description1 stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] : @"";
    NSString *d2 = description2 && ![description2 isKindOfClass:[NSNull class]] ? [description2 stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] : nil;
    if (d2 == nil || [d2 length] == 0) {
        self.desc.hidden = FALSE;
        self.desc1.hidden = TRUE;
        self.desc2.hidden = TRUE;
        self.desc.text = d1;
    } else {
        self.desc.hidden = TRUE;
        self.desc1.hidden = FALSE;
        self.desc2.hidden = FALSE;
        self.desc1.text = d1;
        self.desc2.text = d2;
    }

}

- (void)showLineItem:(ALineItem *)data withTag:(NSInteger *)tag {
    ShowConfigurations *config = [ShowConfigurations instance];
    Product *product = [Product findProduct:data.productId];
    self.lineItem = data;

    // description
    if (data.isDiscount) {
        self.invtid.text = @"Discount";
    } else if (data.productId) {
        NSString *invtid = product ? product.invtid : @"Product Not Found";
        self.invtid.text = invtid;
    }
    [self setDescription:data.desc withSubtext:data.desc2];

    // vouchers
    if (config.vouchers) {
        self.voucher.text = data.voucherPrice ? [NSString stringWithFormat:@"%d", data.voucherPrice] : @"0";
    } else {
        self.voucher.hidden = YES;
    }

    // quantities
    self.qtyBtn.hidden = YES;
    self.qty.text = self.qtyLbl.text = [NSString stringWithFormat:@"%i", data.totalQuantity];
    if (data.isDiscount || config.isLineItemShipDatesType) {
        self.qty.hidden = YES;
        self.qtyLbl.hidden = NO;
    } else {
        self.qty.hidden = NO;
        self.qtyLbl.hidden = YES;
    }

    // ship dates
    if ([config isLineItemShipDatesType] && product) {
        self.shipDatesLabel.text = [NSString stringWithFormat:@"%i", data.shipDates.count];
        self.shipDatesLabel.hidden = NO;
    } else {
        self.shipDatesLabel.hidden = YES;
    }

    // price/total
    self.numOfShipDates = data.shipDates.count;
    if (data.price && ![data.price isKindOfClass:[NSNull class]]) {
        NSNumberFormatter *nf = [[NSNumberFormatter alloc] init];
        nf.formatterBehavior = NSNumberFormatterBehavior10_4;
        nf.maximumFractionDigits = 2;
        nf.minimumFractionDigits = 2;
        nf.minimumIntegerDigits = 1;
        double price = [data.price doubleValue];
        self.price.text = [nf stringFromNumber:[NSNumber numberWithDouble:price]];
        self.priceLbl.text = self.price.text;
        [self.price setHidden:YES];
        [self updateTotal:self.lineItem.totalQuantity];
    }
    else {
        self.price.text = @"0.00";
        self.priceLbl.text = self.price.text;
        [self.price setHidden:YES];
        self.total.text = @"$0.00";
    }
    self.tag = tag;
    [self updateErrorsView:data.errors];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSInteger numberOfMatches = 0;
    if (textField == self.qty && string.length != 0) {
        NSError *error;
        NSRegularExpression *numbersOnly = [NSRegularExpression regularExpressionWithPattern:@"[0-9]+" options:NSRegularExpressionCaseInsensitive error:&error];
        numberOfMatches = [numbersOnly numberOfMatchesInString:string options:0 range:NSMakeRange(0, string.length)];
        return numberOfMatches != 1 ? NO : YES;
    } else
        return YES;
}

@end
