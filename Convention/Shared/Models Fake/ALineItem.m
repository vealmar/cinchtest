//
// Created by septerr on 8/21/13.
// Copyright (c) 2013 Convention Innovations. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <JSONKit/JSONKit.h>
#import <Underscore.m/Underscore.h>
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
        self.warnings = (NSArray *) [NilUtil nilOrObject:[json objectForKey:@"warnings"]];
    }
    return self;
}

- (NSArray *)shipDates {
    return _shipDates ? _shipDates : [[NSArray alloc] init];
}

- (BOOL)isStandard {
    return self.category && [self.category isEqualToString:@"standard"];
}

- (int)totalQuantity {
    id quantities = [self.quantity objectFromJSONString];
    if (self.quantity != nil && quantities == nil) {
        return [self.quantity intValue];
    } else if ([quantities isKindOfClass:[NSString class]]) {
        return [quantities intValue];
    } else if ([quantities isKindOfClass:[NSDictionary class]]) {
        NSNumber* total = Underscore.array([((NSDictionary *)quantities) allValues]).reduce([NSNumber numberWithInt:0], ^(NSNumber *memo, NSString *obj) {
            return [NSNumber numberWithInt:([obj intValue] + [memo intValue])];
        });
        return [total intValue];
    }
    return 0;
}

- (BOOL)isDiscount {
    return [self.category isEqualToString:@"discount"];
}

@end