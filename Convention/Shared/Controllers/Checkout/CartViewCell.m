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
#import "Cart+Extensions.h"
#import "UIColor+Boost.h"
#import "EditableEntity+Extensions.h"


@implementation CartViewCell {
}
@synthesize InvtID;

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    if ([ShowConfigurations instance].isLineItemShipDatesType) {
        return NO;
    } else {
        UITableView *tableView = (UITableView *) self.superview.superview;
        NSIndexPath *indexPath = [tableView indexPathForCell:self];
        //[self.delegate setSelectedRow:indexPath];
        return YES;
    }
}

- (void)updateErrorsView:(Cart *)cart {
    if (cart && [cart hasErrorsOrWarnings]) {
        self.errorMessageView.attributedText = [cart buildMessageSummary];
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