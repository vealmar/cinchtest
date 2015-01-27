//
// Created by David Jafari on 12/26/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <Underscore.m/Underscore.h>
#import "OrderSubtotalsByDate.h"
#import "NilUtil.h"

@interface OrderSubtotalsByDate ()

@property NSMutableDictionary *subtotalsByDate;
@property NSMutableOrderedSet *shipDatesAggregation;

@end

@implementation OrderSubtotalsByDate

- (id)init {
    self = [super init];
    if (self) {
        self.shipDatesAggregation = [NSMutableOrderedSet orderedSet];
        self.subtotalsByDate = [NSMutableDictionary dictionary];
    }
    return self;
}

- (id)addTotal:(double)total forDate:(NSDate *)shipDate {
    [self.shipDatesAggregation addObject:shipDate];

    NSNumber *existingTotal = (NSNumber *) [NilUtil objectOrDefault:self.subtotalsByDate[shipDate] defaultObject:@0.0];
    self.subtotalsByDate[shipDate] = @(total + [existingTotal doubleValue]);

    return self;
}

- (NSNumber *)totalOn:(NSDate *)shipDate {
    return self.subtotalsByDate[shipDate];
}

- (void)each:(void (^)(NSDate *shipDate, NSNumber *totalOnShipDate))block {
    __weak OrderSubtotalsByDate *weakSelf = self;
    for (NSDate *shipDate in [self.shipDatesAggregation.array sortedArrayUsingSelector:@selector(compare:)]) {
        NSNumber *subtotal = [weakSelf totalOn:shipDate];
        if ([subtotal doubleValue] > 0.0) block(shipDate, subtotal);
    };
}

- (BOOL)hasSubtotals {
    __weak OrderSubtotalsByDate *weakSelf = self;
    for (NSDate *shipDate in [self.shipDatesAggregation.array sortedArrayUsingSelector:@selector(compare:)]) {
        NSNumber *subtotal = [weakSelf totalOn:shipDate];
        if ([subtotal doubleValue] > 0.0) return YES;
    };
    return NO;
}

@end