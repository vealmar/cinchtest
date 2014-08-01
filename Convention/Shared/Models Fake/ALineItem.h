//
// Created by septerr on 8/21/13.
// Copyright (c) 2013 Convention Innovations. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>

@interface ALineItem : NSObject
@property(strong, nonatomic) NSNumber *voucherPrice;
@property(strong, nonatomic) NSNumber *orderId;
@property(strong, nonatomic) NSString *desc;
@property(strong, nonatomic) NSString *desc2;
@property(strong, nonatomic) NSNumber *itemId;
@property(strong, nonatomic) NSString *category;
@property(strong, nonatomic) NSString *quantity; //could be a json string with quantity by store or could be a number as a string.
@property(strong, nonatomic) NSArray *shipDates; //array of "yyyy-MM-dd" strings.
@property(strong, nonatomic) NSNumber *productId;
@property(strong, nonatomic) NSNumber *price;
@property(strong, nonatomic) NSArray *errors;
@property(strong, nonatomic) NSArray *warnings;

- (id)initWithJsonFromServer:(NSDictionary *)json;

- (BOOL)isStandard;

- (int)totalQuantity;

- (BOOL)isDiscount;

@end