//
//  CIFinalCustomerInfoViewController.m
//  Convention
//
//  Created by Matthew Clark on 4/25/12.
//  Copyright (c) 2012 MotionMobs. All rights reserved.
//

#import <Underscore.m/Underscore.h>
#import "CIFinalCustomerInfoViewController.h"
#import "Macros.h"
#import "config.h"
#import "CoreDataUtil.h"
#import "CIAppDelegate.h"
#import "SetupInfo.h"
#import "Order.h"
#import "ShowConfigurations.h"
#import "UIColor+Boost.h"
#import "SegmentedControlHelper.h"
#import "NilUtil.h"
#import "CoreDataManager.h"
#import "DateUtil.h"
#import "UIView+Boost.h"
#import "OrderCustomFieldView.h"
#import "ShowCustomField.h"
#import "StringOrderCustomFieldView.h"
#import "DateOrderCustomFieldView.h"
#import "EnumOrderCustomFieldView.h"
#import "BooleanOrderCustomFieldView.h"
#import "Order+Extensions.h"

@interface CIFinalCustomerInfoViewController () {
    SetupInfo *authorizedBy;
    SetupInfo *shipFlag;
    NSManagedObjectContext *context;
    CGRect originalBounds;
    SegmentedControlHelper *cancelDaysHelper;
    SegmentedControlHelper *paymentTermsHelper;
}

@property(strong, nonatomic) UITextField *authorizedByTextField;
@property(strong, nonatomic) UITextField *poNumberTextField;
@property(strong, nonatomic) UITextView *notesTextView;
@property(strong, nonatomic) MICheckBox *contactBeforeShippingCB;
@property(strong, nonatomic) UISegmentedControl *cancelDaysControl;
@property(strong, nonatomic) UISegmentedControl *paymentTermsControl;
@property BOOL contactBeforeShippingConfig;
@property BOOL cancelConfig;
@property BOOL poNumberConfig;
@property BOOL paymentTermsConfig;
@property NSArray *customFieldViews; // id<OrderCustomFieldView>

@end

@implementation CIFinalCustomerInfoViewController
- (id)init {
    self = [super init];
    if (self) {
        ShowConfigurations *configurations = [ShowConfigurations instance];
        self.contactBeforeShippingConfig = configurations.contactBeforeShipping;
        self.cancelConfig = configurations.cancelOrder;
        self.poNumberConfig = configurations.poNumber;
        self.paymentTermsConfig = configurations.paymentTerms;
        cancelDaysHelper = [[SegmentedControlHelper alloc] initForCancelByDays];
        paymentTermsHelper = [[SegmentedControlHelper alloc] initForPaymentTerms];
    }
    return self;
}

#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    context = ((CIAppDelegate *) [[UIApplication sharedApplication] delegate]).managedObjectContext;
    [self defaultAuthorizedbyText];

    self.notesTextView.text = self.order && self.order.notes ? self.order.notes : @"";

    Underscore.array(self.customFieldViews).each(^(id<OrderCustomFieldView> orderCustomFieldView) {
        //take order custom field value and
        [orderCustomFieldView value:[self.order customFieldValueFor:orderCustomFieldView.showCustomField]];
    });

    if (self.contactBeforeShippingConfig) {
        [self defaultShippingFields];
    }

    if (self.cancelConfig) {
        [self.cancelDaysControl setSelectedSegmentIndex:[cancelDaysHelper indexForValue:self.order.cancelByDays]];
    }

    if (self.poNumberConfig) {
        self.poNumberTextField.text = self.order && self.order.po_number ? self.order.po_number : @"";
    }

    if (self.paymentTermsConfig) {
        [self.paymentTermsControl setSelectedSegmentIndex:[paymentTermsHelper indexForValue:self.order.payment_terms]];
    }

    self.view.superview.bounds = originalBounds;
}

- (void)defaultAuthorizedbyText {
    authorizedBy = [CoreDataManager getSetupInfo:@"authorizedBy"];
    self.authorizedByTextField.text = self.order && self.order.authorized ? self.order.authorized : authorizedBy ? authorizedBy.value : @"";
}

- (void)defaultShippingFields {
    shipFlag = [CoreDataManager getSetupInfo:@"ship_flag"];
    [self.contactBeforeShippingCB updateCheckBox:self.order && [self.order.ship_flag boolValue] ? YES : shipFlag ? [shipFlag.value isEqualToString:@"YES"] : NO];
}

