//
//  CIFinalCustomerInfoViewController.m
//  Convention
//
//  Created by Matthew Clark on 4/25/12.
//  Copyright (c) 2012 MotionMobs. All rights reserved.
//

#import "CIFinalCustomerInfoViewController.h"
#import "Macros.h"
#import "config.h"
#import "CoreDataUtil.h"
#import "CIAppDelegate.h"
#import "SetupInfo.h"
#import "Order.h"
#import "ShowConfigurations.h"
#import "UIColor+Boost.h"
#import "CancelOrderDaysHelper.h"
#import "NilUtil.h"

@interface CIFinalCustomerInfoViewController () {
    SetupInfo *authorizedBy;
    SetupInfo *shipFlag;
    NSManagedObjectContext *context;
    CGRect originalBounds;
    CancelOrderDaysHelper *cancelDaysHelper;
}

@property(strong, nonatomic) UITextField *authorizedByTextField;
@property(strong, nonatomic) UITextView *notesTextView;
@property(strong, nonatomic) MICheckBox *contactBeforeShippingCB;
@property(strong, nonatomic) UISegmentedControl *cancelDaysControl;
@property BOOL contactBeforeShippingConfig;
@property BOOL cancelConfig;

@end

@implementation CIFinalCustomerInfoViewController
- (id)init {
    self = [super init];
    if (self) {
        ShowConfigurations *configurations = [ShowConfigurations instance];
        self.contactBeforeShippingConfig = configurations.contactBeforeShipping;
        self.cancelConfig = configurations.cancelOrder;
        cancelDaysHelper = [[CancelOrderDaysHelper alloc] init];
    }
    return self;
}

#pragma mark - View lifecycle



- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    context = ((CIAppDelegate *) [[UIApplication sharedApplication] delegate]).managedObjectContext;
    [self defaultAuthorizedbyText];
    [self defaultShippingFields];
    self.notesTextView.text = self.order && self.order.notes ? self.order.notes : @"";
    if (self.cancelConfig) {
        [self.cancelDaysControl setSelectedSegmentIndex:[cancelDaysHelper indexForDays:self.order.cancelByDays]];
    }
    self.view.superview.bounds = originalBounds;
}

- (void)defaultAuthorizedbyText {
    NSDictionary *subs = [NSDictionary dictionaryWithObject:@"authorizedBy" forKey:@"ITEMNAME"];
    CIAppDelegate *appDelegate = (CIAppDelegate *) [[UIApplication sharedApplication] delegate];
    NSManagedObjectModel *model = appDelegate.managedObjectModel;
    NSFetchRequest *req = [model fetchRequestFromTemplateWithName:@"getSetupItem" substitutionVariables:subs];
    NSError *error = nil;
    NSArray *results = [context executeFetchRequest:req error:&error];
    if (!error && results != nil && [results count] > 0) {
        authorizedBy = [results objectAtIndex:0];
    }
    self.authorizedByTextField.text = self.order && self.order.authorized ? self.order.authorized
            : authorizedBy ? authorizedBy.value : @"";
}

- (void)defaultShippingFields {
    {
        if (self.contactBeforeShippingConfig) {
            NSDictionary *subs = [NSDictionary dictionaryWithObject:@"ship_flag" forKey:@"ITEMNAME"];
            CIAppDelegate *appDelegate = (CIAppDelegate *) [[UIApplication sharedApplication] delegate];
            NSManagedObjectModel *model = appDelegate.managedObjectModel;
            NSFetchRequest *req = [model fetchRequestFromTemplateWithName:@"getSetupItem" substitutionVariables:subs];
            NSError *error = nil;
            NSArray *results = [context executeFetchRequest:req error:&error];
            if (!error && results != nil && [results count] > 0) {
                shipFlag = [results objectAtIndex:0];
            }
            [self.contactBeforeShippingCB updateCheckBox:self.order && [self.order.ship_flag boolValue] ? YES
                    : shipFlag ? [shipFlag.value isEqualToString:@"YES"] : NO];
        }

    }
}

