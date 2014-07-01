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
@class ShowCustomField;

@interface Order (Extensions)

- (id)initWithOrder:(AnOrder *)orderFromServer forCustomer:(NSDictionary *)customer vendorId:(NSNumber *)vendorId vendorGroup:(NSString *)vendorGroup andVendorGroupId:(NSString *)vendorGroupId context:(NSManagedObjectContext *)context;

- (void)updateItemQuantity:(NSString *)quantity productId:(NSNumber *)productId context:(NSManagedObjectContext *)context;

- (void)updateItemVoucher:(NSNumber *)voucher productId:(NSNumber *)productId context:(NSManagedObjectContext *)context;

- (void)updateItemShowPrice:(NSNumber *)price productId:(NSNumber *)productId context:(NSManagedObjectContext *)context;

- (Cart *)findCartForProductId:(NSNumber *)productId;

- (Cart *)findOrCreateCartForId:(NSNumber *)productId context:(NSManagedObjectContext *)context;

- (DiscountLineItem *)findDiscountForLineItemId:(NSNumber *)lineItemId;

- (NSArray *)productIds;

- (NSArray *)discountLineItemIds;

- (NSString *)customFieldValueFor:(ShowCustomField *)showCustomField;

- (void)setCustomFieldValueFor:(ShowCustomField *)showCustomField value:(NSString *)value;

- (NSDictionary *)asJSONReqParameter;

@end
