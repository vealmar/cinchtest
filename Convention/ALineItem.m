//
// Created by septerr on 8/21/13.
// Copyright (c) 2013 Convention Innovations. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "ALineItem.h"
#import "NilUtil.h"
#import "config.h"
#import "CIProductViewControllerHelper.h"


@implementation ALineItem {

}
- (id)initWithJsonFromServer:(NSDictionary *)json {
    self = [super init];
    if (self) {
        self.voucherPrice = (NSNumber *) [NilUtil nilOrObject:[json objectForKey:@"voucherPrice"]];
        self.orderId = (NSNumber *) [NilUtil nilOrObject:[json objectForKey:@"order_id"]];
        self.desc = (NSString *) [NilUtil nilOrObject:[json objectForKey:@"desc"]];
        self.itemId = (NSNumber *) [NilUtil nilOrObject:[json objectForKey:@"id"]];
        self.category = (NSString *) [NilUtil nilOrObject:[json objectForKey:@"category"]];
        self.desc2 = (NSString *) [NilUtil nilOrObject:[json objectForKey:@"desc2"]];
        self.quantity = (NSString *) [NilUtil nilOrObject:[json objectForKey:@"quantity"]];
        self.shipDates = (NSArray *) [NilUtil nilOrObject:[json objectForKey:@"shipdates"]];
        self.product = (NSDictionary *) [NilUtil nilOrObject:[json objectForKey:@"product"]];
        self.productId = (NSNumber *) [NilUtil nilOrObject:[json objectForKey:@"product_id"]];
        self.price = (NSNumber *) [NilUtil nilOrObject:[json objectForKey:@"price"]];
        self.errors = (NSArray *) [NilUtil nilOrObject:[json objectForKey:@"errors"]];
    }
    return self;
}

- (NSArray *)shipDates {
    return _shipDates ? _shipDates : [[NSArray alloc] init];
}

- (double)getQuantity {
    return [[[CIProductViewControllerHelper alloc] init] getQuantity:self.quantity];
}

- (double)getItemTotal {
    return _shipDates ? [self getQuantity] * [self.price doubleValue] * [self.shipDates count] : [self getQuantity] * [self.price doubleValue];
}

- (double)getVoucherTotal {
    return self.voucherPrice ? [self getQuantity] * [self.voucherPrice doubleValue] * (_shipDates ? [self.shipDates count] : 1) : 0;
}

- (NSNumber *)getInvtId {
    return (NSNumber *) [NilUtil nilOrObject:[self.product objectForKey:kProductInvtid]];
}

@end