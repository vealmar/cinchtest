//
// Created by David Jafari on 2/16/15.
// Copyright (c) 2015 Urban Coding. All rights reserved.
//

#import "CISelectOrderDiscountViewController.h"
#import "Order.h"
#import "ShowConfigurations.h"
#import "NotificationConstants.h"

@interface CISelectOrderDiscountViewController ()

@property Order *order;
@property XLFormRowDescriptor *percentDiscount;

@end

@implementation CISelectOrderDiscountViewController

-(id)init {
    self = [super initWithTitle:@"Order Discount"];
    if (self) {

    }
    return self;
}

-(void)prepareForDisplay:(Order *)order {
    self.order = order;
}

- (void)addSections:(XLFormDescriptor *)formDescriptor {
    XLFormSectionDescriptor *section = [XLFormSectionDescriptor formSection];
//    section.title = @"";

    [formDescriptor addFormSection:section];
    self.percentDiscount = [XLFormRowDescriptor formRowDescriptorWithTag:@"percentDiscount"
                                                                        rowType:XLFormRowDescriptorTypeDecimal
                                                                          title:@"Percent Discount"];
    [self setDefaultStyle:self.percentDiscount];
    [section addFormRow:self.percentDiscount];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.percentDiscount.value = self.order.discountPercentage;
    [self.formController.tableView reloadData];
}

- (void)submit:(id)sender {
    NSNumber *value = @(((NSString *) self.percentDiscount.value).doubleValue);
    self.percentDiscount.value = value; // remove fluff characters
    if (![self.order.discountPercentage isEqualToNumber:value]) {
        self.order.discountPercentage = value;
//        for (LineItem *lineItem in self.order.lineItems) {
//            if (lineItem.product && [lineItem.product.prices containsObject:lineItem.price]) {
//                lineItem.price = [lineItem.product priceAtTier:self.order.pricingTierIndex.intValue];
//            }
//        }
        [[NSNotificationCenter defaultCenter] postNotificationName:OrderDiscountPercentageChangedNotification object:value];
    }
    //@todo notify of changed value if necessary, update order
    [self back:sender];
}


@end