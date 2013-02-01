//
//  Cart.h
//  Convention
//
//  Created by Kerry Sanders on 1/21/13.
//  Copyright (c) 2013 MotionMobs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Order, ShipDate;

@interface Cart : NSManagedObject

@property (nonatomic) BOOL adv;
@property (nonatomic) int32_t cartId;
@property (nonatomic, retain) NSString * caseqty;
@property (nonatomic, retain) NSString * category;
@property (nonatomic, retain) NSString * company;
@property (nonatomic, retain) NSString * created_at;
@property (nonatomic, retain) NSString * descr;
@property (nonatomic, retain) NSString * descr2;
@property (nonatomic) BOOL dirship;
@property (nonatomic) float discount;
@property (nonatomic) float editablePrice;
@property (nonatomic, retain) NSString * editableQty;
@property (nonatomic) float editableVoucher;
@property (nonatomic) int32_t idx;
@property (nonatomic) int32_t import_id;
@property (nonatomic, retain) NSString * initial_show;
@property (nonatomic, retain) NSString * invtid;
@property (nonatomic, retain) NSString * linenbr;
@property (nonatomic) BOOL new;
@property (nonatomic) int32_t orderLineItem_id;
@property (nonatomic, retain) NSString * partnbr;
@property (nonatomic, retain) NSString * regprc;
@property (nonatomic, retain) NSString * shipdate1;
@property (nonatomic, retain) NSString * shipdate2;
@property (nonatomic, retain) NSString * showprc;
@property (nonatomic, retain) NSString * unique_product_id;
@property (nonatomic, retain) NSString * uom;
@property (nonatomic, retain) NSString * updated_at;
@property (nonatomic, retain) NSString * vendid;
@property (nonatomic) int32_t vendor_id;
@property (nonatomic, retain) NSString * voucher;
@property (nonatomic, retain) Order *order;
@property (nonatomic, retain) NSOrderedSet *shipdates;
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
