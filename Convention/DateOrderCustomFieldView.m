//
// Created by David Jafari on 6/29/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import "DateOrderCustomFieldView.h"
#import "ShowCustomField.h"
#import "DateUtil.h"

@interface  DateOrderCustomFieldView()

@property UIPopoverController *datePopoverController;
@property NSDate *selectedDate;
@property UITextField *dateTextField;
@property OrderShipDateViewController *dateSelectorViewController; // todo this can just be a generic shipdate controller

@end

@implementation DateOrderCustomFieldView

-(id)init:(ShowCustomField *)showCustomField at:(CGPoint)cgPoint withElementWidth:(CGFloat)elementWidth {
    self = [super init];
    if (self) {
        self.showCustomField = showCustomField;

        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(cgPoint.x, cgPoint.y, elementWidth, 35.0)];
        label.font = [UIFont fontWithName:@"Futura-MediumItalic" size:22.0f];
        label.textColor = [UIColor whiteColor];
        label.text = showCustomField.label;
        [self addSubview:label];

        self.dateTextField = [[UITextField alloc] initWithFrame:CGRectMake(cgPoint.x, CGRectGetMaxY(label.frame) + 10.0, elementWidth, 44.0)];
        self.dateTextField.backgroundColor = [UIColor whiteColor];
        [self addSubview:self.dateTextField];

        self.dateSelectorViewController = [[OrderShipDateViewController alloc] initWithDelegate:self];
        self.datePopoverController = [[UIPopoverController alloc] initWithContentViewController:self.dateSelectorViewController];
        [self.datePopoverController setPopoverContentSize:CGSizeMake(self.dateSelectorViewController.view.frame.size.width, self.dateSelectorViewController.view.frame.size.height)];

        self.frame = CGRectMake(cgPoint.x, cgPoint.y, elementWidth, 35.0 + 10.0 + 44.0);
    }
    return self;
}

- (NSString *)value {
    return [DateUtil convertDateToMmddyyyy:self.selectedDate];
}

- (void)value:(NSString *)value {
    [self selectShipDate:[DateUtil convertYyyymmddToDate:value]];
    self.dateSelectorViewController.selectedDate = self.selectedDate;
}

- (void)updateShipDateTextField {
    self.dateTextField.text = self.selectedDate ? [DateUtil convertDateToMmddyyyy:self.selectedDate] : @"";
}

- (void)selectShipDate:(NSDate *)date {
    self.selectedDate = date;
    [self updateShipDateTextField];
}

- (void)shipDateSelected:(NSDate *)date {
    [self selectShipDate:date];
    [self.datePopoverController dismissPopoverAnimated:YES];
}

- (void)orderShipDateViewControllerCancelled {
    [self.datePopoverController dismissPopoverAnimated:YES];
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    [self.datePopoverController presentPopoverFromRect:self.dateTextField.frame inView:self permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    return NO;
}

@end