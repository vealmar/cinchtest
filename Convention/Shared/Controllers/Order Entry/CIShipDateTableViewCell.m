//
// Created by David Jafari on 5/26/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import "CIShipDateTableViewCell.h"
#import "DateUtil.h"
#import "config.h"
#import "NotificationConstants.h"
#import "ShowConfigurations.h"
#import "ThemeUtil.h"
#import "LineItem.h"
#import "LineItem+Extensions.h"

@interface CIShipDateTableViewCell ()

@property NSMutableArray *selectedLines;
@property (strong, nonatomic) UILabel *xLabel;

@end

@implementation CIShipDateTableViewCell

- (id)initOn:(NSDate *)shipDate for:(NSMutableArray *)selectedCartsParam usingQuantityField:(BOOL)useQuantity {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"CIShipDateTableViewCell"];
    if (self) {
        self.shipDate = shipDate;
        self.selectedLines = selectedCartsParam;
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
            self.quantityField = [[UITextField alloc] initWithFrame:CGRectMake(160, 10, 55, 20)];
            self.quantityField.textAlignment = NSTextAlignmentCenter;
            self.quantityField.font = [UIFont systemFontOfSize:14.0f];
            self.quantityField.borderStyle = UITextBorderStyleRoundedRect;
            self.quantityField.text = @"0";
            self.quantityField.delegate = self;
            self.quantityField.keyboardType = UIKeyboardTypeNumberPad;
            self.quantityField.backgroundColor = self.backgroundColor;
            self.quantityField.textColor = self.textLabel.textColor;
            [self addSubview:self.quantityField];

            if (self.selectedLines.count == 1) {
                LineItem *newLineItem = [self.selectedLines objectAtIndex:0];
                self.quantityField.text = [NSString stringWithFormat:@"%i", [newLineItem getQuantityForShipDate:shipDate]];
            }

            self.xLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.quantityField.frame.origin.x - 13, self.quantityField.frame.origin.y, 20, self.quantityField.frame.size.height)];
            self.xLabel.font = [UIFont systemFontOfSize:14.0f];
            self.xLabel.textColor = [UIColor whiteColor];
            self.xLabel.text = @"x";
            [self addSubview:self.xLabel];

            self.lineTotalBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(self.quantityField.frame.origin.x + 60, self.quantityField.frame.origin.y, 90, self.quantityField.frame.size.height)];
            self.lineTotalBackgroundView.backgroundColor = [ThemeUtil blackColor];
            self.lineTotalBackgroundView.layer.cornerRadius = 3;
            [self addSubview:self.lineTotalBackgroundView];

            self.lineTotalLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.quantityField.frame.origin.x + 60, self.quantityField.frame.origin.y, 85, self.quantityField.frame.size.height)];
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
    [self.selectedLines enumerateObjectsUsingBlock:^(LineItem *lineItem, NSUInteger idx, BOOL *stop) {
        [lineItem setQuantity:quantity forShipDate:self.shipDate];
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

    [[NSNotificationCenter defaultCenter] addObserver:textField selector:@selector(resignFirstResponder) name:LineDeselectionNotification object:nil];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
//    [textField resignFirstResponder];
    [[NSNotificationCenter defaultCenter] postNotificationName:LineTabbedNotification object:self];
    return NO;
}

// This text field is the quantity field on each ship date cell.
- (void)textFieldDidEndEditing:(UITextField *)textField {
    textField.backgroundColor = self.backgroundColor;
    textField.textColor = self.textLabel.textColor;

    if ([textField.text isEqualToString:@""]) {
        textField.text = @"0";
    }

    int quantity = textField.text.intValue;
    [self.selectedLines enumerateObjectsUsingBlock:^(LineItem *lineItem, NSUInteger idx, BOOL *stop) {
        [lineItem setQuantity:quantity forShipDate:self.shipDate];
    }];

    [[NSNotificationCenter defaultCenter] removeObserver:textField name:LineDeselectionNotification object:nil];

    if (self.resignedFirstResponderBlock) {
        self.resignedFirstResponderBlock(self);
    }
}

@end