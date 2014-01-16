//
// Created by septerr on 8/21/13.
// Copyright (c) 2013 Convention Innovations. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>

@class Order;

@interface AnOrder : NSObject
@property(strong, nonatomic) NSArray *lineItems;
@property(strong, nonatomic) NSNumber *customerId;
@property(strong, nonatomic) NSNumber *orderId;
@property(strong, nonatomic) NSString *notes;
@property(strong, nonatomic) NSNumber *voucherTotal;
@property(strong, nonatomic) NSString *shipNotes;
@property(strong, nonatomic) NSNumber *total;
@property(strong, nonatomic) NSString *status;
@property(strong, nonatomic) NSString *authorized;
@property(strong, nonatomic) NSDictionary *customer;
@property(strong, nonatomic) NSNumber *cancelByDays;
@property(strong, nonatomic) Order *coreDataOrder;
@property(nonatomic) BOOL *shipFlag;
@property(strong, nonatomic) NSArray *errors;

- (id)initWithJSONFromServer:(NSDictionary *)JSON;

- (id)initWithCoreData:(Order *)order;

- (NSString *)getCustomerDisplayName;

@end