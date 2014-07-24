//
// Created by David Jafari on 6/29/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import "EnumOrderCustomFieldView.h"
#import "ShowCustomField.h"
#import "UIColor+Boost.h"

@interface EnumOrderCustomFieldView()

@property(strong, nonatomic) UISegmentedControl *segmentedControl;

@end

@implementation EnumOrderCustomFieldView

-(id)init:(ShowCustomField *)showCustomField at:(CGPoint)cgPoint withElementWidth:(CGFloat)elementWidth {
    self = [super init];
    if (self) {
        if (showCustomField.enumValues.count == 0) {
            NSLog(@"Enum must have more than one enum_values.");
            [NSException raise:NSGenericException format:@"Enum must have more than one enum_values."];
        }

        self.frame = CGRectMake(cgPoint.x, cgPoint.y, elementWidth, 35.0 + 10.0 + 35.0);
        self.showCustomField = showCustomField;

        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, elementWidth, 35.0)];
        label.font = [UIFont fontWithName:@"Futura-MediumItalic" size:22.0f];
        label.textColor = [UIColor whiteColor];
        label.text = showCustomField.label;
        [self addSubview:label];

        UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:showCustomField.enumValues];
        self.segmentedControl = segmentedControl;
        self.segmentedControl.frame = CGRectMake(0, CGRectGetMaxY(label.frame) + 10, elementWidth, 35.0);
        self.segmentedControl.tintColor = [UIColor colorWith256Red:255 green:144 blue:58];
        [self addSubview:self.segmentedControl];
    }
    return self;
}

- (NSString *)value {
    return (NSString *)[self.showCustomField.enumValues objectAtIndex:[self.segmentedControl selectedSegmentIndex]];
}

- (void)value:(NSString *)value {
    if ([[NSNull null] isEqual:value]) {
        [[self segmentedControl] setSelectedSegmentIndex:0];
    } else {
        [self.segmentedControl setSelectedSegmentIndex:[self.showCustomField.enumValues indexOfObject:value]];
    }
}

@end