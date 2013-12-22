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

- (NSArray *)getItemShipDatesToSendToServer:(NSDictionary *)lineItem;

- (BOOL)itemIsVoucher:(NSDictionary *)product;

- (void)updateCellBackground:(UITableViewCell *)cell product:(NSDictionary *)product cart:(Cart *)cart;

- (UITableViewCell *)dequeueReusableProductCell:(UITableView *)table;

- (UITableViewCell *)dequeueReusableCartViewCell:(UITableView *)table;

- (int)getQuantity:(NSString *)quantity;

- (NSDictionary *)prepareJsonRequestParameterFromOrder:(Order *)coreDataOrder notes:(NSString *)notes shipNotes:(NSString *)shipNotes
                                              shipFlag:(NSString *)shipFlag
                                          authorizedBy:(NSString *)authorizedBy
                                             printFlag:(NSString *)printFlag
                                        printStationId:(NSNumber *)printStationId;

@end