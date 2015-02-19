//
// Created by David Jafari on 2/16/15.
// Copyright (c) 2015 Urban Coding. All rights reserved.
//

#import "CISelectPricingTierViewController.h"
#import "Order.h"
#import "ShowConfigurations.h"
#import "LineItem+Extensions.h"
#import "Product.h"
#import "NotificationConstants.h"
#import "Product+Extensions.h"

@interface CISelectPricingTierViewController ()

@property Order *order;
@property XLFormRowDescriptor *pricingTierSelectorRow;

@end

@implementation CISelectPricingTierViewController

-(id)init {
    self = [super initWithTitle:@"Select Pricing Tier"];
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
    self.pricingTierSelectorRow = [XLFormRowDescriptor formRowDescriptorWithTag:@"pricingTierIndex"
                                                                 rowType:XLFormRowDescriptorTypeSelectorPickerViewInline
                                                                   title:@"Pricing Tier"];

    ShowConfigurations *configurations = [ShowConfigurations instance];
    NSMutableArray *tiers = [NSMutableArray array];
    for (int i = 0; i < configurations.priceTiersAvailable; i++) {
        [tiers addObject:[XLFormOptionsObject formOptionsObjectWithValue:@(i) displayText:[configurations priceTierLabelAt:i]]];
    }
    self.pricingTierSelectorRow.selectorOptions = [NSArray arrayWithArray:tiers];
    self.pricingTierSelectorRow.required = YES;
    [self setDefaultStyle:self.pricingTierSelectorRow];
    [section addFormRow:self.pricingTierSelectorRow];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if (self.order.pricingTierIndex) {
        self.pricingTierSelectorRow.value = [XLFormOptionsObject formOptionsObjectWithValue:self.order.pricingTierIndex displayText:[[ShowConfigurations instance] priceTierLabelAt:self.order.pricingTierIndex.intValue]];
    } else {
        self.pricingTierSelectorRow.value = self.pricingTierSelectorRow.selectorOptions.firstObject;
    }

    [self.formController.tableView reloadData];
}

- (void)submit:(id)sender {
    XLFormOptionsObject *value = self.pricingTierSelectorRow.value;
    if (![self.order.pricingTierIndex isEqualToNumber:value.formValue]) {
        self.order.pricingTierIndex = value.formValue;
        for (LineItem *lineItem in self.order.lineItems) {
            if (lineItem.product && [lineItem.product.prices containsObject:lineItem.price]) {
                lineItem.price = [lineItem.product priceAtTier:self.order.pricingTierIndex.intValue];
            }
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:OrderPriceTierChangedNotification object:value.formValue];
    }
    //@todo notify of changed value if necessary, update order
    [self back:sender];
}


@end