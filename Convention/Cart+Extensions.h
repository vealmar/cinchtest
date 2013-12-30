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

- (id)initWithQuantity:(NSString *)quantity price:(NSNumber *)price voucherPrice:(NSNumber *)voucherPrice category:(NSString *)category shipDates:(NSArray *)shipDates
             productId:(NSNumber *)productId context:(NSManagedObjectContext *)context;

- (id)initWithProduct:(NSDictionary *)product context:(NSManagedObjectContext *)context;

- (NSDictionary *)asJsonReqParameter;

@end
