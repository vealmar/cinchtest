//
// Created by David Jafari on 12/24/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <Underscore.m/Underscore.h>
#import <JSONKit/JSONKit.h>
#import "Order.h"
#import "Order+Extensions.h"
#import "LineItem.h"
#import "Product.h"
#import "Product+Extensions.h"
#import "LineItem+Extensions.h"
#import "OrderManager.h"
#import "NilUtil.h"
#import "config.h"
#import "DateUtil.h"
#import "OrderManager.h"
#import "ShowCustomField.h"
#import "ShowConfigurations.h"
#import "CurrentSession.h"
#import "CoreDataUtil.h"
#import "OrderTotals.h"
#import "OrderSubtotalsByDate.h"
#import "DateRange.h"
#import "Error+Extensions.h"

@implementation Order (Extensions)

+ (id)newOrderForCustomer:(NSDictionary *)customer {
    __block Order *newOrder = nil;

    [[CurrentSession mainQueueContext] performBlockAndWait:^{
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Order" inManagedObjectContext:[CurrentSession mainQueueContext]];
        newOrder = [[Order alloc] initWithEntity:entity insertIntoManagedObjectContext:[CurrentSession mainQueueContext]];
        newOrder.inSync = NO;
        newOrder.status = @"partial";
        newOrder.customerId = customer[kID];
        newOrder.custId = customer[kCustID];
        newOrder.customerName = customer[kBillName];
        newOrder.vendorId = [CurrentSession instance].vendorId;
        newOrder.pricingTierIndex = @([[ShowConfigurations instance] defaultPriceTierIndex]);
        [OrderManager saveOrder:newOrder inContext:[CurrentSession mainQueueContext]];
    }];

    return newOrder;
}

- (BOOL)isPartial {
    return [self.status isEqualToString:@"partial"];
}

- (BOOL)isPending {
    return [self.status isEqualToString:@"pending"];
}

- (BOOL)isComplete{
    return [self.status isEqualToString:@"complete"];
}

- (BOOL)isSubmitted{
    return [self.status isEqualToString:@"submitted"];
}

- (BOOL)hasNontransientChanges {
    @try {
        int maxLength = 0;
        NSArray *changedFields = self.changedValues.allKeys;
        if ([changedFields containsObject:@"grossTotal"]) maxLength++;
        if ([changedFields containsObject:@"discountTotal"]) maxLength++;
        if ([changedFields containsObject:@"voucherTotal"]) maxLength++;
        
        BOOL nontransientOrderChanges = changedFields.count > maxLength;
        
        BOOL hasLineChanges = Underscore.array(self.lineItems.allObjects).any(^BOOL(LineItem *lineItem) {
            return lineItem.hasChanges;
        });
        
        return (self.hasChanges && nontransientOrderChanges) || hasLineChanges;
    }
    @catch (NSException *exception) {
        if ([exception description]) NSLog(@"%@", [exception description]);
        return false;
    }
}

- (NSString *)getCustomerDisplayName {
    return [NSString stringWithFormat:@"%@ - %@", (self.customerName == nil ? @"(Unknown)" : self.customerName), (self.custId == nil? @"(Unknown)" : self.custId)];
}

- (OrderTotals *)calculateTotals {
    if (self.grossTotal && !self.hasNontransientChanges) {
        return [[OrderTotals alloc] initWithOrder:self];
    } else {
        __block double grossTotal = 0;
        __block double discountTotal = 0;

        for (LineItem *lineItem in self.lineItems) {
            if (lineItem.isDiscount) {
                discountTotal += [lineItem subtotal];
            } else {
                grossTotal += [lineItem subtotal];
            }
        };

        OrderTotals *totals = [[OrderTotals alloc] initWithGrossTotal:grossTotal discountTotal:discountTotal];
        self.grossTotal = totals.grossTotal;
        self.discountTotal = totals.discountTotal;
        self.voucherTotal = totals.voucherTotal;
        return totals;
    }
}

