//
//  FarrisProductCell.m
//  Convention
//
//  Created by Kerry Sanders on 1/20/13.
//  Copyright (c) 2013 MotionMobs. All rights reserved.
//

#import "FarrisProductCell.h"
#import "StringManipulation.h"

@interface FarrisProductCell() {
    NSString* originalCellValue;
}
@end

@implementation FarrisProductCell

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

- (IBAction)quantityChanged:(id)sender {
    if (self.delegate) {
        [self.delegate QtyChange:[self.quantity.text doubleValue] forIndex:self.tag];
    }
}

- (IBAction)quantyEditDidEnd:(id)sender {
    if (self.delegate) {
        [self.delegate QtyChange:[self.quantity.text doubleValue] forIndex:self.tag];
    }
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    originalCellValue = [NSString stringWithString:textField.text];
    UITableView * tableView = (UITableView *)self.superview;
    NSIndexPath *indexPath = [tableView indexPathForCell:self];
    [tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
    return YES;
}

-(void)textFieldDidEndEditing:(UITextField *)textField{
    if ([textField.text isEmpty]) {
        textField.text = originalCellValue;
    }
    if ([textField isFirstResponder])
        [textField resignFirstResponder];
}
@end
