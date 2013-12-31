//
// Created by septerr on 12/31/13.
// Copyright (c) 2013 Convention Innovations. All rights reserved.
//

#import "DiscountLineItem+Extensions.h"
#import "ALineItem.h"
#import "NumberUtil.h"


@implementation DiscountLineItem (Extensions)
- (id)initWithLineItem:(ALineItem *)lineItem context:(NSManagedObjectContext *)context {
    self = [super initWithEntity:[NSEntityDescription entityForName:@"Cart" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
    if (self) {
        self.quantity = [NSNumber numberWithInt:[lineItem.quantity intValue]];
        self.price = [NumberUtil convertDollarsToCents:lineItem.price];
        self.voucherPrice = [NumberUtil convertDollarsToCents:lineItem.voucherPrice];
        self.productId = lineItem.productId;
        self.lineItemId = lineItem.itemId;
    }
    return self;
}
@end