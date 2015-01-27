//
// Created by David Jafari on 12/26/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OrderSubtotalsByDate : NSObject

@property (readonly) NSOrderedSet *shipDates; // NSOrderedSet[NSDate]

- (id)addTotal:(double)total forDate:(NSDate *)shipDate;

- (NSNumber *)totalOn:(NSDate *)shipDate;

- (void)each:(void (^)(NSDate *shipDate, NSNumber *totalOnShipDate))block;

- (BOOL)hasSubtotals;

@end