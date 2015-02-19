//
//  CIFinalCustomerFormViewController.m
//  Convention
//
//  Created by Bogdan Covaci on 31.10.2014.
//  Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <Underscore.m/Underscore.h>
#import "CIFinalCustomerFormViewController.h"
#import "ShowConfigurations.h"
#import "SetupInfo.h"
#import "CoreDataManager.h"
#import "Order.h"
#import "CoreDataUtil.h"
#import "CIFinalCustomerInfoViewController.h"
#import "CurrentSession.h"
#import "Order+Extensions.h"
#import "ShowCustomField.h"
#import "Customer.h"

@interface CIFinalCustomerFormViewController () {
    SetupInfo *authorizedBy;
}

@property (strong, nonatomic) UIView *contentView;
@property (strong, nonatomic) XLFormRowDescriptor *authorizedByRow;
@property (strong, nonatomic) XLFormRowDescriptor *orderShipDateRow;
@property (strong, nonatomic) XLFormRowDescriptor *notesRow;
@property (strong, nonatomic) XLFormRowDescriptor *sendEmailRow;
@property (strong, nonatomic) XLFormRowDescriptor *sendEmailToRow;

@end

@implementation CIFinalCustomerFormViewController

- (id)init {
    self = [super initWithTitle:@"Order Details"];
    if (self) {
    }
    return self;
}

