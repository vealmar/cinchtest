//
// Created by David Jafari on 2/7/15.
// Copyright (c) 2015 Urban Coding. All rights reserved.
//

#import "CIProductDescriptionColumnView.h"
#import "ThemeUtil.h"
#import "CITableViewColumn.h"
#import "Product.h"
#import "LineItem.h"


@implementation CIProductDescriptionColumnView

- (id)initColumn:(CITableViewColumn *)column frame:(CGRect)frame {
    self = [super initColumn:column frame:frame];
    if (self) {
        self.editableDescriptionTextField = [[UITextField alloc] initWithFrame:frame];
        self.editableDescriptionTextField.textColor = [ThemeUtil blackColor];
        self.editableDescriptionTextField.autocorrectionType = UITextAutocorrectionTypeNo;
        self.editableDescriptionTextField.textAlignment = column.alignment;
        self.editableDescriptionTextField.delegate = self;
        [self addSubview:self.editableDescriptionTextField];

        [self unhighlight];
    }

    return self;
}

- (void)render:(id)rowData lineItem:(LineItem *)lineItem {
    Product *product = (Product *) rowData;

    if (!product.editable.boolValue) {
        self.editableDescriptionTextField.hidden = YES;
        [super render:rowData];

    } else {
        self.editableDescriptionTextField.hidden = NO;
        self.editableDescriptionTextField.text = @"";

        if (lineItem) {
            self.editableDescriptionTextField.text = lineItem.description1;
        } else if (product) {
            self.editableDescriptionTextField.text = product.descr;
        }
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

@end