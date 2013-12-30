//
// Created by septerr on 8/19/13.
// Copyright (c) 2013 Convention Innovations. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "ProductCell.h"
#import "Error.h"


@implementation ProductCell {

}
- (void)updateErrorsView:(NSSet *)errors {
    if (errors.count > 0) {
        NSMutableString *bulletList = [NSMutableString stringWithCapacity:errors.count * 30];
        for (Error *error in errors) {
            [bulletList appendFormat:@"\u2022 %@\n", error.message];
        }
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