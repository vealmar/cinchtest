//
// Created by septerr on 1/15/14.
// Copyright (c) 2014 Convention Innovations. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface SegmentedControlHelper : NSObject
- (id)initForCancelByDays;

- (id)initForPaymentTerms;

- (id)valueAtIndex:(NSInteger)index;

- (NSArray *)displayStrings;

- (NSUInteger)indexForValue:(id)value;
@end