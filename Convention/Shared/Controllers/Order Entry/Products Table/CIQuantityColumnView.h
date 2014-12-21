//
// Created by David Jafari on 12/21/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CITableViewColumnView.h"

@class Cart;

@interface CIQuantityColumnView : CITableViewColumnView <UITextFieldDelegate>

@property UITextField *quantityTextField;

- (void)render:(id)rowData cart:(Cart *)cart;

- (void)updateQuantity:(Cart *)cart;

@end