//
//  Cart+Extensions.m
//  Convention
//
//  Created by Kerry Sanders on 12/5/12.
//  Copyright (c) 2012 MotionMobs. All rights reserved.
//

#import "Cart+Extensions.h"

@implementation Cart (Extensions)


- (void)addShipdatesObject:(ShipDate *)value {
    [self willChangeValueForKey:@"shipdates"];
    NSMutableOrderedSet *_shipdates = [NSMutableOrderedSet orderedSetWithOrderedSet:self.shipdates];
    [_shipdates addObject:value];
    self.shipdates = _shipdates;
    [self didChangeValueForKey:@"shipdates"];
}

@end
