//
// Created by David Jafari on 6/29/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import "BooleanOrderCustomFieldView.h"
#import "ShowCustomField.h"
#import "MICheckBox.h"

@interface BooleanOrderCustomFieldView()

@property MICheckBox *checkBox;

@end

@implementation BooleanOrderCustomFieldView

-(id)init:(ShowCustomField *)showCustomField at:(CGPoint)cgPoint withElementWidth:(CGFloat)elementWidth {
    self = [super init];
    if (self) {
        self.showCustomField = showCustomField;

        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(cgPoint.x, cgPoint.y, elementWidth, 35.0)];
        label.font = [UIFont fontWithName:@"Futura-MediumItalic" size:22.0f];
        label.textColor = [UIColor whiteColor];
        label.text = showCustomField.label;
        [self addSubview:label];

        self.checkBox = [[MICheckBox alloc] initWithFrame:CGRectMake(470.0, cgPoint.y, 40.0, 40.0)];;
        [self addSubview:self.checkBox];

        self.frame = CGRectMake(cgPoint.x, cgPoint.y, elementWidth, 40.0);
    }
    return self;
}

- (NSString *)value {
    return self.checkBox.isChecked ? @"true" : @"false";
}

- (void)value:(NSString *)value {
    self.checkBox.isChecked = [value isEqualToString:@"true"];
}

@end