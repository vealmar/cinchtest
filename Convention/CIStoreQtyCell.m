//
//  CIStoreQtyCell.m
//  Convention
//
//  Created by Matthew Clark on 8/16/12.
//  Copyright (c) 2012 MotionMobs. All rights reserved.
//

#import "CIStoreQtyCell.h"

@implementation CIStoreQtyCell
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

//-(void)textFieldDidBeginEditing:(UITextField *)textField{
//    [self qtyChanged:nil];
//}
//
//-(void)textFieldDidEndEditing:(UITextField *)textField{
//    [self qtyChanged:nil];
//}

- (IBAction)qtyChanged:(id)sender {
    if (self.delegate) {
        [self.delegate QtyChange:[self.Qty.text doubleValue] forIndex:self.tag];
    }
}
@end
