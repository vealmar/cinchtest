//
//  Order.h
//  Convention
//
//  Created by Kerry Sanders on 11/13/12.
//  Copyright (c) 2012 MotionMobs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Order : NSManagedObject

@property (nonatomic, retain) NSNumber * customer_id;
@property (nonatomic, retain) NSNumber * multiStore;
@property (nonatomic, retain) NSDate * created_at;
@property (nonatomic, retain) NSNumber * partial;
@property (nonatomic, retain) NSNumber * custid;
@property (nonatomic, retain) NSOrderedSet *carts;

- (void)addCartsObject:(NSManagedObject *)value;

@end

@interface Order (CoreDataGeneratedAccessors)

- (void)insertObject:(NSManagedObject *)value inCartsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromCartsAtIndex:(NSUInteger)idx;
- (void)insertCarts:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeCartsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInCartsAtIndex:(NSUInteger)idx withObject:(NSManagedObject *)value;
- (void)replaceCartsAtIndexes:(NSIndexSet *)indexes withCarts:(NSArray *)values;
- (void)removeCartsObject:(NSManagedObject *)value;
- (void)addCarts:(NSOrderedSet *)values;
- (void)removeCarts:(NSOrderedSet *)values;
@end