- (void)addSections:(XLFormDescriptor *)formDescriptor {
    XLFormSectionDescriptor *section = [XLFormSectionDescriptor formSection];
    section.title = @"Order Details";
    [formDescriptor addFormSection:section];
    
    self.authorizedByRow = [XLFormRowDescriptor formRowDescriptorWithTag:section.title rowType:XLFormRowDescriptorTypeText title:@"Authorized By"];
    [self setDefaultStyle:self.authorizedByRow];
    [section addFormRow:self.authorizedByRow];
    
    if ([ShowConfigurations instance].isOrderShipDatesType) {
        self.orderShipDateRow = [XLFormRowDescriptor formRowDescriptorWithTag:section.title rowType:XLFormRowDescriptorTypeDateInline title:@"Ship Date"];
        [self setDefaultStyle:self.orderShipDateRow];
        [section addFormRow:self.orderShipDateRow];
    }

    Underscore.array([[ShowConfigurations instance] orderCustomFields]).each(^(ShowCustomField *showCustomField) {
        XLFormRowDescriptor *descriptor = nil;
        if (showCustomField.isStringValueType) {
            descriptor = [XLFormRowDescriptor formRowDescriptorWithTag:showCustomField.fieldKey
                                                                                    rowType:XLFormRowDescriptorTypeText
                                                                                      title:showCustomField.label];
        } else if (showCustomField.isEnumValueType) {
            descriptor = [XLFormRowDescriptor formRowDescriptorWithTag:showCustomField.fieldKey
                                                                                    rowType:XLFormRowDescriptorTypeSelectorPush
                                                                                      title:showCustomField.label];
            descriptor.selectorOptions = Underscore.array(showCustomField.enumValues).map(^id(NSString *enumValue) {
                return [XLFormOptionsObject formOptionsObjectWithValue:enumValue displayText:enumValue];
            }).unwrap;
            descriptor.required = YES;
        } else if (showCustomField.isDateValueType) {
            descriptor = [XLFormRowDescriptor formRowDescriptorWithTag:showCustomField.fieldKey
                                                                                    rowType:XLFormRowDescriptorTypeDate
                                                                                      title:showCustomField.label];
        } else if (showCustomField.isBooleanValueType) {
            descriptor = [XLFormRowDescriptor formRowDescriptorWithTag:showCustomField.fieldKey
                                                                                    rowType:XLFormRowDescriptorTypeBooleanSwitch
                                                                                      title:showCustomField.label];
        } else {
            NSLog(@"Unsupported Custom Field Value Type.");
        }

        [self setDefaultStyle:descriptor];
        if (descriptor) {
            [section addFormRow:descriptor];
        }
    });

    section = [XLFormSectionDescriptor formSection];
    section.title = @"Additional Information";
    [formDescriptor addFormSection:section];
    self.notesRow = [XLFormRowDescriptor formRowDescriptorWithTag:section.title
                                                          rowType:XLFormRowDescriptorTypeTextView];
    [self.notesRow.cellConfig setObject:@"Order Notes" forKey:@"textView.placeholder"];
    [section addFormRow:self.notesRow];

    section = [XLFormSectionDescriptor formSection];
    section.title = @"Email";
    [formDescriptor addFormSection:section];
    self.sendEmailRow = [XLFormRowDescriptor formRowDescriptorWithTag:@"sendEmail"
                                                          rowType:XLFormRowDescriptorTypeBooleanSwitch
                                                                title:@"Send Email"];
    [self setDefaultStyle:self.sendEmailRow];
    [section addFormRow:self.sendEmailRow];

    self.sendEmailToRow = [XLFormRowDescriptor formRowDescriptorWithTag:@"sendEmail"
                                                                rowType:XLFormRowDescriptorTypeEmail
                                                                  title:@"Email Address"];
    [self setDefaultStyle:self.sendEmailToRow];
    [section addFormRow:self.sendEmailToRow];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    // set defaults

    if (nil == authorizedBy) {
        authorizedBy = [CoreDataManager getSetupInfo:@"authorizedBy"];
        if ([ShowConfigurations instance].vendorMode) {
            [self updateSetting:@"authorizedBy" newValue:[CurrentSession instance].vendorName setupInfo:authorizedBy];
        }
    }
    self.authorizedByRow.value = self.order && self.order.authorizedBy ? self.order.authorizedBy : authorizedBy ? authorizedBy.value : @"";
    self.notesRow.value = self.order && self.order.notes ? self.order.notes : @"";
    self.sendEmailRow.value = @(NO);

    if ([ShowConfigurations instance].isOrderShipDatesType) {
        id shipDate = self.order.shipDates.firstObject;
        if (shipDate) {
            self.orderShipDateRow.value = shipDate;
        } else {
            self.orderShipDateRow.value = [NSDate date];
        }
    }

    Customer *customer = (Customer *) [[CoreDataUtil sharedManager] fetchObject:@"Customer" inContext:[CurrentSession mainQueueContext] withPredicate:[NSPredicate predicateWithFormat:@"customer_id = %@", self.order.customerId]];
    if (customer) {
        self.sendEmailToRow.value = customer.email;
    } else {
        self.sendEmailToRow.value = @"";
    }

    Underscore.array([[ShowConfigurations instance] orderCustomFields]).each(^(ShowCustomField *showCustomField) {
        XLFormRowDescriptor *descriptor = [self.formController.form formRowWithTag:showCustomField.fieldKey];
        NSString *value = [self.order customFieldValueFor:showCustomField];
        if (showCustomField.isEnumValueType) {
            if (value) descriptor.value = [XLFormOptionsObject formOptionsObjectWithValue:value displayText:value];
            else descriptor.value = descriptor.selectorOptions.firstObject;
        } else {
            descriptor.value = value ? value : @"";
        }
    });
    
    [self.formController.tableView reloadData];
}

- (void)submit:(id)sender {
    NSString *authorizedByText = self.authorizedByRow.value ? self.authorizedByRow.value : @"";
    [self updateSetting:@"authorizedBy" newValue:authorizedByText setupInfo:authorizedBy];

    self.order.notes = self.notesRow.value;
    self.order.authorizedBy = self.authorizedByRow.value;
    if ([ShowConfigurations instance].isOrderShipDatesType) {
        self.order.shipDates = @[self.orderShipDateRow.value];
    }

    Underscore.array([[ShowConfigurations instance] orderCustomFields]).each(^(ShowCustomField *showCustomField) {
        id value = self.formController.form.formValues[showCustomField.fieldKey];
        if (showCustomField.isEnumValueType) {
            value = [(XLFormOptionsObject*)value displayText];
        }
        [self.order setCustomFieldValueFor:showCustomField value:(NSString *)value];
    });

    NSString *sendEmailTo = ((NSNumber *) self.sendEmailRow.value).boolValue ? self.sendEmailToRow.value : nil;

    [self.delegate submit:sendEmailTo];
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
            [[CurrentSession mainQueueContext] save:&error];
        }
    }
}

@end
