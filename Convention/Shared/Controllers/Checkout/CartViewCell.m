//
// Created by septerr on 9/2/13.
// Copyright (c) 2013 Convention Innovations. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "CartViewCell.h"
#import "Configurations.h"
#import "EditableEntity+Extensions.h"
#import "LineItem.h"


@implementation CartViewCell {
}
@synthesize InvtID;

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    if ([Configurations instance].isLineItemShipDatesType) {
        return NO;
    } else {
        UITableView *tableView = (UITableView *) self.superview.superview;
        [tableView indexPathForCell:self];
        return YES;
    }
}

- (void)updateErrorsView:(LineItem *)lineItem {
    if (lineItem && [lineItem hasErrorsOrWarnings]) {
        self.errorMessageView.attributedText = [lineItem buildMessageSummary];
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