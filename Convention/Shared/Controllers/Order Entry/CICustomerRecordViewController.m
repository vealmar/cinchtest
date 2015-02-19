//
// Created by David Jafari on 2/17/15.
// Copyright (c) 2015 Urban Coding. All rights reserved.
//

#import "CICustomerRecordViewController.h"
#import "Customer.h"
#import "CustomerManager.h"
#import "NotificationConstants.h"
#import "CIAlertView.h"

@interface CICustomerRecordViewController()

@property Customer *customer;

@end

@implementation CICustomerRecordViewController

-(id)init {
    self = [super initWithTitle:@"Create Customer"];
    if (self) {

    }
    return self;
}

-(void)prepareForDisplay:(Customer *)customer {
    self.customer = customer;
}

- (void)addSections:(XLFormDescriptor *)formDescriptor {
    //primary details

    XLFormSectionDescriptor *section = [XLFormSectionDescriptor formSection];
    section.title = @"";
    [formDescriptor addFormSection:section];
    
    XLFormRowDescriptor *row = [XLFormRowDescriptor formRowDescriptorWithTag:@"custid" rowType:XLFormRowDescriptorTypeText title:@"Customer ID"];
    row.required = YES;
    [self setDefaultStyle:row];
    [section addFormRow:row];
    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"billname" rowType:XLFormRowDescriptorTypeText title:@"Name"];
    row.required = YES;
    [self setDefaultStyle:row];
    [section addFormRow:row];
    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"email" rowType:XLFormRowDescriptorTypeEmail title:@"Email"];
    [self setDefaultStyle:row];
    [section addFormRow:row];

    // shipping address

    section = [XLFormSectionDescriptor formSection];
    section.title = @"Shipping Address";
    [formDescriptor addFormSection:section];

    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"line1" rowType:XLFormRowDescriptorTypeText title:@"Line 1"];
    [self setDefaultStyle:row];
    [section addFormRow:row];
    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"line2" rowType:XLFormRowDescriptorTypeText title:@"Line 2"];
    [self setDefaultStyle:row];
    [section addFormRow:row];
    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"city" rowType:XLFormRowDescriptorTypeText title:@"City"];
    [self setDefaultStyle:row];
    [section addFormRow:row];
    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"state" rowType:XLFormRowDescriptorTypeText title:@"State"];
    [self setDefaultStyle:row];
    [section addFormRow:row];
    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"zip" rowType:XLFormRowDescriptorTypeText title:@"Zip"];
    [self setDefaultStyle:row];
    [section addFormRow:row];
    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"country" rowType:XLFormRowDescriptorTypeText title:@"Country"];
    [self setDefaultStyle:row];
    [section addFormRow:row];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.customer) {
        [self.formController setValue:self.customer.custid forKey:@"custid"];
        [self.formController setValue:self.customer.billname forKey:@"billname"];
        [self.formController setValue:self.customer.email forKey:@"email"];
        
        //@todo if we allow customer edits in the future, we need the customer record to contain address info or to look it up
    }
    [self.formController.tableView reloadData];
}

- (void)submit:(id)sender {
    NSArray *errors = [self.formController formValidationErrors];
    if (errors.count > 0) {
        for (NSError *error in errors) {
            UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"Validation Error" message:error.localizedDescription delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
            [alertView show];
        }
    } else {
        NSDictionary *formValues = self.formController.formValues;
        NSMutableDictionary *customerParameters = [NSMutableDictionary dictionary];
        customerParameters[@"custid"] = formValues[@"custid"];
        customerParameters[@"billname"] = formValues[@"billname"];
        customerParameters[@"email"] = formValues[@"email"];
        if (self.customer) customerParameters[@"id"] = self.customer.customer_id;
        NSMutableDictionary *shippingAddressParameters = [NSMutableDictionary dictionary];
        shippingAddressParameters[@"line1"] = formValues[@"line1"];
        shippingAddressParameters[@"line2"] = formValues[@"line2"];
        shippingAddressParameters[@"city"] = formValues[@"city"];
        shippingAddressParameters[@"state"] = formValues[@"state"];
        shippingAddressParameters[@"zip"] = formValues[@"zip"];
        shippingAddressParameters[@"country"] = formValues[@"country"];

        if (![[NSNull null] isEqual:shippingAddressParameters[@"line1"]]) {
            customerParameters[@"shipping_address"] = shippingAddressParameters;
        }
        NSDictionary *parameters = @{ @"customer" : customerParameters};

        [CustomerManager syncNewCustomer:parameters
                             attachHudTo:self.view
                               onSuccess:^(Customer *customer) {
                                   [[NSNotificationCenter defaultCenter] postNotificationName:CustomerCreatedNotification object:customer];
                                   [self back:sender];
                                   [CIAlertView alertSyncEvent:@"Customer Created"];
                               }
                               onFailure:nil];
    }
}

@end