//
// Created by David Jafari on 12/24/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <Underscore.m/Underscore.h>
#import <JSONKit/JSONKit.h>
#import "LineItem+Extensions.h"
#import "NilUtil.h"
#import "Product.h"
#import "DateUtil.h"
#import "NSDate+Boost.h"
#import "config.h"
#import "ShowConfigurations.h"
#import "NotificationConstants.h"
#import "NumberUtil.h"
#import "DateRange.h"
#import "CoreDataUtil.h"
#import "Error+Extensions.h"
#import "Error.h"

@implementation LineItem (Extensions)

- (id)initWithProduct:(Product *)product context:(NSManagedObjectContext *)context {
    self = [self initWithEntity:[NSEntityDescription entityForName:@"LineItem" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
    if (self) {
        self.category = @"standard";
        self.product = product;
        self.productId = product.productId;
        self.description1 = product.descr;
        self.description2 = product.descr2;
        self.price = product.showprc;
        self.quantity = @"0";
        self.shipDates = [NSOrderedSet orderedSet];
    }
    return self;
}

- (NSOrderedSet *)shipDates {
    id primitiveValue = [super primitiveValueForKey:@"shipDates"];
    
    if (!primitiveValue) {
//        [self willChangeValueForKey:@"shipDates"]; // not sure if we should trigger hasnontransientchanges here
        [super setPrimitiveValue:[NSOrderedSet orderedSet] forKey:@"shipDates"];
//        [self didChangeValueForKey:@"shipDates"];
    }
    
    return [super primitiveValueForKey:@"shipDates"];
}

- (NSString *)label {
    if (self.isDiscount) {
        return @"Discount";
    } else if (self.productId && self.product) {
        return [NSString stringWithFormat:@"%@", self.product.invtid];
    } else {
        return @"";
    }
}

- (NSNumber *)shipDatesCount {
    return @(self.shipDates.count);
}

- (NSNumber *)subtotalNumber {
    return @(self.subtotal);
}

- (NSNumber *)totalQuantityNumber {
    return @(self.totalQuantity);
}

- (int)totalQuantity {
    return [LineItem totalQuantity:self.quantity];
}

+ (int)totalQuantity:(NSString *)quantityValue {
    id quantities = [quantityValue objectFromJSONString];
    if (quantities == nil) {
        return quantityValue == nil ? 0 : [quantityValue intValue];
    } else if ([quantities isKindOfClass:[NSString class]]) {
        return [quantities intValue];
    } else if ([quantities isKindOfClass:[NSDictionary class]]) {
        NSNumber *total = Underscore.array([((NSDictionary *) quantities) allValues]).reduce([NSNumber numberWithInt:0], ^(NSNumber *memo, NSNumber *obj) {
            return [NSNumber numberWithInt:([obj intValue] + [memo intValue])];
        });
        return [total intValue];
    }
    return 0;
}

- (BOOL)isStandard {
    return self.category && [self.category isEqualToString:@"standard"];
}

- (BOOL)isDiscount {
    return [self.category isEqualToString:@"discount"];
}

- (double)subtotal {
    return [self subtotalUsing:self.quantity shipDatesCount:(self.shipDates.count < 1 ? 1 : self.shipDates.count)];
}

- (double)subtotalUsing:(NSString *)quantityValue shipDatesCount:(int)shipDatesCount {
    ShowConfigurations *configurations = [ShowConfigurations instance];

    if (self.isDiscount) {
        return [self.price doubleValue] * [LineItem totalQuantity:quantityValue];
    } else if (configurations.isOrderShipDatesType) {
        return shipDatesCount * [self.price doubleValue] * [LineItem totalQuantity:quantityValue];
    } else if (configurations.isLineItemShipDatesType && configurations.atOncePricing) {
        if (shipDatesCount > 0) {
            NSArray *fixedShipDates = [ShowConfigurations instance].orderShipDates.fixedDates;
            NSDate *atOnceDate = fixedShipDates ? fixedShipDates.firstObject : nil;

            NSMutableDictionary *quantities = [quantityValue objectFromJSONString];

            double runningTotal = 0.0;

            for (NSDate *shipDate in fixedShipDates) {
                NSString *key = [shipDate formattedDatePattern:@"yyyy-MM-dd'T'HH:mm:ss'.000Z'"];
                int quantityOnDate = [[quantities allKeys] containsObject:key] ? [[quantities valueForKey:key] intValue] : 0;
                if (quantityOnDate > 0) {
                    if (atOnceDate && [atOnceDate isEqualToDate:shipDate]) {
                        runningTotal += [self.product.showprc doubleValue] * quantityOnDate;
                    } else {
                        runningTotal += [self.product.regprc doubleValue] * quantityOnDate;
                    }
                }
            }

            return runningTotal;
        } else {
            return 0;
        }
    } else if (configurations.isLineItemShipDatesType) {
        return [self.price doubleValue] * [LineItem totalQuantity:quantityValue];
    } else {
        return [self.price doubleValue] * [LineItem totalQuantity:quantityValue];
    }
}

#pragma mark - Quantities

- (int)getQuantityForShipDate:(NSDate *)date {
    NSMutableDictionary *quantities = [self.quantity objectFromJSONString];
    NSString *key = [date formattedDatePattern:@"yyyy-MM-dd'T'HH:mm:ss'.000Z'"];
    return [[quantities allKeys] containsObject:key] ? [[quantities valueForKey:key] intValue] : 0;
}

- (void)setQuantity:(int)quantity forShipDate:(NSDate *)date {
    id quantityFromJSON = [self.quantity objectFromJSONString];
    NSMutableDictionary *quantities;
    if (quantityFromJSON && [quantityFromJSON isKindOfClass:[NSDictionary class]]) {
        quantities = [quantityFromJSON mutableCopy];
    } else {
        quantities = [NSMutableDictionary dictionary];
    }
    
    NSString *key = [date formattedDatePattern:@"yyyy-MM-dd'T'HH:mm:ss'.000Z'"];
    [quantities setValue:[NSNumber numberWithInt:quantity] forKey:key];
    if (quantity <= 0) {
        [quantities removeObjectForKey:key];
    }
    if (quantities.count == 0) quantities = nil;
    self.quantity = [quantities JSONString];
    
    NSMutableOrderedSet *tempShipDates = [NSMutableOrderedSet orderedSetWithOrderedSet:self.shipDates];
    BOOL containsDate = [self.shipDates containsObject:date];
    if (quantity > 0 && !containsDate) [tempShipDates addObject:date];
    if (quantity == 0 && containsDate) [tempShipDates removeObject:date];
    self.shipDates = [NSOrderedSet orderedSetWithSet:[tempShipDates set]];
}

- (void)setQuantity:(NSString *)quantity {
    NSString *originalQuantity = self.quantity;
    int originalShipDateCount = self.shipDates.count; // this hasnt been updated yet

    NSString *setQuantity = quantity;
    if (quantity && (quantity.length == 0 || [quantity isEqualToString:@"0"])) {
        setQuantity = nil;
    }

    [self willChangeValueForKey:@"quantity"];
    [super setPrimitiveValue:setQuantity forKey:@"quantity"];
    [self didChangeValueForKey:@"quantity"];
    
    if ((!setQuantity && originalQuantity) || (setQuantity && !originalQuantity) || (setQuantity && originalQuantity && ![setQuantity isEqualToString:originalQuantity])) {
        dispatch_async(dispatch_get_main_queue(), ^{
            @autoreleasepool {
                [[NSNotificationCenter defaultCenter] postNotificationName:LineQuantityChangedNotification object:self userInfo:@{ @"originalQuantity" : (originalQuantity ? originalQuantity : [NSNull null]), @"originalShipDatesCount" : @(originalShipDateCount) }];
            }
        });
    }
}

#pragma mark - Syncing

- (id)initWithJsonFromServer:(NSDictionary *)json inContext:(NSManagedObjectContext *)managedObjectContext {
    self = [super initWithEntity:[NSEntityDescription entityForName:@"LineItem" inManagedObjectContext:managedObjectContext] insertIntoManagedObjectContext:managedObjectContext];
    if (self) {
        [self updateWithJsonFromServer:json withContext:managedObjectContext];
    }
    return self;
}

- (void)updateWithJsonFromServer:(NSDictionary *)json withContext:(NSManagedObjectContext *)managedObjectContext {
    self.lineItemId = (NSNumber *) [NilUtil nilOrObject:json[kID]];
    self.orderId = (NSNumber *) [NilUtil nilOrObject:json[@"order_id"]];
    self.productId = (NSNumber *) [NilUtil nilOrObject:json[@"product_id"]];
    id price = json[@"price"];
    if ([price isKindOfClass:[NSNumber class]]) {
        self.price = price;
    } else {
        self.price = [NumberUtil convertStringToDollars:price];
    }
    
    self.category = (NSString *) [NilUtil nilOrObject:json[@"category"]];
    self.description1 = (NSString *) [NilUtil nilOrObject:json[@"desc"]];
    self.description2 = (NSString *) [NilUtil nilOrObject:json[@"desc2"]];
    self.quantity = (NSString *) [NilUtil nilOrObject:json[@"quantity"]];

    NSArray *shipDatesArray = (NSArray *) [NilUtil nilOrObject:json[@"shipdates"]];
    if (shipDatesArray) self.shipDates = [NSOrderedSet orderedSetWithArray:[DateUtil convertApiDateArrayToNSDateArray:shipDatesArray]];

    BOOL includingErrorsAndWarnings = (BOOL) json[@"including_errors_and_warnings"];
    if (includingErrorsAndWarnings) {
        NSMutableArray *warningsArray = [NSMutableArray array];
        NSMutableArray *errorsArray = [NSMutableArray array];
        
        for (NSString *warning in [NilUtil objectOrEmptyArray:json[@"warnings"]]) {
            Error *lineItemrError = [[Error alloc] initWithMessage:warning andContext:managedObjectContext];
            [warningsArray addObject:lineItemrError];
        }
        for (NSString *error in [NilUtil objectOrEmptyArray:json[@"errors"]]) {
            Error *lineItemrError = [[Error alloc] initWithMessage:error andContext:managedObjectContext];
            [errorsArray addObject:lineItemrError];
        }
        
        self.warnings = [NSSet setWithArray:warningsArray];
        self.errors = [NSSet setWithArray:errorsArray];
    }

    if (self.productId) {
        self.product = [[CoreDataUtil sharedManager] fetchObjectFault:@"Product"
                                                            inContext:managedObjectContext
                                                        withPredicate:[NSPredicate predicateWithFormat:@"productId == %@", [self.productId copy]]];
    }
}

- (NSDictionary *)asJsonReqParameter {
    if (self.totalQuantity > 0) { //only include items that have non-zero quantity specified
        return [NSDictionary dictionaryWithObjectsAndKeys:[self.lineItemId intValue] == 0 ? [NSNull null] : self.lineItemId, kID,
                                                          self.productId, kLineItemProductID,
                                                          [NilUtil objectOrNSNull:self.quantity], kLineItemQuantity,
                                                          [NumberUtil formatDollarAmountWithoutSymbol:self.price], kLineItemPrice,
                                                          [ShowConfigurations instance].shipDates ? self.shipDatesAsStringArray : @[], kLineItemShipDates,
                        nil];
    } else if ([self.lineItemId intValue] != 0) { //if quantity is 0 and item exists on server, tell server to destroy it. if it does not exist on server, don't include it.
        return [NSDictionary dictionaryWithObjectsAndKeys:self.lineItemId, kID, @(1), @"_destroy", nil];
    }
    return nil;
}

#pragma mark - Private

- (NSArray *)shipDatesAsStringArray {
    NSMutableArray *shipDates = [[NSMutableArray alloc] init];
    if ([self.shipDates count] > 0) {
        NSDateFormatter *df = [DateUtil newApiDateFormatter];
        for (NSDate *shipDate in self.shipDates) {
            [shipDates addObject:[df stringFromDate:shipDate]];
        }
    }
    return shipDates;
}

@end