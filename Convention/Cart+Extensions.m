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
#import "CIProductViewControllerHelper.h"
#import "NilUtil.h"
#import "ShowConfigurations.h"
#import "Error.h"
#import "Error+Extensions.h"

@implementation Cart (Extensions)

- (id)initWithLineItem:(ALineItem *)lineItem context:(NSManagedObjectContext *)context {
    self = [self initWithQuantity:lineItem.quantity price:lineItem.price voucherPrice:lineItem.voucherPrice category:lineItem.category shipDates:lineItem.shipDates
                        productId:lineItem.productId context:context];
    self.orderLineItem_id = lineItem.itemId;
    for (NSString *error in [NilUtil objectOrEmptyArray:lineItem.errors]) {
        Error *lineItemError = [[Error alloc] initWithMessage:error andContext:self.managedObjectContext];
        [self addErrorsObject:lineItemError];
    }
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

- (NSDictionary *)asJsonReqParameter {
    BOOL hasQuantity = [[[CIProductViewControllerHelper alloc] init] itemHasQuantity:self.editableQty];
    NSDictionary *proDict;
    if (hasQuantity) { //only include items that have non-zero quantity specified
        return [NSDictionary dictionaryWithObjectsAndKeys:[self.orderLineItem_id intValue] == 0 ? [NSNull null] : self.orderLineItem_id, kID,
                                                          self.cartId, kLineItemProductID,
                                                          [NilUtil objectOrNNull:self.editableQty], kLineItemQuantity,
                                                          @([self.editablePrice intValue] / 100.0), kLineItemPrice,
                                                          @([self.editableVoucher intValue] / 100.0), kLineItemVoucherPrice,
                                                          [ShowConfigurations instance].shipDates ? self.shipDatesAsStringArray : @[], kLineItemShipDates,

                                                          nil];
    } else if ([self.orderLineItem_id intValue] != 0) { //if quantity is 0 and item exists on server, tell server to destroy it. if it does not exist on server, don't include it.
        return [NSDictionary dictionaryWithObjectsAndKeys:self.orderLineItem_id, kID, @(1), @"_destroy", nil];
    }
}


@end
