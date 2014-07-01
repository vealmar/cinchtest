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
        self.selectedDate = [NSNull null];
        self.frame = CGRectMake(cgPoint.x, cgPoint.y, elementWidth, 35.0 + 10.0 + 44.0);
        self.showCustomField = showCustomField;

        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, elementWidth, 35.0)];
        label.font = [UIFont fontWithName:@"Futura-MediumItalic" size:22.0f];
        label.textColor = [UIColor whiteColor];
        label.text = showCustomField.label;
        [self addSubview:label];

        self.dateTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(label.frame) + 10.0, elementWidth, 44.0)];
        self.dateTextField.delegate = self;
        self.dateTextField.backgroundColor = [UIColor whiteColor];
        [self addSubview:self.dateTextField];

        self.dateSelectorViewController = [[OrderShipDateViewController alloc] initWithDelegate:self];
        self.datePopoverController = [[UIPopoverController alloc] initWithContentViewController:self.dateSelectorViewController];
        [self.datePopoverController setPopoverContentSize:CGSizeMake(self.dateSelectorViewController.view.frame.size.width, self.dateSelectorViewController.view.frame.size.height)];
    }
    return self;
}

- (NSString *)value {
    return self.selectedDate == [NSNull null] ? [NSNull null] : [[DateUtil createFormatter:@"MM/dd/yyyy"] stringFromDate:self.selectedDate];
}

- (void)value:(NSString *)value {
    if (value != [NSNull null]) {
        [self selectShipDate:[[DateUtil createFormatter:@"MM/dd/yyyy"] dateFromString:value]];
        self.dateSelectorViewController.selectedDate = self.selectedDate;
    }
}

- (void)updateShipDateTextField {
    self.dateTextField.text = self.selectedDate ? [[DateUtil createFormatter:@"MM/dd/yyyy"] stringFromDate:self.selectedDate] : @"";
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