//
// Created by septerr on 8/28/13.
// Copyright (c) 2013 Convention Innovations. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>

@class ProductCell;
@class Order;
@class Cart;


@interface CIProductViewControllerHelper : NSObject
- (BOOL)itemHasQuantity:(BOOL)multiStore quantity:(NSString *)quantity;

- (BOOL)itemHasQuantity:(NSString *)quantity;

- (BOOL)itemIsVoucher:(NSDictionary *)product;

- (void)updateCellBackground:(UITableViewCell *)cell product:(NSDictionary *)product cart:(Cart *)cart;

- (UITableViewCell *)dequeueReusableProductCell:(UITableView *)table;

- (UITableViewCell *)dequeueReusableCartViewCell:(UITableView *)table;

- (int)getQuantity:(NSString *)quantity;

- (void)saveManagedContext:(NSManagedObjectContext *)managedObjectContext;

- (void)sendRequest:(NSString *)httpMethod url:(NSString *)url parameters:(NSDictionary *)parameters
       successBlock:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, id JSON))successBlock
       failureBlock:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON))failureBlock
               view:(UIView *)view loadingText:(NSString *)loadingText;

@end