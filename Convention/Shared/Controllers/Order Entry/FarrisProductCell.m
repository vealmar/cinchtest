//
//  FarrisProductCell.m
//  Convention
//
//  Created by Kerry Sanders on 1/20/13.
//  Copyright (c) 2013 MotionMobs. All rights reserved.
//

#import "FarrisProductCell.h"
#import "StringManipulation.h"
#import "NumberUtil.h"
#import "Cart.h"
#import "AProduct.h"
#import "ShowConfigurations.h"
#import "Cart+Extensions.h"

@interface FarrisProductCell () {
    NSString *originalCellValue;
    Cart *cart;
}
@end

@implementation FarrisProductCell


- (void)initializeWithAProduct:(AProduct *)product cart:(Cart *)cartInitial tag:(NSInteger)tag ProductCellDelegate:(id <ProductCellDelegate>)productCellDelegate {
    cart = cartInitial;
    if (product) {
        self.InvtID.text = product.invtid;
        [self setDescription:product.descr withSubtext:product.descr2];
        self.min.text = product.min != nil ? [product.min stringValue] : @"";
        self.regPrice.text = [NumberUtil formatCentsAsCurrency:product.regprc];
        self.showPrice.text = [NumberUtil formatCentsAsCurrency:product.showprc];
        if ([product.showprc isEqual:product.regprc]) {
            self.showPrice.text = @"";
        }
    } else {
        self.InvtID.text = @"Product Not Found";
        [self setDescription:@"" withSubtext:@""];
        self.min.text = @"";
        self.regPrice.text = @"";
        self.showPrice.text = @"";
        self.editableShowPrice.text = @"";
        self.numOfShipDates.text = @"";
    }
    if (cart != nil) {
        self.editableShowPrice.text = [NumberUtil formatCentsAsDollarsWithoutSymbol:cart.editablePrice];
    } else {
        if (product)
            self.editableShowPrice.text = [NumberUtil formatCentsAsDollarsWithoutSymbol:product.showprc];
        else
            self.editableShowPrice.text = @"";

    }
    if (cart != nil && cart.editableQty != nil) {
        self.quantity.text = [NSString stringWithFormat:@"%i", cart.totalQuantity];
        if (product)
            self.numOfShipDates.text = cart.shipdates && cart.shipdates.count > 0 ? [NSString stringWithFormat:@"%d", cart.shipdates.count] : @"";

    } else {
        self.quantity.text = @"0";
        self.numOfShipDates.text = @"";
    }
    self.delegate = productCellDelegate;
    self.tag = tag;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    if (![self.InvtID.text isEqualToString:product.invtid]) self.accessoryType = UITableViewCellAccessoryNone;
    self.min.hidden = YES; //Bill Hicks demo is using the Farris Header and we have decided to hide the Min column for now since they do not use it.
    if (product.editable && product.editable.intValue == 1) {
        self.showPrice.hidden = YES;
        self.editableShowPrice.hidden = NO;
    } else {
        self.showPrice.hidden = NO;
        self.editableShowPrice.hidden = YES;
    }
    [self updateErrorsView:cart];
}

- (IBAction)quantityChanged:(id)sender {
    [cart setQuantity:[self.quantity.text intValue]];
}

- (IBAction)showPriceChanged:(id)sender {
    if (self.delegate) {
        [self.delegate ShowPriceChange:[self.editableShowPrice.text doubleValue] forIndex:self.tag];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    UITableView *tableView = (UITableView *) self.superview.superview;
    NSIndexPath *indexPath = [tableView indexPathForCell:self];
    [self.delegate setSelectedRow:indexPath];
    [self.delegate QtyTouchForIndex:indexPath.row];
    return ![ShowConfigurations instance].isLineItemShipDatesType;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    originalCellValue = [NSString stringWithString:textField.text];
    return YES;
}


- (void)textFieldDidEndEditing:(UITextField *)textField {
    if ([textField.text isEmpty]) {
        textField.text = originalCellValue;
    }
    if ([textField isFirstResponder]) [textField resignFirstResponder];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSInteger numberOfMatches = 0;
    if (textField == self.quantity && string.length != 0) {
        NSError *error;
        NSRegularExpression *numbersOnly = [NSRegularExpression regularExpressionWithPattern:@"[0-9]+" options:NSRegularExpressionCaseInsensitive error:&error];
        numberOfMatches = [numbersOnly numberOfMatchesInString:string options:0 range:NSMakeRange(0, string.length)];
        return numberOfMatches != 1 ? NO : YES;
    } else
        return YES;
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
@end
