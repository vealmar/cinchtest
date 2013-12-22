//
//  Cart+Extensions.m
//  Convention
//
//  Created by Kerry Sanders on 12/5/12.
//  Copyright (c) 2012 MotionMobs. All rights reserved.
//

#import "Cart+Extensions.h"
#import "ALineItem.h"
#import "config.h"
#import "NumberUtil.h"
#import "DateUtil.h"
#import "ShipDate.h"

@implementation Cart (Extensions)

- (id)initWithLineItem:(ALineItem *)lineItem forProduct:(NSDictionary *)product context:(NSManagedObjectContext *)context {
    self = [self initWithQuantity:lineItem.quantity price:lineItem.price voucherPrice:lineItem.voucherPrice category:lineItem.category shipDates:lineItem.shipDates
                        productId:[product objectForKey:kProductId] context:context];
    self.orderLineItem_id = lineItem.itemId;
    return self;
}

- (id)initWithProduct:(NSDictionary *)product context:(NSManagedObjectContext *)context {
    self = [self initWithQuantity:@"0" price:[product objectForKey:kProductShowPrice] voucherPrice:[product objectForKey:kProductVoucher] category:@"standard" shipDates:@[]
                        productId:[product objectForKey:kProductId] context:context];
    return self;
}


- (id)initWithQuantity:(NSString *)quantity price:(NSNumber *)price voucherPrice:(NSNumber *)voucherPrice category:(NSString *)category shipDates:(NSArray *)shipDates
             productId:(NSNumber *)productId context:(NSManagedObjectContext *)context {
    self = [super initWithEntity:[NSEntityDescription entityForName:@"Cart" inManagedObjectContext:context] insertIntoManagedObjectContext:context];

    if (self) {
        self.cartId = productId;
        self.editablePrice = [NumberUtil convertDollarsToCents:price];
        self.editableVoucher = [NumberUtil convertDollarsToCents:voucherPrice];
        self.editableQty = quantity;
        if (shipDates && shipDates.count > 0) {
            NSMutableOrderedSet *coreDataShipDates = [[NSMutableOrderedSet alloc] init];
            for (NSString *jsonDate in shipDates) {
                NSDate *shipDate = [DateUtil convertYyyymmddToDate:jsonDate];
                ShipDate *coreDataShipDate = [[ShipDate alloc] initWithEntity:[NSEntityDescription entityForName:@"ShipDate" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
                coreDataShipDate.shipdate = shipDate;
                [coreDataShipDates addObject:coreDataShipDate];
            }
            self.shipdates = coreDataShipDates;
        }
    }
    return self;
}

- (NSArray *)shipDatesAsStringArray {
    NSMutableArray *shipDates = [[NSMutableArray alloc] init];
    if ([self.shipdates count] > 0) {
        for (ShipDate *sd in self.shipdates) {
            [shipDates addObject:[DateUtil convertDateToYyyymmdd:sd.shipdate]];
        }
    }
    return shipDates;
}

@end