- (void)loadView {
    UIView *view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];
    [view setBackgroundColor:[UIColor colorWith256Red:37 green:36 blue:28]];
    self.view = view;
    self.view.translatesAutoresizingMaskIntoConstraints = NO;
    CGFloat leftX = 30.0;
    CGFloat elementWidth = 480.0;
    __block CGFloat currentY = 0.0;
    CGFloat verticalMargin = 15.0;
    UIFont *labelFont = [UIFont fontWithName:@"Futura-MediumItalic" size:22.0f];
    UILabel *authorizedByLabel = [[UILabel alloc] initWithFrame:CGRectMake(leftX, currentY + (verticalMargin * 2), 300.0, 35.0)];
    authorizedByLabel.font = labelFont;
    authorizedByLabel.textColor = [UIColor whiteColor];
    authorizedByLabel.text = @"Authorized By";
    [self.view addSubview:authorizedByLabel];
    UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(leftX, CGRectGetMaxY(authorizedByLabel.frame) + 10, elementWidth, 44.0)];
    self.authorizedByTextField = textField;
    self.authorizedByTextField.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.authorizedByTextField];
    UILabel *notesLabel = [[UILabel alloc] initWithFrame:CGRectMake(leftX, CGRectGetMaxY(self.authorizedByTextField.frame) + verticalMargin, 300.0, 35.0)];
    notesLabel.font = labelFont;
    notesLabel.textColor = [UIColor whiteColor];
    notesLabel.text = @"Notes";
    [self.view addSubview:notesLabel];
    UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(leftX, CGRectGetMaxY(notesLabel.frame) + 10, elementWidth, 80.0)];;
    self.notesTextView = textView;
    [self.view addSubview:self.notesTextView];
    currentY = CGRectGetMaxY(self.notesTextView.frame);

    self.customFieldViews = Underscore.array([[ShowConfigurations instance] orderCustomFields]).map(^id(ShowCustomField *showCustomField) {
        UIView<OrderCustomFieldView> *fieldView;
        if (showCustomField.isStringValueType) {
            fieldView = [[StringOrderCustomFieldView alloc] init:showCustomField at:CGPointMake(leftX, currentY + verticalMargin) withElementWidth:elementWidth];
        } else if (showCustomField.isEnumValueType) {
            fieldView = [[EnumOrderCustomFieldView alloc] init:showCustomField at:CGPointMake(leftX, currentY + verticalMargin) withElementWidth:elementWidth];
        } else if (showCustomField.isDateValueType) {
            fieldView = [[DateOrderCustomFieldView alloc] init:showCustomField at:CGPointMake(leftX, currentY + verticalMargin) withElementWidth:elementWidth];
        } else if (showCustomField.isBooleanValueType) {
            fieldView = [[BooleanOrderCustomFieldView alloc] init:showCustomField at:CGPointMake(leftX, currentY + verticalMargin) withElementWidth:elementWidth];
        } else {
            NSLog(@"Unsupported Custom Field Value Type.");
            return [NSNull null];
        }
        [self.view addSubview:fieldView];
        currentY = CGRectGetMaxY(fieldView.frame);
        return fieldView;
    }).filter(^BOOL(id obj) {
        return [[NSNull null] isEqual:obj] ? NO : YES;
    }).unwrap;

    if (self.poNumberConfig) {
        UILabel *poLabel = [[UILabel alloc] initWithFrame:CGRectMake(leftX, currentY + verticalMargin, 420.0, 35.0)];
        poLabel.font = labelFont;
        poLabel.textColor = [UIColor whiteColor];
        poLabel.text = @"PO Number";
        [self.view addSubview:poLabel];
        textField = [[UITextField alloc] initWithFrame:CGRectMake(leftX, CGRectGetMaxY(poLabel.frame) + 10, elementWidth, 44.0)];
        self.poNumberTextField = textField;
        self.poNumberTextField.backgroundColor = [UIColor whiteColor];
        [self.view addSubview:self.poNumberTextField];
        currentY = CGRectGetMaxY(self.poNumberTextField.frame);
    }

    if (self.contactBeforeShippingConfig) {
        UILabel *contactLabel = [[UILabel alloc] initWithFrame:CGRectMake(leftX, currentY + verticalMargin, 350.0, 35.0)];
        contactLabel.font = labelFont;
        contactLabel.textColor = [UIColor whiteColor];
        contactLabel.text = @"Contact Before Shipping?";
        [self.view addSubview:contactLabel];
        MICheckBox *checkBox = [[MICheckBox alloc] initWithFrame:CGRectMake(470.0, contactLabel.frame.origin.y, 40.0, 40.0)];;
        self.contactBeforeShippingCB = checkBox;
        [self.view addSubview:self.contactBeforeShippingCB];
        currentY = CGRectGetMaxY(self.contactBeforeShippingCB.frame);
    }

    if (self.cancelConfig) {
        UILabel *cancelLabel = [[UILabel alloc] initWithFrame:CGRectMake(leftX, currentY + verticalMargin, 420.0, 35.0)];
        cancelLabel.font = labelFont;
        cancelLabel.textColor = [UIColor whiteColor];
        cancelLabel.text = @"Cancel If Not Shipped Within";
        [self.view addSubview:cancelLabel];
        UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:[cancelDaysHelper displayStrings]];
        self.cancelDaysControl = segmentedControl;
        self.cancelDaysControl.frame = CGRectMake(leftX, CGRectGetMaxY(cancelLabel.frame) + 10, elementWidth, 35.0);
        self.cancelDaysControl.tintColor = [UIColor colorWith256Red:255 green:144 blue:58];
        [self.view addSubview:self.cancelDaysControl];
        currentY = CGRectGetMaxY(self.cancelDaysControl.frame);
    }

    if (self.paymentTermsConfig) {
        UILabel *paymentTermsLabel = [[UILabel alloc] initWithFrame:CGRectMake(leftX, currentY + verticalMargin, 420.0, 35.0)];
        paymentTermsLabel.font = labelFont;
        paymentTermsLabel.textColor = [UIColor whiteColor];
        paymentTermsLabel.text = @"Payment Terms";
        [self.view addSubview:paymentTermsLabel];
        UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:[paymentTermsHelper displayStrings]];
        self.paymentTermsControl = segmentedControl;
        self.paymentTermsControl.frame = CGRectMake(leftX, CGRectGetMaxY(paymentTermsLabel.frame) + 10, elementWidth, 35.0);
        self.paymentTermsControl.tintColor = [UIColor colorWith256Red:255 green:144 blue:58];
        [self.view addSubview:self.paymentTermsControl];
        currentY = CGRectGetMaxY(self.paymentTermsControl.frame);
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

