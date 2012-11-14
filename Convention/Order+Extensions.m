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
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"id=%@", [NSNumber numberWithInt:productId]];
    Cart *cart = (Cart*)[[CoreDataUtil sharedManager] fetchObject:@"Cart" withPredicate:predicate];
    return cart;
}

@end
