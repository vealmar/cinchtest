//
// Created by septerr on 8/28/13.
// Copyright (c) 2013 Convention Innovations. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>


@interface CIProductViewControllerHelper : NSObject
- (BOOL)itemHasQuantity:(BOOL)multiStore lineItem:(NSDictionary *)linetItem;

- (NSArray *)getItemShipDatesToSendToServer:(NSDictionary *)lineItem;

- (BOOL)itemIsVoucher:(NSDictionary *)product;
@end