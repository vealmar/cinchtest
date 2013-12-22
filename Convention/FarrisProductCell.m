//
//  FarrisProductCell.m
//  Convention
//
//  Created by Kerry Sanders on 1/20/13.
//  Copyright (c) 2013 MotionMobs. All rights reserved.
//

#import "FarrisProductCell.h"
#import "StringManipulation.h"
#import "config.h"
#import "NumberUtil.h"
#import "NilUtil.h"
#import "Cart.h"

@interface FarrisProductCell () {
    NSString *originalCellValue;
}
@end

@implementation FarrisProductCell


- (void)initializeWith:(NSDictionary *)product cart:(Cart *)cart tag:(NSInteger)tag ProductCellDelegate:(id <ProductCellDelegate>)productCellDelegate {
    self.InvtID.text = [product objectForKey:@"invtid"];
    [self setDescription:[product objectForKey:kProductDescr] withSubtext:[product objectForKey:kProductDescr2]];
    NSObject *minObj = [NilUtil nilOrObject:[product objectForKey:@"min"]];
    self.min.text = minObj != nil ? [[product objectForKey:@"min"] stringValue] : @"";
    if (cart != nil && cart.editableQty != nil) {
        self.quantity.text = cart.editableQty;
    } else {
        self.quantity.text = @"0";
    }
    self.regPrice.text = [NumberUtil formatDollarAmount:[NSNumber numberWithDouble:[[product objectForKey:kProductRegPrc] doubleValue]]];
    self.showPrice.text = [NumberUtil formatDollarAmount:[NSNumber numberWithDouble:[[product objectForKey:kProductShowPrice] doubleValue]]];
    self.delegate = productCellDelegate;
    self.tag = tag;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.accessoryType = UITableViewCellAccessoryNone;
    self.min.hidden = YES; //Bill Hicks demo is using the Farris Header and we have decided to hide the Min column for now since they do not use it.
}

- (IBAction)quantityChanged:(id)sender {
    if (self.delegate) {
        [self.delegate QtyChange:[self.quantity.text intValue] forIndex:self.tag];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    originalCellValue = [NSString stringWithString:textField.text];
    UITableView *tableView = (UITableView *) self.superview.superview;
    NSIndexPath *indexPath = [tableView indexPathForCell:self];
    [self.delegate setSelectedRow:indexPath.row];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if ([textField.text isEmpty]) {
        textField.text = originalCellValue;
    }
    if ([textField isFirstResponder])
        [textField resignFirstResponder];
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
@end