- (OrderSubtotalsByDate *)calculateShipDateSubtotals {
    OrderSubtotalsByDate *subtotals = [[OrderSubtotalsByDate alloc] init];
    if (![ShowConfigurations instance].shipDates) return subtotals;

    if ([ShowConfigurations instance].isOrderShipDatesType) {
        Underscore.array(self.shipDates).each(^(NSDate *date) {
            for (LineItem *lineItem in self.lineItems) {
                [subtotals addTotal:[lineItem.price doubleValue] * [lineItem.quantity intValue] forDate:date];
            };
    });
    } else if ([ShowConfigurations instance].isLineItemShipDatesType) {
        NSArray *fixedShipDates = [ShowConfigurations instance].orderShipDates.fixedDates;

        for (LineItem *lineItem in self.lineItems) {
            NSDictionary *quantities = [lineItem.quantity objectFromJSONString];
            Underscore.dict(quantities).each(^(NSString *date, NSNumber *quantity) {
                NSDate *shipDate = [DateUtil convertApiDateTimeToNSDate:date];
                NSNumber *price = lineItem.price;
                if ([ShowConfigurations instance].isAtOncePricing && fixedShipDates.count > 0) {
                    if ([((NSDate *) fixedShipDates.firstObject) isEqualToDate:shipDate]) {
                        price = lineItem.product.showprc;
                    } else {
                        price = lineItem.product.regprc;
                    }
                }
                
                [subtotals addTotal:[price doubleValue] * [quantity intValue] forDate:shipDate];
            });
        };
    }

    return subtotals;
}

#pragma mark - LineItems

- (NSArray *)productIds {
    NSMutableArray *productIds = [[NSMutableArray alloc] initWithCapacity:self.lineItems.count];
    for (LineItem *lineItem in self.lineItems) {
        [productIds addObject:lineItem.productId];
    }
    return [NSArray arrayWithArray:productIds];
}

- (NSArray *)discountLineItemIds {
    NSMutableArray *discountLineItemIds = [[NSMutableArray alloc] initWithCapacity:self.lineItems.count];
    for (LineItem *lineItem in self.lineItems) {
        if (lineItem.isDiscount) {
            [discountLineItemIds addObject:lineItem.lineItemId];
        }
    }
    return [NSArray arrayWithArray:discountLineItemIds];
}

// @todo deprecate?
- (LineItem *)findLineById:(NSNumber *)lineItemId {
    for (LineItem *lineItem in self.lineItems) {
        if ([lineItem.lineItemId intValue] == [lineItemId intValue])
            return lineItem;
    }
    return nil;
}

- (int)countWriteInLines {
    int count = 0;
    for (LineItem *lineItem in self.lineItems) {
        if (lineItem.isWriteIn) count++;
    }
    return count;
}

- (NSArray *)findWriteInLines {
    return [self.lineItems filteredSetUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(LineItem *lineItem, NSDictionary *bindings) {
        return lineItem.isWriteIn;
    }]].allObjects;
}

- (NSArray *)findLinesByProductId:(NSNumber *)productId {
    return [self.lineItems filteredSetUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(LineItem *lineItem, NSDictionary *bindings) {
        return ([lineItem.productId intValue] == [productId intValue] && ![lineItem isDiscount]);
    }]].allObjects;
}

- (LineItem *)createLineForProductId:(NSNumber *)productId context:(NSManagedObjectContext *)context {
    Product *product = (Product *) [[CoreDataUtil sharedManager] fetchObject:@"Product" inContext:context withPredicate:[NSPredicate predicateWithFormat:@"(productId == %@)", productId]];
    LineItem *lineItem = [[LineItem alloc] initWithProduct:product order:self context:context];
    [self addLineItemsObject:lineItem];
    return lineItem;
}

- (void)removeZeroQuantityLines {
    NSMutableSet *lineItemsSet = [NSMutableSet setWithSet:self.lineItems];
    Underscore.array(self.lineItems.allObjects).filter(^BOOL(LineItem *lineItem) {
        return lineItem.totalQuantity <= 0;
    }).each(^(LineItem *lineItem) {
        [lineItemsSet removeObject:lineItem];
    });
    self.lineItems = [NSSet setWithSet:lineItemsSet];
}

#pragma mark - CustomFields

- (NSString *)customFieldValueFor:(ShowCustomField *)showCustomField {
    NSDictionary *customField = Underscore.array(self.customFields).find(^BOOL(NSDictionary *dict) {
        return [showCustomField.ownerType isEqualToString:@"Order"] && [showCustomField.fieldName isEqualToString:[dict objectForKey:kCustomFieldFieldName]];
    });
    if (customField == nil) {
        return nil;
    } else {
        return [customField objectForKey:kCustomFieldValue];
    }
}

