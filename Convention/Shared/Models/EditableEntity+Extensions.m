//
// Created by David Jafari on 7/30/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import "EditableEntity+Extensions.h"
#import "UIColor+Boost.h"
#import "NilUtil.h"


@implementation EditableEntity (Extensions)

- (BOOL)hasErrorsOrWarnings {
    if (self.errors && self.errors.count > 0) return YES;
    if (self.warnings && self.warnings.count > 0) return YES;
    return NO;
}

- (NSAttributedString *)buildMessageSummary {
    return [EditableEntity buildMessageSummaryWithErrors:[self.errors valueForKey:@"message"]
                                            withWarnings:[self.warnings valueForKey:@"message"]];
}

+ (NSAttributedString *)buildMessageSummaryWithErrors:(NSArray *)errors withWarnings:(NSArray *)warnings {
    NSMutableAttributedString *mutableAttributedString = [NSMutableAttributedString new];
    errors = [NilUtil objectOrEmptyArray:errors];
    warnings = [NilUtil objectOrEmptyArray:warnings];

    for (NSString *warning in warnings) {
        [mutableAttributedString appendAttributedString:[[NSAttributedString alloc] initWithString:warning attributes:@{ NSForegroundColorAttributeName: [UIColor colorWithHexString:@"#b98201"] }]];
        [mutableAttributedString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
    }
    for (NSString *error in errors) {
        [mutableAttributedString appendAttributedString:[[NSAttributedString alloc] initWithString:error attributes:@{ NSForegroundColorAttributeName: [UIColor redColor] }]];
        [mutableAttributedString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
    }

    return mutableAttributedString;
}

@end