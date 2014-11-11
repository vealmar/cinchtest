//
//  CIFinalCustomerFormViewController.m
//  Convention
//
//  Created by Bogdan Covaci on 31.10.2014.
//  Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import "CIFinalCustomerFormViewController.h"
#import "ShowConfigurations.h"
#import "SetupInfo.h"
#import "CIAppDelegate.h"
#import "CoreDataManager.h"
#import "CoreDataUtil.h"


@interface CIFinalCustomerFormViewController () {
    SetupInfo *authorizedBy;
    SetupInfo *shipFlag;
    NSManagedObjectContext *context;
}

@property (strong, nonatomic) UIView *contentView;
@property (strong, nonatomic) XLFormViewController *formController;
@property (weak, nonatomic) XLFormRowDescriptor *authorizedByRow;
@property (weak, nonatomic) XLFormRowDescriptor *notesRow;

@property (assign, nonatomic) BOOL contactBeforeShippingConfig;
@property (assign, nonatomic) BOOL cancelConfig;
@property (assign, nonatomic) BOOL poNumberConfig;
@property (assign, nonatomic) BOOL paymentTermsConfig;
@end

@implementation CIFinalCustomerFormViewController

- (id)init {
    self = [super init];
    if (self) {
        self.preferredContentSize = CGSizeMake(300, 300);

        ShowConfigurations *configurations = [ShowConfigurations instance];
        self.contactBeforeShippingConfig = configurations.contactBeforeShipping;
        self.cancelConfig = configurations.cancelOrder;
        self.poNumberConfig = configurations.poNumber;
        self.paymentTermsConfig = configurations.paymentTerms;
    }
    return self;
}
- (void)loadView {
    self.view = [UIView new];
    self.view.frame = CGRectMake(0, 0, 540, 400);
    self.view.backgroundColor = [UIColor colorWithRed:0.141 green:0.141 blue:0.106 alpha:1];

    float w = self.view.bounds.size.width;
    float h = self.view.bounds.size.height;

    [[UILabel appearanceWhenContainedIn:[UITableViewHeaderFooterView class], nil] setFont:[UIFont fontWithName:@"Futura-MediumItalic" size:22.0f]];
    [[UILabel appearanceWhenContainedIn:[UITableViewHeaderFooterView class], nil] setTextColor:[UIColor whiteColor]];

    XLFormDescriptor *formDescriptor = [XLFormDescriptor formDescriptor];
    XLFormSectionDescriptor *section;
    XLFormRowDescriptor *row;

    formDescriptor.assignFirstResponderOnShow = YES;

//    section = [XLFormSectionDescriptor formSectionWithTitle:@"Authorized By"];
    section = [XLFormSectionDescriptor formSection];
    [formDescriptor addFormSection:section];

    self.authorizedByRow = [XLFormRowDescriptor formRowDescriptorWithTag:section.title
                                                                 rowType:XLFormRowDescriptorTypeTextView
                                                                   title:@"Authorized by"];
    [section addFormRow:self.authorizedByRow];
    
//    section = [XLFormSectionDescriptor formSectionWithTitle:@"Notes"];
    section = [XLFormSectionDescriptor formSection];
    [formDescriptor addFormSection:section];

    self.notesRow = [XLFormRowDescriptor formRowDescriptorWithTag:section.title
                                                          rowType:XLFormRowDescriptorTypeTextView
                                                            title:@"Notes"];
    [section addFormRow:self.notesRow];
    
    self.formController = [[XLFormViewController alloc] initWithForm:formDescriptor];
    self.formController.view.frame = CGRectMake(10, 10, w - 20, h - 20 - 70);
    self.formController.view.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];
    self.formController.tableView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.formController.view];

    UIView *buttonsView = [UIView new];
    buttonsView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:buttonsView];

    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [cancelButton addTarget:self action:@selector(back:) forControlEvents:UIControlEventTouchDown];
    [cancelButton setBackgroundImage:[UIImage imageNamed:@"cart-cancelout.png"] forState:UIControlStateNormal];
    [cancelButton setBackgroundImage:[UIImage imageNamed:@"cart-cancelin.png"] forState:UIControlStateHighlighted];
    cancelButton.frame = CGRectMake(0, 0, 162.0, 56.0);
    [buttonsView addSubview:cancelButton];

    UIButton *submitButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [submitButton addTarget:self action:@selector(submit:) forControlEvents:UIControlEventTouchDown];
    [submitButton setBackgroundImage:[UIImage imageNamed:@"submitorderout.png"] forState:UIControlStateNormal];
    [submitButton setBackgroundImage:[UIImage imageNamed:@"submitorderin.png"] forState:UIControlStateSelected];
    submitButton.frame = CGRectMake(cancelButton.frame.origin.x + cancelButton.frame.size.width + 5, 0, 260.0, 56.0);
    [buttonsView addSubview:submitButton];

    buttonsView.frame = CGRectMake(0, 0, submitButton.frame.origin.x + submitButton.frame.size.width, submitButton.frame.size.height);
    buttonsView.center = CGPointMake(w / 2, h - buttonsView.frame.size.height / 2 - 10);

    context = ((CIAppDelegate *) [[UIApplication sharedApplication] delegate]).managedObjectContext;
    authorizedBy = [CoreDataManager getSetupInfo:@"authorizedBy"];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];

    self.view.superview.bounds = CGRectMake(0, 0, 540, 400);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.authorizedByRow.value = self.order && self.order.authorized ? self.order.authorized : authorizedBy ? authorizedBy.value : @"";
    self.notesRow.value = self.order && self.order.notes ? self.order.notes : @"";
}

- (void)back:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)submit:(id)sender {
//    NSString *authorizedByText = self.authorizedByRow.value;
//    if (authorizedByText && authorizedByText.length) {
//        [self updateSetting:@"authorizedBy" newValue:authorizedByText setupInfo:authorizedBy];
//        if (self.contactBeforeShippingConfig) {
//            [self updateSetting:@"ship_flag" newValue:self.contactBeforeShippingCB.isChecked ? @"YES" : @"NO" setupInfo:shipFlag];
//        }
//
//        self.order.notes = self.notesRow.value;
//        self.order.authorized = self.authorizedByRow.value;
//
//        Underscore.array(self.customFieldViews).each(^(id<OrderCustomFieldView> orderCustomFieldView) {
//            [self.order setCustomFieldValueFor:orderCustomFieldView.showCustomField value:orderCustomFieldView.value];
//        });
//
//        if (self.poNumberConfig) {
//            self.order.po_number = (NSString *) [NilUtil nilOrObject:self.poNumberTextField.text];
//        }
//        if (self.contactBeforeShippingConfig) {
//            self.order.ship_flag = self.contactBeforeShippingCB.isChecked ? @(1) : @(0);
//        }
//        if (self.cancelConfig) {
//            NSNumber *cancelByDays = [cancelDaysHelper valueAtIndex:[self.cancelDaysControl selectedSegmentIndex]];
//            self.order.cancelByDays = (NSNumber *) [NilUtil nilOrObject:cancelByDays];
//        }
//        if (self.paymentTermsConfig) {
//            NSString *paymentTerms = [paymentTermsHelper valueAtIndex:[self.paymentTermsControl selectedSegmentIndex]];
//            self.order.payment_terms = (NSString *) [NilUtil nilOrObject:paymentTerms];
//        }
//
//        [self.delegate submit:nil];
//        [self.delegate dismissFinalCustomerViewController];
//    } else {
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Authorized By Required!" message:@"Please fill out Authorized By field before submitting!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
//        [alert show];
//    }
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

@end