- (void)setCustomFieldValueFor:(ShowCustomField *)showCustomField value:(NSString *)value {
    NSDictionary *customField = Underscore.array(self.customFields).find(^BOOL(NSDictionary *dict) {
        return [showCustomField.ownerType isEqualToString:@"Order"] && [showCustomField.fieldName isEqualToString:[dict objectForKey:kCustomFieldFieldName]];
    });
    if (nil == customField) {
        customField = @{ kCustomFieldCustomFieldInfoId : showCustomField.id, kCustomFieldFieldName : showCustomField.fieldName, kCustomFieldValue : value };
    } else {
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:customField];
        dict[kCustomFieldValue] = value;
        customField = dict;
    }

    // remove existing field if it exists in collection
    self.customFields = Underscore.array(self.customFields).filter(^BOOL(NSDictionary *dict) {
        return !([showCustomField.ownerType isEqualToString:@"Order"] && [showCustomField.fieldName isEqualToString:[dict objectForKey:kCustomFieldFieldName]]);
    }).unwrap;
    // add new one
    self.customFields = [self.customFields arrayByAddingObject:customField];
}

#pragma mark - Syncing

- (id)initWithJsonFromServer:(NSDictionary *)JSON insertInto:(NSManagedObjectContext *)managedObjectContext {
    self = [super initWithEntity:[NSEntityDescription entityForName:@"Order" inManagedObjectContext:managedObjectContext] insertIntoManagedObjectContext:managedObjectContext];
    if (self) {
        [self updateWithJsonFromServer:JSON withContext:managedObjectContext];
    }
    return self;
}