- (void)loadView {
    UIView *view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];
    [view setBackgroundColor:[UIColor colorWith256Red:37 green:36 blue:28]];
    self.view = view;
    self.view.translatesAutoresizingMaskIntoConstraints = NO;
    CGFloat leftX = 30.0;
    CGFloat elementWidth = 480.0;
    CGFloat currentY = 0.0;
    CGFloat verticalMargin = 20.0;
    UIFont *labelFont = [UIFont fontWithName:@"Futura-MediumItalic" size:22.0f];
    UILabel *authorizedByLabel = [[UILabel alloc] initWithFrame:CGRectMake(leftX, currentY + (verticalMargin * 2), 300.0, 35.0)];
    authorizedByLabel.font = labelFont;
    authorizedByLabel.textColor = [UIColor whiteColor];
    authorizedByLabel.text = @"AUTHORIZED BY";
    [self.view addSubview:authorizedByLabel];
    self.authorizedByTextField = [[UITextField alloc] initWithFrame:CGRectMake(leftX, CGRectGetMaxY(authorizedByLabel.frame) + verticalMargin, elementWidth, 44.0)];
    self.authorizedByTextField.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.authorizedByTextField];
    UILabel *notesLabel = [[UILabel alloc] initWithFrame:CGRectMake(leftX, CGRectGetMaxY(self.authorizedByTextField.frame) + verticalMargin, 300.0, 35.0)];
    notesLabel.font = labelFont;
    notesLabel.textColor = [UIColor whiteColor];
    notesLabel.text = @"NOTES";
    [self.view addSubview:notesLabel];
    self.notesTextView = [[UITextView alloc] initWithFrame:CGRectMake(leftX, CGRectGetMaxY(notesLabel.frame) + verticalMargin, elementWidth, 80.0)];
    [self.view addSubview:self.notesTextView];
    currentY = CGRectGetMaxY(self.notesTextView.frame);
    if (self.contactBeforeShippingConfig) {
        UILabel *contactLabel = [[UILabel alloc] initWithFrame:CGRectMake(leftX, currentY + verticalMargin, 350.0, 35.0)];
        contactLabel.font = labelFont;
        contactLabel.textColor = [UIColor whiteColor];
        contactLabel.text = @"CONTACT BEFORE SHIPPING?";
        [self.view addSubview:contactLabel];
        self.contactBeforeShippingCB = [[MICheckBox alloc] initWithFrame:CGRectMake(470.0, contactLabel.frame.origin.y, 40.0, 40.0)];
        [self.view addSubview:self.contactBeforeShippingCB];
        currentY = CGRectGetMaxY(self.contactBeforeShippingCB.frame);
    }
    if (self.cancelConfig) {
        UILabel *cancelLabel = [[UILabel alloc] initWithFrame:CGRectMake(leftX, currentY, 420.0, 35.0)];
        cancelLabel.font = labelFont;
        cancelLabel.textColor = [UIColor whiteColor];
        cancelLabel.text = @"CANCEL IF NOT SHIPPED WITHIN -";
        [self.view addSubview:cancelLabel];
        self.cancelDaysControl = [[UISegmentedControl alloc] initWithItems:[cancelDaysHelper displayStrings]];
        self.cancelDaysControl.frame = CGRectMake(leftX, CGRectGetMaxY(cancelLabel.frame) + verticalMargin, elementWidth, 35.0);
        self.cancelDaysControl.tintColor = [UIColor colorWith256Red:255 green:144 blue:58];
        [self.view addSubview:self.cancelDaysControl];
        currentY = CGRectGetMaxY(self.cancelDaysControl.frame);
    }
    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [cancelButton addTarget:self action:@selector(back:) forControlEvents:UIControlEventTouchDown];
    [cancelButton setBackgroundImage:[UIImage imageNamed:@"cart-cancelout.png"] forState:UIControlStateNormal];
    [cancelButton setBackgroundImage:[UIImage imageNamed:@"cart-cancelin.png"] forState:UIControlStateHighlighted];
    cancelButton.frame = CGRectMake(leftX + 10.0, currentY + verticalMargin, 162.0, 56.0);
    UIButton *submitButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [submitButton addTarget:self action:@selector(submit:) forControlEvents:UIControlEventTouchDown];
    [submitButton setBackgroundImage:[UIImage imageNamed:@"submitorderout.png"] forState:UIControlStateNormal];
    [submitButton setBackgroundImage:[UIImage imageNamed:@"submitorderin.png"] forState:UIControlStateSelected];
    submitButton.frame = CGRectMake(240.0, cancelButton.frame.origin.y, 260.0, 56.0);
    currentY = CGRectGetMaxY(submitButton.frame);
    [self.view addSubview:cancelButton];
    [self.view addSubview:submitButton];
    self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, 540, currentY + (verticalMargin * 2));
}

