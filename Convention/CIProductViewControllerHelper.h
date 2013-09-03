//
// Created by septerr on 8/28/13.
// Copyright (c) 2013 Convention Innovations. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>

@class ProductCell;


@interface CIProductViewControllerHelper : NSObject
- (BOOL)itemHasQuantity:(BOOL)multiStore quantity:(NSString *)quantity;

- (NSArray *)getItemShipDatesToSendToServer:(NSDictionary *)lineItem;

- (BOOL)itemIsVoucher:(NSDictionary *)product;

- (void)updateCellBackground:(UITableViewCell *)cell product:(NSDictionary *)product
         editableItemDetails:(NSDictionary *)editableItemDetails multiStore:(BOOL)multiStore;

- (UITableViewCell *)dequeueReusableProductCell:(UITableView *)table;

- (UITableViewCell *)dequeueReusableCartViewCell:(UITableView *)table;
@end