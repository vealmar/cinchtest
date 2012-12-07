//
//  Order.h
//  Convention
//
//  Created by Kerry Sanders on 12/5/12.
//  Copyright (c) 2012 MotionMobs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Cart;

@interface Order : NSManagedObject

@property (nonatomic, retain) NSString * billname;
@property (nonatomic) NSTimeInterval created_at;
@property (nonatomic) int32_t custid;
@property (nonatomic) int32_t customer_id;
@property (nonatomic) BOOL multiStore;
@property (nonatomic, retain) NSString * status;
@property (nonatomic, retain) NSOrderedSet *carts;
@end

@interface Order (CoreDataGeneratedAccessors)

- (void)insertObject:(Cart *)value inCartsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromCartsAtIndex:(NSUInteger)idx;
- (void)insertCarts:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeCartsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInCartsAtIndex:(NSUInteger)idx withObject:(Cart *)value;
- (void)replaceCartsAtIndexes:(NSIndexSet *)indexes withCarts:(NSArray *)values;
- (void)removeCartsObject:(Cart *)value;
- (void)addCarts:(NSOrderedSet *)values;
- (void)removeCarts:(NSOrderedSet *)values;
@end
