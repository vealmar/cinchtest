//
//  Order.h
//  Convention
//
//  Created by septerr on 12/27/13.
//  Copyright (c) 2013 Convention Innovations. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "EditableEntity.h"

@class Cart;

@interface Order : EditableEntity

@property(nonatomic, retain) NSString *authorized;
@property(nonatomic, retain) NSString *billname;
@property(nonatomic, retain) NSDate *created_at;
@property(nonatomic, retain) NSString *custid;
@property(nonatomic, retain) NSString *customer_id;
@property(nonatomic, retain) NSString *notes;
@property(nonatomic, retain) NSNumber *orderId;
@property(nonatomic, retain) NSNumber *print;
@property(nonatomic, retain) NSNumber *printer;
@property(nonatomic, retain) NSNumber *ship_flag;
@property(nonatomic, retain) NSString *ship_notes;
@property(nonatomic, retain) NSString *status;
@property(nonatomic, retain) NSString *vendorGroup;
@property(nonatomic, retain) NSString *vendorGroupId;
@property(nonatomic, retain) NSOrderedSet *carts;
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
@end
