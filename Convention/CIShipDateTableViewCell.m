//
// Created by David Jafari on 5/26/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import "CIShipDateTableViewCell.h"
#import "Cart+Extensions.h"
#import "DateUtil.h"
#import "config.h"

@interface CIShipDateTableViewCell ()

@property NSMutableArray *selectedCarts;
@property UITextField *quantityField;

@end

@implementation CIShipDateTableViewCell

- (id)initOn:(NSDate *)shipDate for:(NSMutableArray *)selectedCartsParam usingQuantityField:(BOOL)useQuantity {
    self = [super initWithStyle:nil reuseIdentifier:@"CIShipDateTableViewCell"];
    if (self) {
        self.shipDate = shipDate;
        self.selectedCarts = selectedCartsParam;
        if (shipDate != nil) {
            NSString *label = shipDate == nil ? @"No dates selected, ship immediately." : [DateUtil convertDateToMmddyyyy:shipDate];
            self.textLabel.text = label;
        }
        self.backgroundColor = [UIColor colorWithRed:57/255.0f green:59/255.0f blue:64/255.0f alpha:1];
        self.textLabel.textColor = [UIColor whiteColor];
        self.textLabel.font = [UIFont fontWithName:kFontName size:14.0f];
        if (useQuantity) {
            self.quantityField = [[UITextField alloc] initWithFrame:CGRectMake(260, 10, 40, 20)];
            self.quantityField.textAlignment = NSTextAlignmentCenter;
            self.quantityField.font = [UIFont systemFontOfSize:14.0f];
            self.quantityField.borderStyle = UITextBorderStyleRoundedRect;
            self.quantityField.text = @"0";
            self.quantityField.delegate = self;
            self.quantityField.keyboardType = UIKeyboardTypeNumberPad;
            self.quantityField.backgroundColor = self.backgroundColor;
            self.quantityField.textColor = self.textLabel.textColor;
            [self addSubview:self.quantityField];

            if (self.selectedCarts.count == 1) {
                Cart *cart = [self.selectedCarts objectAtIndex:0];
                self.quantity = [cart getQuantityForShipDate:shipDate];
            }
        }
    }
    return self;
}

- (int)quantity {
    return self.quantityField.text.intValue;
}

- (void)setQuantity:(int)quantity {
    self.quantityField.text = [NSString stringWithFormat:@"%i", quantity];
    [self.selectedCarts enumerateObjectsUsingBlock:^(Cart *cart, NSUInteger idx, BOOL *stop) {
        [cart setQuantity:quantity forShipDate:self.shipDate];
    }];
}

#pragma mark UITextViewDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    textField.backgroundColor = [UIColor whiteColor];
    textField.textColor = [UIColor blackColor];

    if ([textField.text isEqualToString:@"0"]) {
        textField.text = @"";
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}


// This text field is the quantity field on each ship date cell.
- (void)textFieldDidEndEditing:(UITextField *)textField {
    textField.backgroundColor = self.backgroundColor;
    textField.textColor = self.textLabel.textColor;

    if ([textField.text isEqualToString:@""]) {
        textField.text = @"0";
    }

    int quantity = textField.text.intValue;
    [self.selectedCarts enumerateObjectsUsingBlock:^(Cart *cart, NSUInteger idx, BOOL *stop) {
        [cart setQuantity:quantity forShipDate:self.shipDate];
    }];
}

@end