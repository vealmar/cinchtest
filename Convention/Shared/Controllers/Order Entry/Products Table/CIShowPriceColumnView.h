//
// Created by David Jafari on 12/21/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CITableViewColumnView.h"

@class LineItem;


@interface CIShowPriceColumnView : CITableViewColumnView <UITextFieldDelegate>

@property UITextField *editablePriceTextField;

- (void)render:(id)rowData lineItem:(LineItem *)lineItem;

@end