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
#import "NilUtil.h"
#import "CIProductViewControllerHelper.h"
#import "Error.h"
#import "Error+Extensions.h"
#import "ALineItem.h"
#import "Product+Extensions.h"
#import "DiscountLineItem.h"
#import "DiscountLineItem+Extensions.h"

@implementation Order (Extensions)

- (id)initWithOrder:(AnOrder *)orderFromServer forCustomer:(NSDictionary *)customer vendorId:(NSNumber *)vendorId vendorGroup:(NSString *)vendorGroup andVendorGroupId:(NSString *)vendorGroupId context:(NSManagedObjectContext *)context {
    self = [super initWithEntity:[NSEntityDescription entityForName:@"Order" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
    if (self) {
        self.billname = [customer objectForKey:kBillName];
        self.customer_id = [orderFromServer.customerId stringValue];
        self.custid = [orderFromServer.customer objectForKey:@"custid"];
        self.status = orderFromServer.status;
        self.created_at = [NSDate date]; //the time this core data entry was created. It is later used by ciroderviewcontroller to sort the partial orders.
        self.vendorGroupId = vendorGroupId;
        self.orderId = orderFromServer.orderId;
        self.authorized = orderFromServer.authorized;
        self.notes = orderFromServer.notes;
        self.ship_notes = orderFromServer.shipNotes;
        self.ship_flag = [NSNumber numberWithBool:(BOOL) orderFromServer.shipFlag];
        for (NSString *error in [NilUtil objectOrEmptyArray:orderFromServer.errors]) {
            Error *lineItemrError = [[Error alloc] initWithMessage:error andContext:self.managedObjectContext];
            [self addErrorsObject:lineItemrError];
        }
        NSMutableSet *carts = [NSMutableSet set];
        NSMutableSet *discountLineItems = [NSMutableSet set];
        for (ALineItem *lineItem in orderFromServer.lineItems) {
            if ([lineItem.category isEqualToString:@"standard"]) {//if it is a discount item, core data throws error when saving the cart item becasue of nil value in required fields - company, regprc, showprc, invtid.
                Cart *cart = [[Cart alloc] initWithLineItem:lineItem context:self.managedObjectContext];
                [carts addObject:cart];
            } else if ([lineItem.category isEqualToString:@"discount"]) {
                DiscountLineItem *discountLineItem = [[DiscountLineItem alloc] initWithLineItem:lineItem context:context];
                [discountLineItems addObject:discountLineItem];
            }

        }
        self.carts = carts;
        self.discountLineItems = discountLineItems;
    }
    return self;
}

- (DiscountLineItem *)findDiscountForLineItemId:(NSNumber *)lineItemId {
    for (DiscountLineItem *discountLineItem in self.discountLineItems) {
        if ([discountLineItem.lineItemId intValue] == [lineItemId intValue])
            return discountLineItem;
    }
    return nil;
}


- (Cart *)findCartForProductId:(NSNumber *)productId {
    for (Cart *cart in self.carts) {
        if ([cart.cartId intValue] == [productId intValue])
            return cart;
    }
    return nil;
}

- (Cart *)findOrCreateCartForId:(NSNumber *)productId context:(NSManagedObjectContext *)context {
    Cart *cart = [self findCartForProductId:productId];
    if (!cart)
        cart = [[Cart alloc] initWithProduct:[Product findProduct:productId] context:context];
    [self addCartsObject:cart];
    return cart;
}

- (void)updateItemQuantity:(NSString *)quantity productId:(NSNumber *)productId context:(NSManagedObjectContext *)context {
    Cart *cart = [self findOrCreateCartForId:productId context:context];
    cart.editableQty = quantity;
    NSError *error = nil;
    if (![context save:&error]) {
        NSString *msg = [NSString stringWithFormat:@"There was an error saving the product item. %@", error.localizedDescription];
        [[[UIAlertView alloc] initWithTitle:@"Error" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
    }
}

- (void)updateItemVoucher:(NSNumber *)voucher productId:(NSNumber *)productId context:(NSManagedObjectContext *)context {
    Cart *cart = [self findOrCreateCartForId:productId context:context];
    cart.editableVoucher = [NumberUtil convertDollarsToCents:voucher];
    NSError *error = nil;
    if (![context save:&error]) {
        NSString *msg = [NSString stringWithFormat:@"There was an error saving the product item. %@", error.localizedDescription];
        [[[UIAlertView alloc] initWithTitle:@"Error" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
    }
}

- (NSArray *)productIds {
    NSMutableArray *productIds = [[NSMutableArray alloc] initWithCapacity:self.carts.count];
    for (Cart *cart in self.carts) {
        [productIds addObject:cart.cartId];
    }
    return productIds;
}

- (NSArray *)discountLineItemIds {
    NSMutableArray *discountLineItemIds = [[NSMutableArray alloc] initWithCapacity:self.discountLineItems.count];
    for (DiscountLineItem *discountLineItem in self.discountLineItems) {
        [discountLineItemIds addObject:discountLineItem.lineItemId];
    }
    return discountLineItemIds;
}

- (NSDictionary *)asJSONReqParameter {
    NSMutableArray *arr = [[NSMutableArray alloc] initWithCapacity:self.carts.count];
    for (Cart *cart in self.carts) {
        BOOL hasQuantity = [[[CIProductViewControllerHelper alloc] init] itemHasQuantity:cart.editableQty];
        NSDictionary *proDict = [cart asJsonReqParameter];
        if (proDict) [arr addObject:(id) proDict];
    }
    NSMutableDictionary *newOrder = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NilUtil objectOrNNull:self.customer_id], kOrderCustomerID,
                                                                                      [NilUtil objectOrNNull:self.notes], kNotes,
                                                                                      [NilUtil objectOrNNull:self.ship_notes], kShipNotes,
                                                                                      [NilUtil objectOrNNull:self.authorized], kAuthorizedBy,
                                                                                      [self.ship_flag boolValue] ? @"TRUE" : @"FALSE", kShipFlag,
                                                                                      [NilUtil objectOrNNull:self.status], kOrderStatus,
                                                                                      arr, kOrderItems,
                                                                                      [self.print boolValue] ? @"TRUE" : @"FALSE", kOrderPrint,
                                                                                      [NilUtil objectOrNNull:self.printer], kOrderPrinter , nil];
    return [NSDictionary dictionaryWithObjectsAndKeys:newOrder, kOrder, nil];
}

@end
