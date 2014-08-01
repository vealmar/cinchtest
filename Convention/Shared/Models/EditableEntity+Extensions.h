//
// Created by David Jafari on 7/30/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EditableEntity.h"

@interface EditableEntity (Extensions)

+ (NSAttributedString *)buildMessageSummaryWithErrors:(NSArray *)errors withWarnings:(NSArray *)warnings;
- (NSAttributedString *)buildMessageSummary;
- (BOOL)hasErrorsOrWarnings;

@end