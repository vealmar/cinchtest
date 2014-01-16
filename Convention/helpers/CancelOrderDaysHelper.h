//
// Created by septerr on 1/15/14.
// Copyright (c) 2014 Convention Innovations. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface CancelOrderDaysHelper : NSObject
- (NSNumber *)numberAtIndex:(NSInteger)index;

- (NSString *)displayStringForIndex:(NSInteger)index;

- (NSArray *)displayStrings;

- (NSUInteger)numberOfOptios;

- (NSUInteger)indexForDays:(NSNumber *)days;
@end