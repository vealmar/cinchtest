//
//  Order.h
//  Convention
//
//  Created by Kerry Sanders on 1/21/13.
//  Copyright (c) 2013 MotionMobs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Cart;
@class AnOrder;

@interface Order : NSManagedObject

@property(nonatomic, retain) NSString *billname;
@property(nonatomic) NSDate *created_at; //the time this core data entry was created. It is used to sort the partial orders when loading them in order view controller.
@property(nonatomic) BOOL multiStore;
@property(nonatomic) int32_t orderId;
@property(nonatomic, retain) NSString *status;
@property(nonatomic) double totalCost;
@property(nonatomic) double totalVoucher;
@property(nonatomic) int32_t vendor_id;
@property(nonatomic, retain) NSString *vendorGroup;
@property(nonatomic, retain) NSString *vendorGroupId;
@property(nonatomic, retain) NSString *customer_id;
@property(nonatomic, retain) NSString *custid;
@property(nonatomic, retain) NSOrderedSet *carts; //SG: these are the line items.
@property(nonatomic, retain) NSString *authorized;
@property(nonatomic, retain) NSString *notes;
@property(nonatomic, retain) NSString *ship_notes;
@property(nonatomic) BOOL ship_flag;

@end

@interface Order (CoreDataGeneratedAccessors)

- (void)insertObject:(Cart *)value inCartsAtIndex:(NSUInteger)idx;

- (void)removeObjectFromCartsAtIndex:(NSUInteger)idx;

- (void)insertCarts:(NSArray *)value atIndexes:(NSIndexSet *)indexes;

- (void)removeCartsAtIndexes:(NSIndexSet *)indexes;

- (void)replaceObjectInCartsAtIndex:(NSUInteger)idx withObject:(Cart *)value;

- (void)replaceCartsAtIndexes:(NSIndexSet *)indexes withCarts:(NSArray *)values;

- (void)addCartsObject:(Cart *)value;

- (void)removeCartsObject:(Cart *)value;

- (void)addCarts:(NSOrderedSet *)values;

- (void)removeCarts:(NSOrderedSet *)values;

- (id)initWithOrder:(AnOrder *)orderFromServer forCustomer:(NSDictionary *)customer vendorId:(NSNumber *)vendorId vendorGroup:(NSString *)vendorGroup andVendorGroupId:(NSString *)vendorGroupId context:(NSManagedObjectContext *)context;
@end
