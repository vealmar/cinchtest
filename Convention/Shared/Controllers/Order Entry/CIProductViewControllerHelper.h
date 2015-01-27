//
// Created by septerr on 8/28/13.
// Copyright (c) 2013 Convention Innovations. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>

@class ProductCell;
@class Product;
@class Order;
@class LineItem;

@interface CIProductViewControllerHelper : NSObject

+ (BOOL)itemIsVoucher:(Product *)product;

- (void)updateCellBackground:(UITableViewCell *)cell order:(Order *)order lineItem:(LineItem *)lineItem;

- (UITableViewCell *)dequeueReusableCartViewCell:(UITableView *)table;

- (NSArray *)sortProductsBySequenceAndInvtId:(NSArray *)productIdsOrProducts;

- (NSArray *)sortDiscountsByLineItemId:(NSArray *)lineItemIds;

- (BOOL)isOrderReadyForSubmission:(Order *)order;

- (NSString *)displayNameForVendor:(NSNumber *)vendorId;

@end