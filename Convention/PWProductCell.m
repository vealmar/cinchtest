//
//  PWProductCell.m
//  Convention
//
//  Created by Matthew Clark on 11/2/11.
//  Copyright (c) 2011 MotionMobs. All rights reserved.
//

#import "PWProductCell.h"
#import "StringManipulation.h"
#import "config.h"
#import "NumberUtil.h"
#import "Cart.h"
#import "Product.h"

@interface PWProductCell () {
    NSString *originalCellValue;
}

@end

@implementation PWProductCell
@synthesize quantity;
@synthesize qtyLbl;
@synthesize voucherLbl;
@synthesize priceLbl;
@synthesize InvtID;
@synthesize descr;
@synthesize shipDate1, shipDate2;
@synthesize CaseQty;
@synthesize qtyBtn;
@synthesize delegate;
@synthesize numShipDates;

- (void)initializeWith:(NSDictionary *)customer multiStore:(BOOL)multiStore product:(Product *)product cart:(Cart *)cart checkmarked:(BOOL)checkmarked tag:(NSInteger)tag productCellDelegate:(id <ProductCellDelegate>)productCellDelegate {
    self.InvtID.text = product.invtid;
    self.descr.text = product.descr;
    if (product.shipdate1) {
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
        [df setDateFormat:@"yyyy-MM-dd"];
        self.shipDate1.text = [df stringFromDate:product.shipdate1];
    } else {
        self.shipDate1.text = @"";
    }
    if (product.shipdate2) {
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
        [df setDateFormat:@"yyyy-MM-dd"];
        self.shipDate2.text = [df stringFromDate:product.shipdate2];
    } else {
        self.shipDate2.text = @"";
    }

    self.numShipDates.text = [NSString stringWithFormat:@"%d", cart.shipdates ? cart.shipdates.count : 0];
    self.quantity.text = !multiStore && cart.editableQty != nil? cart.editableQty : @"0";

    if (product.caseqty)
        self.CaseQty.text = product.caseqty;
    else
        self.CaseQty.text = @"";
    if ([[customer objectForKey:kStores] isKindOfClass:[NSArray class]] && [((NSArray *) [customer objectForKey:kStores]) count] > 0) {
        self.qtyBtn.hidden = NO;
        self.qtyLbl.hidden = YES;
        self.quantity.hidden = YES;
    }
    if (product.voucher != nil) {
        self.voucherLbl.text = [NumberUtil formatCentsAsCurrency:product.voucher];
    } else {
        self.voucherLbl.text = @"0.00";
    }

    if (cart.editablePrice != nil) {
        self.priceLbl.text = [NumberUtil formatCentsAsCurrency:cart.editablePrice];
    } else if (product.showprc) {
        self.priceLbl.text = [NumberUtil formatCentsAsCurrency:product.showprc];
    } else {
        self.priceLbl.text = @"0.00";
    }
    self.accessoryType = checkmarked ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    self.delegate = productCellDelegate;
    self.tag = tag;
}

- (IBAction)qtyTouch:(id)sender {
    if (self.delegate) {
        [self.delegate QtyTouchForIndex:self.tag];
    }
}

- (IBAction)qtyChanged:(id)sender {
    self.qtyLbl.text = self.quantity.text;
    if (self.delegate) {
        [self.delegate QtyChange:[self.quantity.text intValue] forIndex:self.tag];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    // Resigning from being first responder when user taps the enter key.
    // Since a text field is not the first responder anymore, it causes the keyboard to hide.
    [textField resignFirstResponder];
    return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    UITableView *tableView = (UITableView *) self.superview.superview;
    NSIndexPath *indexPath = [tableView indexPathForCell:self];
    [self.delegate setSelectedRow:indexPath];
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {//todo does this work for voucher field?
    originalCellValue = [NSString stringWithString:textField.text];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if ([textField.text isEmpty]) {
        textField.text = originalCellValue;
    }
    if ([textField isFirstResponder])
        [textField resignFirstResponder];
}

@end
