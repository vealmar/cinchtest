//
//  Order+Extensions.h
//  Convention
//
//  Created by Kerry Sanders on 11/13/12.
//  Copyright (c) 2012 MotionMobs. All rights reserved.
//

#import "Order.h"
#import "Cart.h"

@interface Order (Extensions)

- (void)addCartsObject:(NSManagedObject *)value;

@end
