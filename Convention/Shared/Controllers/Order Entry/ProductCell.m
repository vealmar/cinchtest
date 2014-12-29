//
// Created by septerr on 8/19/13.
// Copyright (c) 2013 Convention Innovations. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "ProductCell.h"
#import "EditableEntity+Extensions.h"
#import "LineItem.h"


@implementation ProductCell {

}
- (void)updateErrorsView:(LineItem *)cart {
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