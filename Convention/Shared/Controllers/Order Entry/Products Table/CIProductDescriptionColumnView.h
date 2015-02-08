//
// Created by David Jafari on 2/7/15.
// Copyright (c) 2015 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CITableViewColumnView.h"

@class LineItem;

@interface CIProductDescriptionColumnView : CITableViewColumnView <UITextFieldDelegate>

@property UITextField *editableDescriptionTextField;

- (void)render:(id)rowData lineItem:(LineItem *)lineItem;

@end