- (Order *)updateWithJsonFromServer:(NSDictionary *)JSON withContext:(NSManagedObjectContext *)managedObjectContext {
    self.inSync = YES;
    self.grossTotal = nil;
    self.discountTotal = nil;
    self.voucherTotal = nil;

    self.customerId = (NSNumber *) [NilUtil nilOrObject:[JSON objectForKey:@"customer_id"]];
    self.shippingAddressId = (NSNumber *) [NilUtil nilOrObject:[JSON objectForKey:@"shipping_address_id"]];
    self.billingAddressId = (NSNumber *) [NilUtil nilOrObject:[JSON objectForKey:@"billing_address_id"]];
    self.showId = (NSNumber *) [NilUtil nilOrObject:[JSON objectForKey:@"show_id"]];
    self.vendorId = (NSNumber *) [NilUtil nilOrObject:[JSON objectForKey:@"vendor_id"]];
    self.orderId = (NSNumber *) [NilUtil nilOrObject:[JSON objectForKey:@"id"]];
    self.notes = (NSString *) [NilUtil nilOrObject:[JSON objectForKey:@"notes"]];
    self.status = (NSString *) [NilUtil nilOrObject:[JSON objectForKey:@"status"]];
    self.authorizedBy = (NSString *) [NilUtil nilOrObject:[JSON objectForKey:@"authorized"]];
    NSNumber *shipFlagInt = (NSNumber *) [NilUtil nilOrObject:[JSON objectForKey:@"ship_flag"]];
    self.shipFlag = shipFlagInt && [shipFlagInt intValue] == 1;//boolean
    self.purchaseOrderNumber = (NSString *) [NilUtil nilOrObject:[JSON objectForKey:@"po_number"]];
    self.shipDates = [DateUtil convertApiDateArrayToNSDateArray:[NilUtil objectOrEmptyArray:[JSON objectForKey:@"ship_dates"]]];
    self.customFields = [JSON objectForKey:@"custom_fields"];
    self.pricingTierIndex = (NSNumber *) [NilUtil objectOrDefault:[JSON objectForKey:@"pricing_tier_index"] defaultObject:@(0)];

    NSString *discountPercentageCopy = (NSString *) [[NilUtil objectOrDefault:JSON[@"discount_percentage"] defaultObject:@"0"] copy];
    self.discountPercentage = @(discountPercentageCopy.doubleValue);
    
    if (JSON[@"updated_at"]) {
        NSString *updatedAtStringCopy = [JSON[@"updated_at"] copy];
        self.updatedAt = [DateUtil convertApiDateTimeToNSDate:updatedAtStringCopy];
        if (!self.updatedAt) self.updatedAt = [DateUtil convertPsqlDateTimeToNSDate:updatedAtStringCopy];
    } else {
        self.updatedAt = nil;
    }

    NSDictionary *customerDictionary = (NSDictionary *) [NilUtil nilOrObject:[JSON objectForKey:@"customer"]];
    if (customerDictionary) {
        self.customerId = ([customerDictionary objectForKey:kCustID] == nil? [NSNumber numberWithInt:0] : [customerDictionary objectForKey:kID]);
        self.custId = ([customerDictionary objectForKey:kCustID] == nil? @"(Unknown)" : [customerDictionary objectForKey:kCustID]);
        self.customerName = ([customerDictionary objectForKey:kBillName] == nil? @"(Unknown)" : [customerDictionary objectForKey:kBillName]);
    } else {
        self.customerId = (NSNumber *) [NilUtil nilOrObject:JSON[@"customer_id"]];
        self.custId = (NSString *) [NilUtil nilOrObject:JSON[kCustID]];
        if (!self.custId) self.custId = @"(Unknown)";
        self.customerName = (NSString *) [NilUtil nilOrObject:JSON[kBillName]];
        if (!self.customerName) self.customerName = @"(Unknown)";
    }
    

    BOOL includingErrorsAndWarnings = (BOOL) JSON[@"including_errors_and_warnings"];
    if (includingErrorsAndWarnings) {
        NSMutableArray *warningsArray = [NSMutableArray array];
        NSMutableArray *errorsArray = [NSMutableArray array];

        for (NSString *warning in [NilUtil objectOrEmptyArray:JSON[@"warnings"]]) {
            Error *lineItemrError = [[Error alloc] initWithMessage:warning andContext:managedObjectContext];
            [warningsArray addObject:lineItemrError];
        }
        for (NSString *error in [NilUtil objectOrEmptyArray:JSON[@"errors"]]) {
            Error *lineItemrError = [[Error alloc] initWithMessage:error andContext:managedObjectContext];
            [errorsArray addObject:lineItemrError];
        }

        self.warnings = [NSSet setWithArray:warningsArray];
        self.errors = [NSSet setWithArray:errorsArray];
    }

    NSMutableSet *lineItems = [[NSMutableSet alloc] init];
    NSArray *jsonLineItems = (NSArray *) [NilUtil nilOrObject:JSON[@"line_items"]];
    if (jsonLineItems != nil) {
        for (NSDictionary *jsonItem in jsonLineItems) {
            [lineItems addObject:[[LineItem alloc] initWithJsonFromServer:jsonItem inContext:managedObjectContext]];
        }
    }
    self.lineItems = [NSSet setWithSet:lineItems];

    return self;
}

- (NSDictionary *)asJsonReqParameter {
    NSArray *lineItems = Underscore.array(self.lineItems.allObjects).filter(^BOOL(LineItem *lineItem) {
        return lineItem.isStandard;
    }).map(^id(LineItem *lineItem) {
        return [lineItem asJsonReqParameter];
    }).unwrap;

    NSDictionary *newOrder = Underscore.dict([self asJsonReqParameterWithoutLines][kOrder]).extend(@{ kOrderItems : [NSArray arrayWithArray:lineItems] }).unwrap;
    return @{kOrder : newOrder};
}
    
- (NSDictionary *)asJsonReqParameterWithoutLines {
    NSDictionary *newOrder = @{
            kOrderCustomerID : [NilUtil objectOrNSNull:self.customerId],
            kNotes : [NilUtil objectOrNSNull:self.notes],
            kAuthorizedBy : [NilUtil objectOrNSNull:self.authorizedBy],
            kOrderStatus : [NilUtil objectOrNSNull:self.status],
            kOrderPricingTierIndex: self.pricingTierIndex,
            kOrderDiscountPercentage: self.discountPercentage,
            kOrderPoNumber : [NilUtil objectOrNSNull:self.purchaseOrderNumber],
            kOrderShipDates : [NilUtil objectOrNSNull:[DateUtil convertNSDateArrayToApiDateArray:self.shipDates]],
            kCustomFields : [NSArray arrayWithArray:self.customFields]
    };
    return @{kOrder : newOrder};
}

@end