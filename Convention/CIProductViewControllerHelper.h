//
// Created by septerr on 8/28/13.
// Copyright (c) 2013 Convention Innovations. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>
#import "AnOrder.h"

@class ProductCell;
@class Order;
@class Cart;
@class Product;


@interface CIProductViewControllerHelper : NSObject

+ (BOOL)itemIsVoucher:(Product *)product;

- (BOOL)isProductAVoucher:(NSNumber *)productId;

- (void)updateCellBackground:(UITableViewCell *)cell cart:(Cart *)cart;

- (UITableViewCell *)dequeueReusableProductCell:(UITableView *)table;

- (UITableViewCell *)dequeueReusableCartViewCell:(UITableView *)table;

+ (int)getQuantity:(NSString *)quantity;

- (Order *)createCoreDataCopyOfOrder:(AnOrder *)order
                            customer:(NSDictionary *)customer
                    loggedInVendorId:(NSString *)loggedInVendorId
               loggedInVendorGroupId:(NSString *)loggedInVendorGroupId
                managedObjectContext:(NSManagedObjectContext *)managedObjectContext;

- (NSArray *)sortProductsByinvtId:(NSArray *)productIdsOrProducts;

- (NSArray *)sortDiscountsByLineItemId:(NSArray *)lineItemIds;

- (void)saveManagedContext:(NSManagedObjectContext *)managedObjectContext;

- (BOOL)isOrderReadyForSubmission:(Order *)coreDataOrder;

- (NSArray *)getTotals:(Order *)coreDataOrder;

- (NSString *)displayNameForVendor:(NSInteger)id1 vendorDisctionaries:(NSArray *)vendorDictionaries;

- (NSString *)displayNameForVendor:(NSNumber *)vendorId;

- (void)sendRequest:(NSString *)httpMethod url:(NSString *)url parameters:(NSDictionary *)parameters
       successBlock:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, id JSON))successBlock
       failureBlock:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON))failureBlock
               view:(UIView *)view loadingText:(NSString *)loadingText;

- (void)sendSignature:(UIImage *)signature
                total:(NSNumber *)total
              orderId:(NSNumber *)orderId
            authToken:(NSString *)authToken
         successBlock:(void (^)())successBlock
         failureBlock:(void (^)(NSError *error))failureBlock view:(UIView *)view;
@end