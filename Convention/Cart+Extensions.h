//
//  Cart+Extensions.h
//  Convention
//
//  Created by Kerry Sanders on 12/5/12.
//  Copyright (c) 2012 MotionMobs. All rights reserved.
//

#import "Cart.h"

@interface Cart (Extensions)
- (void)addShipdatesObject:(ShipDate *)value;

- (NSArray *)shipDatesAsStringArray;

- (id)initWithLineItem:(ALineItem *)lineItem forProduct:(NSDictionary *)product context:(NSManagedObjectContext *)context;

- (id)initWithQuantity:(NSString *)quantity price:(NSNumber *)price voucherPrice:(NSNumber *)voucherPrice category:(NSString *)category shipDates:(NSArray *)shipDates
               product:(NSDictionary *)product context:(NSManagedObjectContext *)context;

- (NSNumber *)productId;

- (id)initWithProduct:(NSDictionary *)product context:(NSManagedObjectContext *)context;
@end
