//
// Created by septerr on 9/2/13.
// Copyright (c) 2013 Convention Innovations. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "CartViewCell.h"
#import "ProductCellDelegate.h"
#import "Error.h"
#import "ShowConfigurations.h"


@implementation CartViewCell {
}
@synthesize InvtID;

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    if ([ShowConfigurations instance].isLineItemShipDatesType) {
        return NO;
    } else {
        UITableView *tableView = (UITableView *) self.superview.superview;
        NSIndexPath *indexPath = [tableView indexPathForCell:self];
        [self.delegate setSelectedRow:indexPath];
        return YES;
    }
}

- (void)updateErrorsView:(NSSet *)errors {
    if (errors.count > 0) {
        NSMutableString *bulletList = [NSMutableString stringWithCapacity:errors.count * 30];
        for (Error *error in errors) {
            [bulletList appendFormat:@"%@\n", error.message];
        }
        //#todo convert this to color string and remove color from storyboard
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

@end