- (BOOL)disablesAutomaticKeyboardDismissal {
    return NO;  //Without this keyboard and datepickerview do not disappear even if the text or picker field resigns first responder status.
}

- (void)viewDidLoad {
    [super viewDidLoad];
    originalBounds = self.view.bounds;
}

- (void)back:(id)sender {
    [self.delegate dismissFinalCustomerViewController];
}


- (void)updateSetting:(NSString *)itemName newValue:(NSString *)newValue setupInfo:(SetupInfo *)setupInfo {
    if ([newValue length] > 0) {
        if (setupInfo == nil) {
            setupInfo = (SetupInfo *) [[CoreDataUtil sharedManager] createNewEntity:@"SetupInfo"];
            setupInfo.item = itemName;
        }
        if (!setupInfo.value || ![setupInfo.value isEqualToString:newValue]) {
            setupInfo.value = newValue;
            NSError *error;
            [context save:&error];
        }
    }
}

- (void)submit:(id)sender {
    if (IS_EMPTY_STRING(self.authorizedByTextField.text)) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Authorized By Required!" message:@"Please fill out Authorized By field before submitting!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return;
    } else {
        [self updateSetting:@"authorizedBy" newValue:self.authorizedByTextField.text setupInfo:authorizedBy];
        if (self.contactBeforeShippingConfig) {
            [self updateSetting:@"ship_flag" newValue:self.contactBeforeShippingCB.isChecked ? @"YES" : @"NO" setupInfo:shipFlag];
        }

        self.order.notes = self.notesTextView.text;
        self.order.authorized = self.authorizedByTextField.text;

        Underscore.array(self.customFieldViews).each(^(id<OrderCustomFieldView> orderCustomFieldView) {
            [self.order setCustomFieldValueFor:orderCustomFieldView.showCustomField value:orderCustomFieldView.value];
        });

        if (self.poNumberConfig) {
            self.order.po_number = (NSString *) [NilUtil nilOrObject:self.poNumberTextField.text];
        }
        if (self.contactBeforeShippingConfig) {
            self.order.ship_flag = self.contactBeforeShippingCB.isChecked ? @(1) : @(0);
        }
        if (self.cancelConfig) {
            NSNumber *cancelByDays = [cancelDaysHelper valueAtIndex:[self.cancelDaysControl selectedSegmentIndex]];
            self.order.cancelByDays = (NSNumber *) [NilUtil nilOrObject:cancelByDays];
        }
        if (self.paymentTermsConfig) {
            NSString *paymentTerms = [paymentTermsHelper valueAtIndex:[self.paymentTermsControl selectedSegmentIndex]];
            self.order.payment_terms = (NSString *) [NilUtil nilOrObject:paymentTerms];
        }
        
        [self.delegate submit:nil];
        [self.delegate dismissFinalCustomerViewController];
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

//Todo I don't think any of these text delegate methods except (shouldBeginEditing for ship dates) are called since the textfields' delegate is not being set.
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