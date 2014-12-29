//
// Created by David Jafari on 12/26/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Order;

@interface OrderTotals : NSObject

@property NSNumber *grossTotal;
@property NSNumber *discountTotal;
@property NSNumber *voucherTotal;
@property (readonly) NSNumber *total;

- (id)initWithOrder:(Order *)order;
- (id)initWithGrossTotal:(double)grossTotal discountTotal:(double)discountTotal;

@end