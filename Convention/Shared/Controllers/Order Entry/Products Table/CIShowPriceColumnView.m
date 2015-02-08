//
// Created by David Jafari on 12/21/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import "CIShowPriceColumnView.h"
#import "ThemeUtil.h"
#import "Product.h"
#import "NumberUtil.h"
#import "StringManipulation.h"
#import "CITableViewColumn.h"
#import "LineItem.h"

@interface CIShowPriceColumnView()

@property UILabel *priceLabel;
@property NSString *originalCellValue;

@end;

@implementation CIShowPriceColumnView

- (id)initColumn:(CITableViewColumn *)column frame:(CGRect)frame {
    self = [super initColumn:column frame:frame];
    if (self) {
        self.editablePriceTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 8.0, frame.size.width, frame.size.height - 16.0)];
        self.editablePriceTextField.textColor = [ThemeUtil blackColor];
        self.editablePriceTextField.autocorrectionType = UITextAutocorrectionTypeNo;
        self.editablePriceTextField.textAlignment = column.alignment;
        self.editablePriceTextField.borderStyle = UITextBorderStyleRoundedRect;
        self.editablePriceTextField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
        self.editablePriceTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        self.editablePriceTextField.enabled = YES;
        self.editablePriceTextField.backgroundColor = [UIColor whiteColor];
        self.editablePriceTextField.clearsOnBeginEditing = YES;
        self.editablePriceTextField.userInteractionEnabled = YES;
        
        self.editablePriceTextField.delegate = self;
        [self addSubview:self.editablePriceTextField];

        self.priceLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, self.frame.size.width, self.frame.size.height)];
        self.priceLabel.textAlignment = column.alignment;
        [self addSubview:self.priceLabel];

        [self unhighlight];
    }

    return self;
}

- (void)render:(id)rowData lineItem:(LineItem *)lineItem {
    [super render:rowData];

    Product *product = (Product *) rowData;

    if (product.editable && product.editable.intValue == 1) {
        self.priceLabel.hidden = YES;
        self.editablePriceTextField.hidden = NO;
    } else {
        self.priceLabel.hidden = NO;
        self.editablePriceTextField.hidden = YES;
    }

    self.priceLabel.text = @"";
    self.editablePriceTextField.text = @"";

    if (lineItem != nil) {
        self.editablePriceTextField.text = [NumberUtil formatDollarAmount:lineItem.price];
    } else {
        if (product) self.editablePriceTextField.text = [NumberUtil formatDollarAmount:product.showprc];
        else self.editablePriceTextField.text = @"";
    }

    if (product) {
        self.priceLabel.text = [NumberUtil formatDollarAmount:product.showprc];
    }
}

-(void)unhighlight {
    self.editablePriceTextField.font = [UIFont regularFontOfSize:14.0];

    self.priceLabel.font = [UIFont regularFontOfSize:14.0];
    self.priceLabel.textColor = [ThemeUtil blackColor];
}

-(void)highlight:(NSDictionary *)attributes {
    UIFont *font = (UIFont *) [attributes objectForKey:NSFontAttributeName];
    if (font) {
        self.editablePriceTextField.font = font;
        self.priceLabel.font = font;
    }
    UIColor *color = (UIColor *) [attributes objectForKey:NSForegroundColorAttributeName];
    if (color) {
        self.priceLabel.textColor = color;
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
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
    if (!string.length)
        return YES;

    if (textField == self.editablePriceTextField) {
        NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
        NSString *expression = @"^\\-?([0-9]+)?(\\.([0-9]{1,2})?)?$";
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:expression
                                                                               options:NSRegularExpressionCaseInsensitive
                                                                                 error:nil];
        NSUInteger numberOfMatches = [regex numberOfMatchesInString:newString
                                                            options:0
                                                              range:NSMakeRange(0, [newString length])];
        if (numberOfMatches == 0)
            return NO;
    }
    return YES;
}

@end