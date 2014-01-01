//
// Created by septerr on 8/21/13.
// Copyright (c) 2013 Convention Innovations. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "ALineItem.h"
#import "NilUtil.h"


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
        self.productId = (NSNumber *) [NilUtil nilOrObject:[json objectForKey:@"product_id"]];
        self.price = (NSNumber *) [NilUtil nilOrObject:[json objectForKey:@"price"]];
        self.errors = (NSArray *) [NilUtil nilOrObject:[json objectForKey:@"errors"]];
    }
    return self;
}

- (NSArray *)shipDates {
    return _shipDates ? _shipDates : [[NSArray alloc] init];
}

- (BOOL)isStandard {
    return self.category && [self.category isEqualToString:@"standard"];
}
@end