//
// Created by David Jafari on 5/26/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import "CIShipDateTableViewCell.h"
#import "DateUtil.h"
#import "NotificationConstants.h"
#import "ShowConfigurations.h"
#import "ThemeUtil.h"
#import "LineItem.h"
#import "LineItem+Extensions.h"
#import "DateRange.h"
#import "NumberUtil.h"
#import "Product+Extensions.h"
#import "View+MASAdditions.h"

@interface CIShipDateTableViewCell ()

@property NSArray *selectedLines;
@property UILabel *priceLabel;
@property UILabel *xLabel;
@property UIView *lineTotalBackgroundView;
@property UILabel *lineTotalLabel;

@end

@implementation CIShipDateTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];

        self.textLabel.textColor = [ThemeUtil offBlackColor];
        self.textLabel.font = [UIFont boldFontOfSize:14.0F];

        self.priceLabel = [[UILabel alloc] init];
        self.priceLabel.textAlignment = NSTextAlignmentRight;
        self.priceLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.priceLabel.font = [UIFont systemFontOfSize:14.0f];
        self.priceLabel.textColor = [ThemeUtil noteColor];
        [self addSubview:self.priceLabel];

        self.xLabel = [[UILabel alloc] init];
        self.xLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.xLabel.font = [UIFont systemFontOfSize:14.0f];
        self.xLabel.textColor = [ThemeUtil noteColor];
        self.xLabel.text = @"x";
        [self addSubview:self.xLabel];

        self.quantityField = [[UITextField alloc] init];
        self.quantityField.textAlignment = NSTextAlignmentCenter;
        self.quantityField.font = [UIFont systemFontOfSize:14.0f];
        self.quantityField.borderStyle = UITextBorderStyleRoundedRect;
        self.quantityField.text = @"0";
        self.quantityField.delegate = self;
        self.quantityField.keyboardType = UIKeyboardTypeNumberPad;
        self.quantityField.textColor = self.textLabel.textColor;
        [self addSubview:self.quantityField];

        self.lineTotalBackgroundView = [[UIView alloc] init];
        self.lineTotalBackgroundView.backgroundColor = [UIColor clearColor];
        self.lineTotalBackgroundView.layer.cornerRadius = 3;
        self.lineTotalBackgroundView.layer.borderColor = [ThemeUtil noteColor].CGColor;
        self.lineTotalBackgroundView.layer.borderWidth = 0.1F;
        [self addSubview:self.lineTotalBackgroundView];

        self.lineTotalLabel = [[UILabel alloc] init];
        self.lineTotalLabel.font = [UIFont systemFontOfSize:13.0f];
        self.lineTotalLabel.textColor = [ThemeUtil noteColor];
        self.lineTotalLabel.text = @"$0.00";
        self.lineTotalLabel.textAlignment = NSTextAlignmentRight;
        self.lineTotalLabel.backgroundColor = [UIColor clearColor];
        [self addSubview:self.lineTotalLabel];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onPriceChanged:) name:LinePriceChangedNotification object:nil];

        [self.priceLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self.xLabel.mas_left).offset(-10);
            make.centerY.equalTo(self.textLabel.mas_centerY);
        }];

        [self.xLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self.quantityField.mas_left).offset(-10);
            make.centerY.equalTo(self.textLabel.mas_centerY);
        }];

        [self.quantityField mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self.lineTotalBackgroundView.mas_left).offset(-10);
            make.centerY.equalTo(self.textLabel.mas_centerY);
            make.height.equalTo(@20);
            make.width.equalTo(@55);
        }];

        [self.lineTotalBackgroundView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self.contentView.mas_right).offset(-15);
            make.left.greaterThanOrEqualTo(self.lineTotalLabel.mas_left).offset(3);
            make.centerY.equalTo(self.textLabel.mas_centerY);
            make.height.equalTo(@20);
            make.width.greaterThanOrEqualTo(@75);
        }];

        [self.lineTotalLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self.lineTotalBackgroundView.mas_right).offset(-5);
            make.centerY.equalTo(self.textLabel.mas_centerY);
            make.height.equalTo(@20);
        }];

        [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.mas_left);
            make.right.equalTo(self.mas_right);
        }];

        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cellTapped:)];
        tapGesture.numberOfTouchesRequired = 1;
        tapGesture.cancelsTouchesInView = NO;
        [self addGestureRecognizer:tapGesture];
    }

    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)prepareForDisplay:(NSDate *)shipDate selectedLineItems:(NSArray *)selectedLineItems {
    self.shipDate = shipDate;
    self.selectedLines = selectedLineItems;

    if ([ShowConfigurations instance].isLineItemShipDatesType && shipDate != nil) {
        self.textLabel.text = [DateUtil convertNSDateToApiDate:shipDate];
    } else {
        self.textLabel.text = @"";
    }

    if (self.selectedLines.count == 1) {
        LineItem *newLineItem = [self.selectedLines objectAtIndex:0];
        self.quantityField.text = [NSString stringWithFormat:@"%i", [newLineItem getQuantityForShipDate:shipDate]];
    } else {
        self.quantityField.text = @"";
    }

    [self updatePriceLabel];
    [self calculateLineTotal];
}

