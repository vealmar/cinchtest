//
// Created by David Jafari on 5/26/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import "CIShipDateTableViewCell.h"
#import "Cart+Extensions.h"
#import "DateUtil.h"
#import "config.h"
#import "NotificationConstants.h"
#import "ShowConfigurations.h"

@interface CIShipDateTableViewCell ()

@property NSMutableArray *selectedCarts;
@property (strong, nonatomic) UILabel *xLabel;

@end

@implementation CIShipDateTableViewCell

- (id)initOn:(NSDate *)shipDate for:(NSMutableArray *)selectedCartsParam usingQuantityField:(BOOL)useQuantity {
    self = [super initWithStyle:nil reuseIdentifier:@"CIShipDateTableViewCell"];
    if (self) {
        self.shipDate = shipDate;
        self.selectedCarts = selectedCartsParam;
        if (shipDate != nil) {
            NSString *label = shipDate == nil ? @"No dates selected, ship immediately." : [DateUtil convertNSDateToApiDate:shipDate];
            self.textLabel.text = label;
        }

        if ([ShowConfigurations instance].isLineItemShipDatesType && shipDate != nil) {
            self.textLabel.text = [DateUtil convertNSDateToApiDate:shipDate];
        } else if ([ShowConfigurations instance].isOrderShipDatesType) {
            if (shipDate == nil) {
                self.textLabel.text = @"No dates selected, ship immediately.";
            } else {
                self.textLabel.text = [DateUtil convertNSDateToApiDate:shipDate];
            }
        }

        UIColor *backgroundColor = [UIColor colorWithRed:57/255.0f green:59/255.0f blue:64/255.0f alpha:1];
        self.backgroundColor = backgroundColor;
        self.textLabel.textColor = [UIColor whiteColor];
        self.textLabel.font = [UIFont fontWithName:kFontName size:14.0f];
        if (useQuantity) {
            self.quantityField = [[UITextField alloc] initWithFrame:CGRectMake(190, 10, 40, 20)];
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

            self.xLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.quantityField.frame.origin.x-15, self.quantityField.frame.origin.y, 20, self.quantityField.frame.size.height)];
            self.xLabel.font = [UIFont systemFontOfSize:14.0f];
            self.xLabel.textColor = [UIColor whiteColor];
            self.xLabel.text = @"x";
            [self addSubview:self.xLabel];

            self.lineTotalBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(self.quantityField.frame.origin.x+ 50, self.quantityField.frame.origin.y, 75, self.quantityField.frame.size.height)];
            self.lineTotalBackgroundView.backgroundColor = [UIColor colorWithRed:0.161 green:0.169 blue:0.169 alpha:1];
            self.lineTotalBackgroundView.layer.cornerRadius = 3;
            [self addSubview:self.lineTotalBackgroundView];

            self.lineTotalLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.quantityField.frame.origin.x+ 50, self.quantityField.frame.origin.y, 70, self.quantityField.frame.size.height)];
            self.lineTotalLabel.font = [UIFont systemFontOfSize:13.0f];
            self.lineTotalLabel.textColor = [UIColor whiteColor];
            self.lineTotalLabel.text = @"$0.00";
            self.lineTotalLabel.textAlignment = NSTextAlignmentRight;
            self.lineTotalLabel.backgroundColor = [UIColor clearColor];
            [self addSubview:self.lineTotalLabel];
        }

        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cellTapped:)];
        tapGesture.numberOfTouchesRequired = 1;
        tapGesture.cancelsTouchesInView = NO;
        [self.contentView addGestureRecognizer:tapGesture];

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

- (void)cellTapped:(UISwipeGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        [self.quantityField becomeFirstResponder];
    }
}

#pragma mark UITextViewDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    textField.backgroundColor = [UIColor whiteColor];
    textField.textColor = [UIColor blackColor];

    if ([textField.text isEqualToString:@"0"]) {
        textField.text = @"";
    }

    [[NSNotificationCenter defaultCenter] addObserver:textField selector:@selector(resignFirstResponder) name:CartDeselectionNotification object:nil];
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

    [[NSNotificationCenter defaultCenter] removeObserver:textField name:CartDeselectionNotification object:nil];

    if (self.resignedFirstResponderBlock) {
        self.resignedFirstResponderBlock(self);
    }
}

@end