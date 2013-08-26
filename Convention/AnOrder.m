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
#import "JSONKit.h"
#import "Cart.h"
#import "NilUtil.h"


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
        self.customer = (NSDictionary *) [NilUtil nilOrObject:[JSON objectForKey:@"customer"]];
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
        self.orderId = [NSNumber numberWithInt:order.orderId];
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
        self.coreDataOrder = order;
        // TODO: setup line items
        double itemTotal = 0.f;
        for (int i = 0; i < order.carts.count; i++) {
            Cart *lineItem = (Cart *) [order.carts objectAtIndex:(NSUInteger) i];
            __autoreleasing NSError *err = nil;
            NSMutableDictionary *dict = [lineItem.editableQty objectFromJSONStringWithParseOptions:JKParseOptionNone error:&err];
            double itemQty = 0;
            if (err) { //SG: if the item quantity is not a json/hash like string.
                itemQty = [lineItem.editableQty doubleValue];
            } else { //SG: if item quantity is a json/hash like string i.e. there is more than one quantity for this item. This will happen when the customer has multiple stores.
                for (NSString *key in dict.allKeys) {
                    itemQty += [[dict objectForKey:key] doubleValue];
                }
            }
            itemTotal += itemQty * lineItem.editablePrice; //todo: is this correct? doesn't account for ship dates.
        };
        self.total = [NSNumber numberWithDouble:itemTotal];
    }
    return self;
}

@end