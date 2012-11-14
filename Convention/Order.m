//
//  Order.m
//  Convention
//
//  Created by Kerry Sanders on 11/13/12.
//  Copyright (c) 2012 MotionMobs. All rights reserved.
//

#import "Order.h"


@implementation Order

@dynamic customer_id;
@dynamic multiStore;
@dynamic created_at;
@dynamic partial;
@dynamic custid;
@dynamic carts;

- (void)addCartsObject:(NSManagedObject *)value {
    [self willChangeValueForKey:@"carts"];
    NSMutableOrderedSet *_carts = [NSMutableOrderedSet orderedSetWithOrderedSet:self.carts];
    [_carts addObject:value];
    self.carts = _carts;
    [self didChangeValueForKey:@"carts"];
}

@end
