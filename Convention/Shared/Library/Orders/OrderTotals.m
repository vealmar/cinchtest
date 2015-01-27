//
// Created by David Jafari on 12/26/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import "OrderTotals.h"
#import "Order.h"


@implementation OrderTotals

-(id)initWithOrder:(Order *)order {
    self = [self init];
    if (self) {
        self.grossTotal = order.grossTotal;
        self.voucherTotal = order.voucherTotal;
        self.discountTotal = order.discountTotal;
    }
    return self;
}

- (id)initWithGrossTotal:(double)grossTotal discountTotal:(double)discountTotal {
    self = [self init];
    if (self) {
        self.grossTotal = [NSNumber numberWithDouble:grossTotal];
        self.voucherTotal = [NSNumber numberWithDouble:0.0];
        self.discountTotal = [NSNumber numberWithDouble:discountTotal];
    }
    return self;
}

- (NSNumber *)total {
    return [NSNumber numberWithDouble:self.grossTotal.doubleValue + self.discountTotal.doubleValue];
}

@end