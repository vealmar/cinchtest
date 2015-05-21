//
// Created by David Jafari on 12/21/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import "CIQuantityColumnView.h"
#import "Configurations.h"
#import "ThemeUtil.h"
#import "StringManipulation.h"
#import "CITableViewColumn.h"
#import "LineItem.h"
#import "LineItem+Extensions.h"

@interface CIQuantityColumnView ()

@property NSString *originalCellValue;

@end

@implementation CIQuantityColumnView

- (id)initColumn:(CITableViewColumn *)column frame:(CGRect)frame {
    self = [super initColumn:column frame:frame];
    if (self) {
        self.quantityTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 8.0, frame.size.width, (CGFloat) (frame.size.height - 16.0))];
        self.quantityTextField.textColor = [ThemeUtil blackColor];
        self.quantityTextField.autocorrectionType = UITextAutocorrectionTypeNo;
        self.quantityTextField.borderStyle = UITextBorderStyleRoundedRect;
        self.quantityTextField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
        self.quantityTextField.textAlignment = column.alignment;
        self.quantityTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        self.quantityTextField.enabled = YES;
        self.quantityTextField.backgroundColor = [UIColor whiteColor];
        self.quantityTextField.clearsOnBeginEditing = YES;
        self.quantityTextField.delegate = self;
        self.quantityTextField.userInteractionEnabled = YES;
        [self addSubview:self.quantityTextField];
        [self unhighlight];
    }

    return self;
}

- (void)render:(id)rowData lineItem:(LineItem *)lineItem {
    [super render:rowData];
    [self updateQuantity:lineItem];
}

- (void)updateQuantity:(LineItem *)lineItem {
    if (lineItem) {
        self.quantityTextField.text = [NSString stringWithFormat:@"%i", lineItem.totalQuantity];
    } else {
        self.quantityTextField.text = @"0";
    }
}

-(void)unhighlight {
    self.quantityTextField.font = [UIFont regularFontOfSize:14.0];
}

-(void)highlight:(NSDictionary *)attributes {
    UIFont *font = (UIFont *) attributes[NSFontAttributeName];
    if (font) {
        self.quantityTextField.font = font;
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    return ![Configurations instance].isLineItemShipDatesType;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    self.originalCellValue = [NSString stringWithString:textField.text];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if ([textField.text isEmpty]) {
        textField.text = self.originalCellValue;
    }
    if ([textField isFirstResponder]) [textField resignFirstResponder];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (string.length != 0) {
        NSError *error;
        NSRegularExpression *numbersOnly = [NSRegularExpression regularExpressionWithPattern:@"[0-9]+" options:NSRegularExpressionCaseInsensitive error:&error];
        NSInteger numberOfMatches = [numbersOnly numberOfMatchesInString:string options:0 range:NSMakeRange(0, string.length)];
        return numberOfMatches == 1;
    }
    return YES;
}

@end