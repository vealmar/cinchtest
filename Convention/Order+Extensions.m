//
//  Order+Extensions.m
//  Convention
//
//  Created by Kerry Sanders on 11/13/12.
//  Copyright (c) 2012 MotionMobs. All rights reserved.
//

#import "Order+Extensions.h"
#import "CoreDataUtil.h"

@implementation Order (Extensions)

-(Cart *)fetchCart:(int)productId {
    
//    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"id=%@", [NSNumber numberWithInt:productId]];
//    Cart *cart = (Cart *)[[CoreDataUtil sharedManager] fetchObject:@"Cart" withPredicate:predicate];
//    return cart;
    
    Cart *oldCart = nil;
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"order.custid = %@ AND order.customer_id = %@ AND id = %@",
                              self.custid, self.customer_id, productId];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Cart"];
    [request setPredicate:predicate];
    [request setRelationshipKeyPathsForPrefetching:[NSArray arrayWithObject:@"shipdates"]];
    [request setReturnsObjectsAsFaults:NO];
    
    NSError *error;
    NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:request error:&error];
    if (!error && [fetchedObjects count] > 0) {
        oldCart = [fetchedObjects objectAtIndex:0];
    }

    return oldCart;
}

- (void)addCartsObject:(Cart *)value {
    [self willChangeValueForKey:@"carts"];
    NSMutableOrderedSet *_carts = [NSMutableOrderedSet orderedSetWithOrderedSet:self.carts];
    [_carts addObject:value];
    self.carts = _carts;
    [self didChangeValueForKey:@"carts"];
}

@end
