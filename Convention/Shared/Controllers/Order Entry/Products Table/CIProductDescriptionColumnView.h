//
// Created by David Jafari on 2/7/15.
// Copyright (c) 2015 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CITableViewStandardColumnView.h"

@class LineItem;

@interface CIProductDescriptionColumnView : CITableViewStandardColumnView <UITextFieldDelegate>

@property UITextField *editableDescriptionTextField;

- (void)render:(id)rowData lineItem:(LineItem *)lineItem;

@end