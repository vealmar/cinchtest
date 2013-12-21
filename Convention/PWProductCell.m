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

- (void)initializeWith:(NSDictionary *)customer multiStore:(BOOL)multiStore product:(NSDictionary *)product item:(NSDictionary *)item checkmarked:(BOOL)checkmarked tag:(NSInteger)tag productCellDelegate:(id <ProductCellDelegate>)productCellDelegate {
    self.InvtID.text = [product objectForKey:@"invtid"];
    self.descr.text = [product objectForKey:@"descr"];
    if ([product objectForKey:kProductShipDate1] != nil && ![[product objectForKey:kProductShipDate1] isKindOfClass:[NSNull class]]) {
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
        NSDate *date = [df dateFromString:[product objectForKey:kProductShipDate1]];
        [df setDateFormat:@"yyyy-MM-dd"];
        self.shipDate1.text = [df stringFromDate:date];
    } else {
        self.shipDate1.text = @"";
    }
    if ([product objectForKey:kProductShipDate2] != nil && ![[product objectForKey:kProductShipDate2] isKindOfClass:[NSNull class]]) {
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
        NSDate *date = [df dateFromString:[product objectForKey:kProductShipDate2]];
        [df setDateFormat:@"yyyy-MM-dd"];
        self.shipDate2.text = [df stringFromDate:date];
    } else {
        self.shipDate2.text = @"";
    }

    self.numShipDates.text = ([[item objectForKey:kLineItemShipDates] isKindOfClass:[NSArray class]]
            ? [NSString stringWithFormat:@"%d", ((NSArray *) [item objectForKey:kLineItemShipDates]).count] : @"0");
    if (!multiStore && item != nil && [item objectForKey:kEditableQty] != nil) {
        self.quantity.text = [item objectForKey:kEditableQty];
    }
    else
        self.quantity.text = @"0";

    if ([product objectForKey:@"caseqty"] != nil && ![[product objectForKey:@"caseqty"] isKindOfClass:[NSNull class]])
        self.CaseQty.text = [product objectForKey:@"caseqty"];
    else
        self.CaseQty.text = @"";
    if ([[customer objectForKey:kStores] isKindOfClass:[NSArray class]] && [((NSArray *) [customer objectForKey:kStores]) count] > 0) {
        self.qtyBtn.hidden = NO;
        self.qtyLbl.hidden = YES;
        self.quantity.hidden = YES;
    }
//    if (item != nil && [item objectForKey:kEditableVoucher] != nil) {
//        self.voucherLbl.text = [NumberUtil formatDollarAmount:[item objectForKey:kEditableVoucher]];
//    } else
    if ([product objectForKey:kProductVoucher] != nil) {
        self.voucherLbl.text = [NumberUtil formatDollarAmount:[product objectForKey:kProductVoucher]];
    } else {
        self.voucherLbl.text = @"0.00";
    }

    if (item != nil && [item objectForKey:kEditablePrice] != nil) {
        self.priceLbl.text = [NumberUtil formatDollarAmount:[item objectForKey:kEditablePrice]];
    } else if ([product objectForKey:kProductShowPrice] != nil) {
        self.priceLbl.text = [NumberUtil formatDollarAmount:[product objectForKey:kProductShowPrice]];
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
    originalCellValue = [NSString stringWithString:textField.text];
    UITableView *tableView = (UITableView *) self.superview.superview;
    NSIndexPath *indexPath = [tableView indexPathForCell:self];
    [self.delegate setSelectedRow:(NSUInteger) [indexPath row]];
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
