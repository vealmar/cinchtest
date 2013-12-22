//
//  Order+Extensions.m
//  Convention
//
//  Created by Kerry Sanders on 11/13/12.
//  Copyright (c) 2012 MotionMobs. All rights reserved.
//

#import "Order+Extensions.h"
#import "config.h"
#import "NumberUtil.h"
#import "Cart+Extensions.h"
#import "AnOrder.h"

@implementation Order (Extensions)

- (id)initWithOrder:(AnOrder *)orderFromServer forCustomer:(NSDictionary *)customer vendorId:(NSNumber *)vendorId vendorGroup:(NSString *)vendorGroup andVendorGroupId:(NSString *)vendorGroupId context:(NSManagedObjectContext *)context {
    self = [super initWithEntity:[NSEntityDescription entityForName:@"Order" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
    if (self) {
        self.billname = [customer objectForKey:kBillName];
        self.customer_id = [orderFromServer.customerId stringValue];
        self.custid = [orderFromServer.customer objectForKey:@"custid"];
        self.multiStore = [[customer objectForKey:kStores] isKindOfClass:[NSArray class]] && [((NSArray *) [customer objectForKey:kStores]) count] > 0;
        self.status = orderFromServer.status;
        self.created_at = [NSDate date]; //the time this core data entry was created. It is later used by ciroderviewcontroller to sort the partial orders.
        self.vendorGroup = vendorGroup;
        self.vendorGroupId = vendorGroupId;
        self.vendor_id = [vendorId intValue];
        self.orderId = [orderFromServer.orderId intValue];
        self.totalCost = [orderFromServer.total doubleValue];
        self.authorized = orderFromServer.authorized;
        self.notes = orderFromServer.notes;
        self.ship_notes = orderFromServer.shipNotes;
        self.ship_flag = (BOOL) orderFromServer.shipFlag;
    }
    return self;
}

- (Cart *)findCartForProductId:(NSNumber *)productId {
    for (Cart *cart in self.carts) {
        if ([cart.cartId intValue] == [productId intValue])
            return cart;
    }
    return nil;
}

- (Cart *)findOrCreateCartForId:(NSDictionary *)product context:(NSManagedObjectContext *)context {
    Cart *cart = [self findCartForProductId:[product objectForKey:kProductId]];
    if (!cart)
        cart = [[Cart alloc] initWithProduct:product context:context];
    [self addCartsObject:cart];
    return cart;
}

- (void)updateItemQuantity:(NSString *)quantity product:(NSDictionary *)product context:(NSManagedObjectContext *)context {
    Cart *cart = [self findOrCreateCartForId:product context:context];
    cart.editableQty = quantity;
    NSError *error = nil;
    if (![context save:&error]) {
        NSString *msg = [NSString stringWithFormat:@"There was an error saving the product item. %@", error.localizedDescription];
        [[[UIAlertView alloc] initWithTitle:@"Error" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
    }
}

- (void)updateItemVoucher:(NSNumber *)voucher product:(NSDictionary *)product context:(NSManagedObjectContext *)context {
    Cart *cart = [self findOrCreateCartForId:product context:context];
    cart.editableVoucher = [NumberUtil convertDollarsToCents:voucher];
    NSError *error = nil;
    if (![context save:&error]) {
        NSString *msg = [NSString stringWithFormat:@"There was an error saving the product item. %@", error.localizedDescription];
        [[[UIAlertView alloc] initWithTitle:@"Error" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
    }
}


- (void)addCartsObject:(Cart *)value {
    [self willChangeValueForKey:@"carts"];
    NSMutableOrderedSet *_carts = [NSMutableOrderedSet orderedSetWithOrderedSet:self.carts];
    [_carts addObject:value];
    self.carts = _carts;
    [self didChangeValueForKey:@"carts"];
}

@end
