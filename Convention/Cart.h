//
//  Cart.h
//  Convention
//
//  Created by septerr on 12/21/13.
//  Copyright (c) 2013 Convention Innovations. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Order, ShipDate;

@interface Cart : NSManagedObject

@property(nonatomic, retain) NSNumber *cartId;
@property(nonatomic, retain) NSNumber *editablePrice;
@property(nonatomic, retain) NSString *editableQty;
@property(nonatomic, retain) NSNumber *editableVoucher;
@property(nonatomic, retain) NSNumber *orderLineItem_id;
@property(nonatomic, retain) Order *order;
@property(nonatomic, retain) NSOrderedSet *shipdates;
@end

@interface Cart (CoreDataGeneratedAccessors)

- (void)insertObject:(ShipDate *)value inShipdatesAtIndex:(NSUInteger)idx;

- (void)removeObjectFromShipdatesAtIndex:(NSUInteger)idx;

- (void)insertShipdates:(NSArray *)value atIndexes:(NSIndexSet *)indexes;

- (void)removeShipdatesAtIndexes:(NSIndexSet *)indexes;

- (void)replaceObjectInShipdatesAtIndex:(NSUInteger)idx withObject:(ShipDate *)value;

- (void)replaceShipdatesAtIndexes:(NSIndexSet *)indexes withShipdates:(NSArray *)values;

- (void)addShipdatesObject:(ShipDate *)value;

- (void)removeShipdatesObject:(ShipDate *)value;

- (void)addShipdates:(NSOrderedSet *)values;

- (void)removeShipdates:(NSOrderedSet *)values;
@end