- (void)viewDidLoad {
    [super viewDidLoad];
    originalBounds = self.view.bounds;
}

- (void)back:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)submit:(id)sender {
    if (!IS_EMPTY_STRING(self.authorizedByTextField.text)) {
        if (![self.authorizedByTextField.text isEqualToString:authorizedBy.value]) {//SG: If the value specified for Authorized By last time is not same as the value specified this time, update the value in setupinfo.
            if (authorizedBy != nil) {
                authorizedBy.value = self.authorizedByTextField.text;
            } else {
                SetupInfo *setup = (SetupInfo *) [[CoreDataUtil sharedManager] createNewEntity:@"SetupInfo"];
                setup.item = @"authorizedBy";
                setup.value = self.authorizedByTextField.text;
            }
            NSError *error;
            [context save:&error];
        }
        if (self.contactBeforeShippingConfig) {
            NSError *error;
            if (shipFlag == nil) {   //SG: If the value specified for Contact Before Shipping last time is not same as the value specified this time, update the value in setupinfo.
                SetupInfo *setup = (SetupInfo *) [[CoreDataUtil sharedManager] createNewEntity:@"SetupInfo"];
                setup.item = @"ship_flag";
                setup.value = self.contactBeforeShippingCB.isChecked ? @"YES" : @"NO";
                [context save:&error];
            } else if ((self.contactBeforeShippingCB.isChecked && [shipFlag.value isEqualToString:@"NO"])
                    || (!self.contactBeforeShippingCB.isChecked && [shipFlag.value isEqualToString:@"YES"])) {
                shipFlag.value = self.contactBeforeShippingCB.isChecked ? @"YES" : @"NO";
                [context save:&error];
            }
        }

        if (self.delegate) {
            NSMutableDictionary *dict = [[self.delegate getCustomerInfo] mutableCopy];
            if (dict == nil) {
                return;
            }
            [dict setObject:self.notesTextView.text forKey:kNotes];
            [dict setObject:self.authorizedByTextField.text forKey:kAuthorizedBy];
            if (self.contactBeforeShippingConfig) {
                [dict setObject:(self.contactBeforeShippingCB.isChecked ? @"true" : @"false") forKey:kShipFlag];
            }
            if (self.cancelConfig) {
                NSNumber *cancelByDays = [cancelDaysHelper numberAtIndex:[self.cancelDaysControl selectedSegmentIndex]];
                [dict setObject:[NilUtil objectOrNSNull:cancelByDays] forKey:kCancelByDays];
            }
            [self.delegate setAuthorizedByInfo:[dict copy]];
            [self.delegate submit:nil];
            [self dismissViewControllerAnimated:NO completion:nil];
        }
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Authorized By Required!" message:@"Please fill out Authorized By field before submitting!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}

- (void)setViewMovedUpDouble:(BOOL)movedUp {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3]; // if you want to slide up the view

    CGRect rect = self.view.bounds;
    if (movedUp) {
        // 1. move the view's origin up so that the text field that will be hidden come above the keyboard
        // 2. increase the size of the view so that the area behind the keyboard is covered up.
        rect.origin.y += kOFFSET_FOR_KEYBOARD + 70;
        self.view.bounds = rect;
    }
    else {
        // revert back to the normal state.
        self.view.bounds = originalBounds;
    }

    [UIView commitAnimations];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    return YES;
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
//    [textView resignFirstResponder];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if ([textField isFirstResponder])
        [textField resignFirstResponder];
}

- (void)textViewDidBeginEditing:(UITextView *)sender {
    if ([sender isEqual:self.notesTextView]) {
        //move the main view, so that the keyboard does not hide it.
        if (self.view.frame.origin.y >= 0) {
            [self setViewMovedUpDouble:YES];
        }
    }
}

- (void)textViewDidEndEditing:(UITextView *)sender {
    if ([sender isEqual:self.notesTextView]) {
        //move the main view, so that the keyboard does not hide it.
        if (self.view.frame.origin.y >= 0) {
            [self setViewMovedUpDouble:NO];
        }
    }
}

@end
