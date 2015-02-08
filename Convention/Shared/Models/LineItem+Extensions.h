//
// Created by David Jafari on 12/24/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LineItem.h"

@class Product;

@interface LineItem (Extensions)

@property (readonly) int totalQuantity;

//view helpers
@property (readonly) NSNumber *totalQuantityNumber;
@property (readonly) NSString *label;
@property (readonly) NSNumber *shipDatesCount;
@property (readonly) NSNumber *subtotalNumber;

- (id)initWithProduct:(Product *)product context:(NSManagedObjectContext *)context;

- (BOOL)isStandard;

- (BOOL)isDiscount;

- (BOOL)isWriteIn;

- (double)subtotal;

- (double)subtotalUsing:(NSString *)quantityValue shipDatesCount:(int)shipDatesCount;

#pragma mark - Quantities

- (int)getQuantityForShipDate:(NSDate *)date;

- (void)setQuantity:(int)quantity forShipDate:(NSDate *)date;

- (void)setQuantity:(NSString *)quantity;

#pragma mark - Syncing

- (id)initWithJsonFromServer:(NSDictionary *)json inContext:(NSManagedObjectContext *)managedObjectContext;

- (NSDictionary *)asJsonReqParameter;

@end