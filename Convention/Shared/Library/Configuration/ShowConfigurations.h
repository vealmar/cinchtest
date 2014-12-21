//
// Created by septerr on 8/11/13.
// Copyright (c) 2013 MotionMobs. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>

@class DateRange;

@interface ShowConfigurations : NSObject

@property BOOL productEnableManufacturerNo;
@property BOOL atOncePricing;
@property BOOL discounts;
@property BOOL shipDates; //uses or requires shipdates
@property BOOL shipDatesRequired;
@property BOOL printing;
@property BOOL captureSignature;
@property BOOL vouchers;
@property BOOL contracts;
@property BOOL contactBeforeShipping;
@property BOOL cancelOrder;
@property NSDate *boothPaymentsDate;
@property UIImage *loginScreen;
@property UIImage *logo;
@property BOOL poNumber;
@property BOOL paymentTerms;
@property NSString *shipDatesType;
@property DateRange *orderShipDates;
@property BOOL *vendorMode;
@property NSArray *customFields; //Array<ShowCustomField>

+ (ShowConfigurations *)instance;

+ (void)createInstanceFromJson:(NSDictionary *)json;

- (bool)isOrderShipDatesType;

- (bool)isLineItemShipDatesType;

- (NSArray *)orderCustomFields;

- (NSString *)price1Label;

- (NSString *)price2Label;
@end