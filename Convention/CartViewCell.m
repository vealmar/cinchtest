//
// Created by septerr on 9/2/13.
// Copyright (c) 2013 Convention Innovations. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "CartViewCell.h"
#import "ProductCellDelegate.h"


@implementation CartViewCell {
}
@synthesize InvtID;

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    UITableView *tableView = (UITableView *) self.superview.superview;
    NSIndexPath *indexPath = [tableView indexPathForCell:self];
    [self.delegate setSelectedRow:(NSUInteger) [indexPath row]];
    return YES;
}

@end