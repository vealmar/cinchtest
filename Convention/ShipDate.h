//
//  ShipDate.h
//  Convention
//
//  Created by Kerry Sanders on 12/5/12.
//  Copyright (c) 2012 MotionMobs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Cart;

@interface ShipDate : NSManagedObject

@property (nonatomic) NSTimeInterval shipdate;
@property (nonatomic, retain) Cart *cart;

@end
