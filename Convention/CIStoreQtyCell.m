//
//  CIStoreQtyCell.m
//  Convention
//
//  Created by Matthew Clark on 8/16/12.
//  Copyright (c) 2012 MotionMobs. All rights reserved.
//

#import "CIStoreQtyCell.h"
#import "StringManipulation.h"

@implementation CIStoreQtyCell {
    NSString *originalText;
}
@synthesize Key;
@synthesize Qty;
@synthesize lblQty;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

//-(BOOL)textFieldShouldReturn:(UITextField *)textField {
//    [textField resignFirstResponder];
////    if (self.delegate)
////        [self.delegate selectNextRow:self.tag];
//    return YES;
//}

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    originalText = [NSString stringWithString:textField.text];
    return YES;
}

-(void)textFieldDidEndEditing:(UITextField *)textField {
    [textField resignFirstResponder];
    // Revert the text to original value
    // if nothing is in the field.
    if ([textField.text isEmpty])
        textField.text = [NSString stringWithString:originalText];
    
//    UITableView *tableView = (UITableView *)self.superview;
//    int nextRow = self.tag + 1;
//    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:nextRow inSection:0];
//    CIStoreQtyCell *nextCell = (CIStoreQtyCell *)[tableView cellForRowAtIndexPath:indexPath];
//    if (nextCell)
//        [nextCell.Qty becomeFirstResponder];
//    if (cellPath.row + 1 > [tableView numberOfRowsInSection:0]) {
//        NSIndexPath *nextCellPath = [NSIndexPath indexPathForRow:cellPath.row + 1 inSection:cellPath.section];
//        CIStoreQtyCell *nextCell = (CIStoreQtyCell *)[tableView cellForRowAtIndexPath:nextCellPath];
//        [nextCell.Qty becomeFirstResponder];
//    }
}

- (IBAction)qtyChanged:(id)sender {
    if (self.delegate) {
        [self.delegate QtyChange:[self.Qty.text doubleValue] forIndex:self.tag];
    }
}
@end
