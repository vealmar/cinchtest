//
// Created by David Jafari on 5/26/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface CIShipDateTableViewCell : UITableViewCell <UITextFieldDelegate>

@property NSDate *shipDate;

- (id)initOn:(NSDate *)shipDate for:(NSArray *)selectedCartsParam usingQuantityField:(BOOL)useQuantity;
- (int)quantity;
- (void)setQuantity:(int)quantity;

@property (nonatomic, copy) void (^resignedFirstResponderBlock)(CIShipDateTableViewCell *cell);
@property UITextField *quantityField;

@end