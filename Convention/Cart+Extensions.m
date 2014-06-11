//
//  Cart+Extensions.m
//  Convention
//
//  Created by Kerry Sanders on 12/5/12.
//  Copyright (c) 2012 MotionMobs. All rights reserved.
//

#import <JSONKit/JSONKit.h>
#import <Underscore.m/Underscore.h>
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
#import "Product.h"
#import "Product+Extensions.h"
#import "NSDate+Boost.h"
#import "NotificationConstants.h"

@implementation Cart (Extensions)

- (id)initWithLineItem:(ALineItem *)lineItem context:(NSManagedObjectContext *)context {
    self = [self initWithQuantity:lineItem.quantity priceInCents:[NumberUtil convertDollarsToCents:lineItem.price] voucherPriceInCents:[NumberUtil convertDollarsToCents:lineItem.voucherPrice] category:lineItem.category shipDates:lineItem.shipDates
                        productId:lineItem.productId context:context];
    self.orderLineItem_id = lineItem.itemId;
    for (NSString *error in [NilUtil objectOrEmptyArray:lineItem.errors]) {
        Error *lineItemError = [[Error alloc] initWithMessage:error andContext:self.managedObjectContext];
        [self addErrorsObject:lineItemError];
    }
    return self;
}

- (id)initWithProduct:(Product *)product context:(NSManagedObjectContext *)context {
    self = [self initWithQuantity:@"0" priceInCents:product.showprc voucherPriceInCents:product.voucher category:@"standard" shipDates:@[]
                        productId:product.productId context:context];
    return self;
}


- (id)initWithQuantity:(NSString *)quantity priceInCents:(NSNumber *)priceInCents voucherPriceInCents:(NSNumber *)voucherPriceInCents category:(NSString *)category shipDates:(NSArray *)lineItemShipDates
             productId:(NSNumber *)productId context:(NSManagedObjectContext *)context {
    self = [super initWithEntity:[NSEntityDescription entityForName:@"Cart" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
    if (self) {
        self.product = [Product findProduct:productId];
        self.cartId = productId;
        self.editablePrice = priceInCents;
        self.editableVoucher = voucherPriceInCents;
        self.editableQty = quantity;
        self.shipdates = [[NSMutableOrderedSet alloc] init];
        if (lineItemShipDates && lineItemShipDates.count > 0) {
            for (NSString *jsonDate in lineItemShipDates) {
                NSDate *shipDate = [DateUtil convertYyyymmddToDate:jsonDate];
                [self addShipDate:shipDate];
            }
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

- (NSArray *)shipDatesAsDatesArray {
    NSMutableArray *shipDates = [[NSMutableArray alloc] init];
    if ([self.shipdates count] > 0) {
        for (ShipDate *sd in self.shipdates) {
            [shipDates addObject:sd.shipdate];
        }
    }
    return shipDates;
}

- (int)getQuantityForShipDate:(NSDate *)date {
    NSMutableDictionary *quantities = [self.editableQty objectFromJSONString];
    return [[quantities valueForKey:[date formattedDatePattern:@"yyyy-MM-dd'T'HH:mm:ss'Z'"]] intValue];
}

- (int)totalQuantity {
    id quantities = [self.editableQty objectFromJSONString];
    if (quantities == nil) {
        return self.editableQty == nil ? 0 : [self.editableQty intValue];
    } else if ([quantities isKindOfClass:[NSString class]]) {
        return [quantities intValue];
    } else if ([quantities isKindOfClass:[NSDictionary class]]) {
        NSNumber* total = Underscore.array([((NSDictionary *)quantities) allValues]).reduce([NSNumber numberWithInt:0], ^(NSNumber *memo, NSNumber *obj) {
            return [NSNumber numberWithInt:([obj intValue] + [memo intValue])];
        });
        return [total intValue];
    }
    return 0;
}

- (void)setQuantity:(int)quantity forShipDate:(NSDate *)date {
    NSMutableDictionary *quantities = [[self.editableQty objectFromJSONString] mutableCopy];
    if (quantities == nil) {
        quantities = [NSMutableDictionary dictionary];
    }
    [quantities setValue:[NSNumber numberWithInt:quantity] forKey:[date formattedDatePattern:@"yyyy-MM-dd'T'HH:mm:ss'Z'"]];
    self.editableQty = [quantities JSONString];

    dispatch_async(dispatch_get_main_queue(), ^{
        @autoreleasepool {
            [[NSNotificationCenter defaultCenter] postNotificationName:CartQuantityChangedNotification object:self];
        }
    });

    BOOL containsDate = [self containsShipDate:date];
    if (quantity > 0 && !containsDate) [self addShipDate:date];
    if (quantity == 0 && containsDate) [self removeShipDate:date];
}

- (void)setQuantity:(int)quantity {
    self.editableQty = [NSString stringWithFormat:@"%i", quantity];
    dispatch_async(dispatch_get_main_queue(), ^{
        @autoreleasepool {
            [[NSNotificationCenter defaultCenter] postNotificationName:CartQuantityChangedNotification object:self];
        }
    });
}

- (void)addShipDate:(NSDate *)date {
    ShipDate *coreDataShipDate = [[ShipDate alloc] initWithEntity:[NSEntityDescription entityForName:@"ShipDate" inManagedObjectContext:self.managedObjectContext] insertIntoManagedObjectContext:self.managedObjectContext];
    coreDataShipDate.shipdate = date;
    coreDataShipDate.cart = self;
    [((NSMutableSet *)self.shipdates) addObject:coreDataShipDate];
}

- (void)removeShipDate:(NSDate *)date {
    Underscore.array(self.shipdates).filter(^BOOL(ShipDate *shipDate){
        return [shipDate.shipdate isEqualToDate:date];
    }).each(^(ShipDate *shipDate) {
        [((NSMutableSet *)self.shipdates) removeObject:shipDate];
    });
}

- (BOOL)containsShipDate:(NSDate *)date {
    return Underscore.array(self.shipdates).any(^BOOL(ShipDate *shipDate){
        return [shipDate.shipdate isEqualToDate:date];
    });
}

- (NSDictionary *)asJsonReqParameter {
    BOOL hasQuantity = [[[CIProductViewControllerHelper alloc] init] itemHasQuantity:self.editableQty];
    if (hasQuantity) { //only include items that have non-zero quantity specified
        return [NSDictionary dictionaryWithObjectsAndKeys:[self.orderLineItem_id intValue] == 0 ? [NSNull null] : self.orderLineItem_id, kID,
                                                          self.cartId, kLineItemProductID,
                                                          [NilUtil objectOrNSNull:self.editableQty], kLineItemQuantity,
                                                          @([self.editablePrice intValue] / 100.0), kLineItemPrice,
                                                          @([self.editableVoucher intValue] / 100.0), kLineItemVoucherPrice,
                                                          [ShowConfigurations instance].shipDates ? self.shipDatesAsStringArray : @[], kLineItemShipDates,

                                                          nil];
    } else if ([self.orderLineItem_id intValue] != 0) { //if quantity is 0 and item exists on server, tell server to destroy it. if it does not exist on server, don't include it.
        return [NSDictionary dictionaryWithObjectsAndKeys:self.orderLineItem_id, kID, @(1), @"_destroy", nil];
    }
    return nil;
}


@end
