//
//  Cart+Extensions.h
//  Convention
//
//  Created by Kerry Sanders on 12/5/12.
//  Copyright (c) 2012 MotionMobs. All rights reserved.
//

#import "Cart.h"

@class ALineItem;

@interface Cart (Extensions)

- (NSArray *)shipDatesAsStringArray;

- (id)initWithLineItem:(ALineItem *)lineItem context:(NSManagedObjectContext *)context;

- (id)initWithQuantity:(NSString *)quantity priceInCents:(NSNumber *)priceInCents voucherPriceInCents:(NSNumber *)voucherPriceInCents category:(NSString *)category shipDates:(NSArray *)lineItemShipDates
             productId:(NSNumber *)productId context:(NSManagedObjectContext *)context;

- (id)initWithProduct:(Product *)product context:(NSManagedObjectContext *)context;

- (NSArray *)shipDatesAsDatesArray;

- (int)getQuantityForShipDate:(NSDate *)date;
- (int)totalQuantity;
- (void)setQuantity:(int)quantity forShipDate:(NSDate *)date;

- (void)setQuantity:(int)quantity;

- (NSDictionary *)asJsonReqParameter;

@end
