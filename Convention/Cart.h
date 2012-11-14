//
//  Cart.h
//  Convention
//
//  Created by Kerry Sanders on 11/13/12.
//  Copyright (c) 2012 MotionMobs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Order, ShipDate;

@interface Cart : NSManagedObject

@property (nonatomic, retain) NSNumber * adv;
@property (nonatomic, retain) NSString * caseqty;
@property (nonatomic, retain) NSString * company;
@property (nonatomic, retain) NSString * created_at;
@property (nonatomic, retain) NSString * descr;
@property (nonatomic, retain) NSNumber * dirship;
@property (nonatomic, retain) NSNumber * discount;
@property (nonatomic, retain) NSNumber * editablePrice;
@property (nonatomic, retain) NSNumber * editableQty;
@property (nonatomic, retain) NSNumber * editableVoucher;
@property (nonatomic, retain) NSNumber * id;
@property (nonatomic, retain) NSNumber * idx;
@property (nonatomic, retain) NSNumber * import_id;
@property (nonatomic, retain) NSString * initial_show;
@property (nonatomic, retain) NSNumber * invtid;
@property (nonatomic, retain) NSString * linenbr;
@property (nonatomic, retain) NSNumber * new;
@property (nonatomic, retain) NSString * partnbr;
@property (nonatomic, retain) NSString * regprc;
@property (nonatomic, retain) NSString * shipdate1;
@property (nonatomic, retain) NSString * shipdate2;
@property (nonatomic, retain) NSString * showprc;
@property (nonatomic, retain) NSString * unique_product_id;
@property (nonatomic, retain) NSString * uom;
@property (nonatomic, retain) NSString * updated_at;
@property (nonatomic, retain) NSNumber * vendid;
@property (nonatomic, retain) NSNumber * vendor_id;
@property (nonatomic, retain) NSString * voucher;
@property (nonatomic, retain) NSOrderedSet *shipdates;
@property (nonatomic, retain) Order *order;
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
