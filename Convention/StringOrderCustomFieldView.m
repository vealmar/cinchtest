//
// Created by David Jafari on 6/29/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import "StringOrderCustomFieldView.h"
#import "ShowCustomField.h"

@interface StringOrderCustomFieldView()

@property UITextField *textField;

@end

@implementation StringOrderCustomFieldView

- (id)init:(ShowCustomField *)showCustomField at:(CGPoint)cgPoint withElementWidth:(CGFloat)elementWidth {
    self = [super init];
    if (self) {
        self.showCustomField = showCustomField;

        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(cgPoint.x, cgPoint.y, elementWidth, 35.0)];
        label.font = [UIFont fontWithName:@"Futura-MediumItalic" size:22.0f];
        label.textColor = [UIColor whiteColor];
        label.text = showCustomField.label;
        [self addSubview:label];

        self.textField = [[UITextField alloc] initWithFrame:CGRectMake(cgPoint.x, CGRectGetMaxY(label.frame) + 10.0, elementWidth, 44.0)];
        self.textField.backgroundColor = [UIColor whiteColor];
        [self addSubview:self.textField];

        self.frame = CGRectMake(cgPoint.x, cgPoint.y, elementWidth, 35.0 + 10.0 + 44.0);
    }
    return self;
}

- (NSString *)value {
    return self.textField.text;
}

- (void)value:(NSString *)value {
    self.textField.text = value;
}


@end