//
// Created by David Jafari on 12/24/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LineItem.h"

@class Product;

@interface LineItem (Extensions)

@property (readonly) int totalQuantity;

- (id)initWithProduct:(Product *)product context:(NSManagedObjectContext *)context;

- (BOOL)isStandard;

- (BOOL)isDiscount;

- (double)subtotal;

#pragma mark - Quantities

- (int)getQuantityForShipDate:(NSDate *)date;

- (void)setQuantity:(int)quantity forShipDate:(NSDate *)date;

- (void)setQuantity:(NSString *)quantity;

#pragma mark - Syncing

- (id)initWithJsonFromServer:(NSDictionary *)json inContext:(NSManagedObjectContext *)managedObjectContext;

- (NSDictionary *)asJsonReqParameter;

@end