//
// Created by David Jafari on 5/26/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface CIShipDateTableViewCell : UITableViewCell <UITextFieldDelegate>

@property NSDate *shipDate;

@property UITextField *quantityField;

- (void)prepareForDisplay:(NSDate *)shipDate selectedLineItems:(NSArray *)selectedLineItems;
- (int)quantity;
- (void)setQuantity:(int)quantity;

@end