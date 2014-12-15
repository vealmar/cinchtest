//
// Created by septerr on 8/21/13.
// Copyright (c) 2013 Convention Innovations. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "AnOrder.h"
#import "ALineItem.h"
#import "Order.h"
#import "config.h"
#import "Cart.h"
#import "NilUtil.h"
#import "CIProductViewControllerHelper.h"
#import "DateUtil.h"
#import "CoreDataUtil.h"

@implementation AnOrder {

}

- (id)initWithJSONFromServer:(NSDictionary *)JSON {
    self = [super init];
    if (self) {
        self.customerId = (NSNumber *) [NilUtil nilOrObject:[JSON objectForKey:@"customer_id"]];
        self.orderId = (NSNumber *) [NilUtil nilOrObject:[JSON objectForKey:@"id"]];
        self.notes = (NSString *) [NilUtil nilOrObject:[JSON objectForKey:@"notes"]];
        self.voucherTotal = (NSNumber *) [NilUtil nilOrObject:[JSON objectForKey:@"voucherTotal"]];
        self.shipNotes = (NSString *) [NilUtil nilOrObject:[JSON objectForKey:@"ship_notes"]];
        self.total = (NSNumber *) [NilUtil nilOrObject:[JSON objectForKey:@"total"]];
        self.status = (NSString *) [NilUtil nilOrObject:[JSON objectForKey:@"status"]];
        self.authorized = (NSString *) [NilUtil nilOrObject:[JSON objectForKey:@"authorized"]];
        NSNumber *shipFlagInt = (NSNumber *) [NilUtil nilOrObject:[JSON objectForKey:@"ship_flag"]];
        self.shipFlag = (BOOL *) (shipFlagInt && [shipFlagInt intValue] == 1);//boolean
        self.cancelByDays = (NSNumber *) [NilUtil nilOrObject:[JSON objectForKey:@"cancel_by_days"]];
        self.poNumber = (NSString *) [NilUtil nilOrObject:[JSON objectForKey:@"po_number"]];
        self.paymentTerms = (NSString *) [NilUtil nilOrObject:[JSON objectForKey:@"payment_terms"]];
        self.shipDates = [DateUtil convertApiDateArrayToNSDateArray:[NilUtil objectOrEmptyArray:[JSON objectForKey:@"ship_dates"]]];
        self.customFields = [JSON objectForKey:@"custom_fields"];
        self.customer = (NSDictionary *) [NilUtil nilOrObject:[JSON objectForKey:@"customer"]];
        self.warnings = (NSArray *) [NilUtil nilOrObject:[JSON objectForKey:@"warnings"]];
        self.errors = (NSArray *) [NilUtil nilOrObject:[JSON objectForKey:@"errors"]];
        NSMutableArray *lineItems = [[NSMutableArray alloc] init];
        NSArray *jsonLIneItems = (NSArray *) [NilUtil nilOrObject:[JSON objectForKey:@"line_items"]];
        if (jsonLIneItems != nil) {
            for (NSDictionary *jsonItem in (NSArray *) [JSON objectForKey:@"line_items"]) {
                [lineItems addObject:[[ALineItem alloc] initWithJsonFromServer:jsonItem]];
            }
        }
        self.lineItems = lineItems;
    }
    return self;
}

- (id)initWithCoreData:(Order *)order {
    self = [super init];
    if (self) {
        self.customerId = [NSNumber numberWithInt:[order.customer_id intValue]];
        self.orderId = order.orderId;
        self.notes = @"";
        self.voucherTotal = [NSNumber numberWithInt:0]; //todo: voucher total not stored or evaluated for core data?
        self.shipNotes = @"";
        self.status = order.status;
        NSMutableDictionary *customer = [[NSMutableDictionary alloc] init];
        [customer setObject:order.billname forKey:kBillName];
        [customer setObject:[NSString stringWithFormat:@"%@", order.custid] forKey:kCustID];
        [customer setObject:[NSString stringWithFormat:@"%@", order.customer_id] forKey:@"id"];
        self.customer = customer;
        self.authorized = @"";
        self.cancelByDays = order.cancelByDays;
        self.poNumber = order.po_number;
        self.paymentTerms = order.payment_terms;
        self.shipDates = [NilUtil objectOrEmptyArray:order.ship_dates];
        self.customFields = order.customFields;
        self.coreDataOrder = order;
        int itemTotal = 0;
        int voucherTotal = 0;
        for (Cart *cart in order.carts) {
            int itemQty = [CIProductViewControllerHelper getQuantity:cart.editableQty];
            itemTotal += itemQty * [cart.editablePrice intValue] * cart.shipdates.count;
            if (cart.product && [CIProductViewControllerHelper itemIsVoucher:cart.product]) {
                voucherTotal += itemQty * [cart.editableVoucher intValue] * cart.shipdates.count;
            }
        };
        self.total = @(itemTotal / 100.0);
    }
    return self;
}

- (NSString *)getCustomerDisplayName {
    return [NSString stringWithFormat:@"%@ - %@", ([self.customer objectForKey:kBillName] == nil? @"(Unknown)" : [self.customer objectForKey:kBillName]), ([self.customer objectForKey:kCustID] == nil? @"(Unknown)" : [self.customer objectForKey:kCustID])];
}

- (float)adjustedTotal {
    CoreDataUtil *coreDataUtil = [CoreDataUtil sharedManager];
    NSMutableDictionary *dateProducts = [NSMutableDictionary dictionary];
    NSMutableArray *orderedDates = [NSMutableArray array];

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];

    [dateFormatter setLocale:enUSPOSIXLocale];
    [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'.000Z'"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];

    NSDate *earliestDate = nil;

    for (ALineItem *line in self.lineItems) {
        Product *product = (Product *) [coreDataUtil fetchObject:@"Product" withPredicate:[NSPredicate predicateWithFormat:@"(productId == %@)", line.productId]];

        NSDictionary *quantities = [NSJSONSerialization JSONObjectWithData:[line.quantity dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
        if ([quantities isKindOfClass:[NSDictionary class]]) {
            for (NSString *d in quantities.allKeys) {
                NSDate *date = [dateFormatter dateFromString:d];
                int quantity = [quantities[d] intValue];

                if (earliestDate == nil) {
                    earliestDate = date;
                } else {
                    earliestDate = [earliestDate earlierDate:date];
                }

                if(quantity) {
                    NSMutableArray *products = [dateProducts objectForKey:date];
                    if (!products) {
                        products = [NSMutableArray array];
                        dateProducts[date] = products;
                        [orderedDates addObject:date];
                    }
                    [products addObject:@[product, @(quantity)]];
                }
            }
        }
    }

    float grossTotal = 0;
    for (int i = 0; i < orderedDates.count; i++) {
        NSDate *date = (NSDate*)[orderedDates objectAtIndex:i];

        float total = 0;
        for (NSArray *pair in dateProducts[date]) {
            Product *product = pair[0];
            int quantity = [pair[1] intValue];

            if (date == earliestDate) {
                total += quantity * [product.showprc intValue];
            } else {
                total += quantity * [product.regprc intValue];
            }
        }
        grossTotal += total;
    }

    return grossTotal / 100.0;
}

@end