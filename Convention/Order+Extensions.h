//
//  Order+Extensions.h
//  Convention
//
//  Created by Kerry Sanders on 11/13/12.
//  Copyright (c) 2012 MotionMobs. All rights reserved.
//

#import "Order.h"
#import "Cart.h"

@class AnOrder;

@interface Order (Extensions)

- (id)initWithOrder:(AnOrder *)orderFromServer forCustomer:(NSDictionary *)customer vendorId:(NSNumber *)vendorId vendorGroup:(NSString *)vendorGroup andVendorGroupId:(NSString *)vendorGroupId context:(NSManagedObjectContext *)context;

- (void)updateItemQuantity:(NSString *)quantity productId:(NSNumber *)productId context:(NSManagedObjectContext *)context;

- (void)updateItemVoucher:(NSNumber *)voucher productId:(NSNumber *)productId context:(NSManagedObjectContext *)context;

- (Cart *)findCartForProductId:(NSNumber *)productId;

- (DiscountLineItem *)findDiscountForLineItemId:(NSNumber *)lineItemId;

- (NSArray *)productIds;

- (NSArray *)discountLineItemIds;

- (NSDictionary *)asJSONReqParameter;

@end
