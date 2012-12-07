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

- (void)addCartsObject:(Cart *)value {
    [self willChangeValueForKey:@"carts"];
    NSMutableOrderedSet *_carts = [NSMutableOrderedSet orderedSetWithOrderedSet:self.carts];
    [_carts addObject:value];
    self.carts = _carts;
    [self didChangeValueForKey:@"carts"];
}

@end
