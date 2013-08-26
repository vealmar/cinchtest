//
// Created by septerr on 8/21/13.
// Copyright (c) 2013 Convention Innovations. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "ALineItem.h"
#import "Cart.h"
#import "NilUtil.h"


@implementation ALineItem {

}
/*
"voucherPrice" -> "0.5"
"order_id" -> "12820"
"desc" -> "PW COCKTAIL SAUCE 35166"
"id" -> "92489"
"category" -> "standard"
"desc2" -> "<null>"
"quantity" -> "1"
"shipdates" -> count = 1
"product" -> count = 3
"product_id" -> "45079"
"price" -> "11.61"
* */
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
    }
    return self;
}

- (id)initWithCoreData:(Cart *)coreDataLineItem {
    self = [super init];

    if (self) {


    }
    return self;
}
@end