- (void)updatePriceLabel {
    if (self.selectedLines.count == 1) {
        LineItem *currentLineItem = self.selectedLines.firstObject;
        NSNumber *price = [currentLineItem priceOn:self.shipDate];
        self.priceLabel.text = [NumberUtil formatDollarAmount:price];
    } else {
        self.priceLabel.text = @"";
    }
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

- (void)calculateLineTotal {
    NSArray *fixedShipDates = [ShowConfigurations instance].orderShipDates.fixedDates;
    LineItem *currentLineItem = self.selectedLines.firstObject;
    NSNumber *price = currentLineItem.price;
    if ([ShowConfigurations instance].isAtOncePricing && fixedShipDates.count > 0) {
        if ([((NSDate *) fixedShipDates.firstObject) isEqualToDate:self.shipDate]) {
            price = currentLineItem.product.showprc;
        } else {
            price = currentLineItem.product.regprc;
        }
    }

    int quantity = [self.quantityField.text intValue];
    double total = quantity * [price doubleValue];
    self.lineTotalLabel.text = [NumberUtil formatDollarAmount:[NSNumber numberWithDouble:total]];

    if (quantity > 0) {
        self.lineTotalBackgroundView.layer.borderColor = [UIColor clearColor].CGColor;
        self.lineTotalBackgroundView.backgroundColor = [ThemeUtil orangeColor];
        self.lineTotalLabel.textColor = [UIColor whiteColor];
    } else {
        self.lineTotalBackgroundView.layer.borderColor = [ThemeUtil noteColor].CGColor;
        self.lineTotalBackgroundView.backgroundColor = [UIColor clearColor];
        self.lineTotalLabel.textColor = [ThemeUtil noteColor];
    }
}

- (void)cellTapped:(UISwipeGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        [self.quantityField becomeFirstResponder];
    }
}

#pragma mark Notification Handlers

- (void)onPriceChanged:(NSNotification *)notification {
    [self updatePriceLabel];
    [self calculateLineTotal];
}

#pragma mark UITextViewDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    textField.backgroundColor = [UIColor whiteColor];
    textField.textColor = [UIColor blackColor];

    if ([textField.text isEqualToString:@"0"]) {
        textField.text = @"";
    }

    if (textField.text.length > 0) {
        UITextRange *textRange = [textField textRangeFromPosition:textField.beginningOfDocument toPosition:textField.endOfDocument];
        [textField setSelectedTextRange:textRange];
    }

    [[NSNotificationCenter defaultCenter] addObserver:textField selector:@selector(resignFirstResponder) name:LineDeselectionNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:textField selector:@selector(resignFirstResponder) name:ProductsLoadRequestedNotification object:nil];
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
    [[NSNotificationCenter defaultCenter] removeObserver:textField name:ProductsLoadRequestedNotification object:nil];

    [self calculateLineTotal];
}

@end