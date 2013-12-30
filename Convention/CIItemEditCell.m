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
#import "config.h"
#import "StringManipulation.h"
#import "Error.h"

@implementation CIItemEditCell
@synthesize desc;
@synthesize desc1;
@synthesize desc2;
@synthesize voucher;
@synthesize qty;
@synthesize price;
@synthesize btnShipdates;
@synthesize total;
@synthesize delegate;
@synthesize qtyBtn;
@synthesize priceLbl;

- (void)updateErrorsView:(NSArray *)errors {
    if (errors && errors.count > 0) {
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

- (void)UpdateTotal {
    __autoreleasing NSError *err = nil;
    NSMutableDictionary *dict = [self.qty.text objectFromJSONStringWithParseOptions:JKParseOptionNone error:&err];

    double q = 0;
    if (err) {
        q = [self.qty.text doubleValue];
    } else {
        for (NSString *key in dict.allKeys) {
            q += [[dict objectForKey:key] doubleValue];
        }
    }

    double p = [self.priceLbl.text doubleValue];

    self.total.text = [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithDouble:(q * p)] numberStyle:NSNumberFormatterCurrencyStyle];
}

- (IBAction)voucherEdit:(id)sender {
    if (self.delegate) {
        [self.delegate setVoucher:self.voucher.text atIndex:self.tag];
        [self.delegate UpdateTotal];
    }
}

- (IBAction)qtyEdit:(id)sender {
    [self UpdateTotal];
    if (self.delegate) {
        [self.delegate setQuantity:self.qty.text atIndex:self.tag];
        [self.delegate UpdateTotal];
    }
}

- (IBAction)priceEdit:(id)sender {
    self.priceLbl.text = self.price.text;
    [self UpdateTotal];
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

- (IBAction)shipdates:(id)sender {
    if (self.delegate) {
        [self.delegate ShipDatesTouchForIndex:self.tag];
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

- (void)setDescription:(NSString *)description1 withSubtext:(NSString *)description2 {
    if (description2 == nil) {
        self.desc.hidden = FALSE;
        self.desc1.hidden = TRUE;
        self.desc2.hidden = TRUE;
        self.desc.text = description1;
    } else {
        self.desc.hidden = TRUE;
        self.desc1.hidden = FALSE;
        self.desc2.hidden = FALSE;
        self.desc1.text = description1;
        self.desc2.text = description2;
    }

}

- (void)updateCellAtIndexPath:(NSIndexPath *)indexPath withLineItem:(ALineItem *)data quantities:(NSArray *)itemsQty prices:(NSArray *)itemsPrice vouchers:(NSArray *)itemsVouchers shipDates:(NSArray *)itemsShipDates {
    BOOL isDiscount = [data.category isEqualToString:@"discount"];
    if (data.product) {
        NSString *invtid = isDiscount ? @"Discount" : [data.product objectForKey:@"invtid"];
        self.invtid.text = invtid;
    }
    [self setDescription:data.desc withSubtext:data.desc2];
    if ([ShowConfigurations instance].vouchers) {
        if ([itemsVouchers objectAtIndex:indexPath.row]) {
            self.voucher.text = [itemsVouchers objectAtIndex:indexPath.row];
        }
        else
            self.voucher.text = @"0";
    } else {
        self.voucher.hidden = YES;
    }

    BOOL isJSON = NO;
    double q = 0;
    if ([itemsQty objectAtIndex:indexPath.row]) {
        self.qty.text = [itemsQty objectAtIndex:indexPath.row];
        self.qtyLbl.text = [itemsQty objectAtIndex:indexPath.row];
        q = [self.qty.text doubleValue];
    }
    else
        self.qty.text = @"0";

    __autoreleasing NSError *err = nil;
    NSMutableDictionary *dict = [self.qty.text objectFromJSONStringWithParseOptions:JKParseOptionNone error:&err];
    if (!err && dict && ![dict isKindOfClass:[NSNull class]] && dict.allKeys.count > 0) {
        isJSON = YES;
    }
    if (isJSON) {
        [self.qtyBtn setHidden:NO];
        for (NSString *key in dict.allKeys) {
            q += [[dict objectForKey:key] doubleValue];
        }
        if (ceil(q) == q) {
            [self.qtyBtn setTitle:[NSString stringWithFormat:@"%d", (int) q] forState:UIControlStateNormal];
        } else
            [self.qtyBtn setTitle:[NSString stringWithFormat:@"%.1f", q] forState:UIControlStateNormal];

    } else {
        [self.qtyBtn setHidden:YES];
    }

    if (isDiscount) {
        self.qty.hidden = YES;
        self.qtyLbl.hidden = NO;
    } else {
        self.qty.hidden = NO;
        self.qtyLbl.hidden = YES;
    }

    int nd = 1;
    if ([[ShowConfigurations instance] shipDates]) {
        int idx = [[data.product objectForKey:kProductIdx] intValue];
        NSString *invtId = [data.product objectForKey:kProductInvtid];
        BOOL isVoucher = idx == 0 && ([invtId isEmpty] || [invtId isEqualToString:@"0"]);
        if (isVoucher) {
            self.btnShipdates.enabled = NO;
            [self.btnShipdates setTitle:@"SD:0" forState:UIControlStateDisabled];
        } else {
            self.btnShipdates.enabled = YES;//since cells are reused, it may have been set to NO.
            int lblsd = 0;
            if (((NSArray *) [itemsShipDates objectAtIndex:indexPath.row]).count > 0) {
                nd = ((NSArray *) [itemsShipDates objectAtIndex:indexPath.row]).count;
                lblsd = nd;
            }
            [self.btnShipdates setTitle:[NSString stringWithFormat:@"SD:%d", lblsd] forState:UIControlStateNormal];
        }
    } else {
        self.btnShipdates.hidden = YES;
    }

    if ([itemsPrice objectAtIndex:indexPath.row] && ![[itemsPrice objectAtIndex:indexPath.row] isKindOfClass:[NSNull class]]) {
        NSNumberFormatter *nf = [[NSNumberFormatter alloc] init];
        nf.formatterBehavior = NSNumberFormatterBehavior10_4;
        nf.maximumFractionDigits = 2;
        nf.minimumFractionDigits = 2;
        nf.minimumIntegerDigits = 1;

        double price = [[itemsPrice objectAtIndex:indexPath.row] doubleValue];

        self.price.text = [nf stringFromNumber:[NSNumber numberWithDouble:price]];
        self.priceLbl.text = self.price.text;
        [self.price setHidden:YES];
        self.total.text = [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithDouble:(price * q * nd)] numberStyle:NSNumberFormatterCurrencyStyle];
    }
    else {
        self.price.text = @"0.00";
        self.priceLbl.text = self.price.text;
        [self.price setHidden:YES];
        self.total.text = @"$0.00";
    }
    self.tag = indexPath.row;
    [self updateErrorsView:data.errors];
}

@end
