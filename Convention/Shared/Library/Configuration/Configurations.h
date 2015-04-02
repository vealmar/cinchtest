//
// Created by septerr on 8/11/13.
// Copyright (c) 2013 MotionMobs. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>

@class DateRange;

@interface Configurations : NSObject

@property BOOL enableOrderNotes;
@property BOOL enableOrderAuthorizedBy;
@property BOOL productEnableManufacturerNo;
@property BOOL discounts;
@property BOOL discountsGuide;
@property BOOL shipDates; //uses or requires shipdates
@property BOOL shipDatesRequired;
@property BOOL captureSignature;
@property BOOL vouchers;
@property BOOL contactBeforeShipping;
@property BOOL cancelOrder;
@property UIImage *loginScreen;
@property UIImage *logo;
@property BOOL poNumber;
@property BOOL paymentTerms;
@property NSString *shipDatesType;
@property DateRange *orderShipDates;
@property BOOL vendorMode;
@property NSArray *customFields; //Array<ShowCustomField>

+ (Configurations *)instance;

+ (void)createInstanceFromJson:(NSDictionary *)json;

+ (void)overrideWith:(NSDictionary *)json;

- (bool)isOrderShipDatesType;

- (bool)isLineItemShipDatesType;

- (NSArray *)orderCustomFields;

- (NSString *)price1Label;

- (NSString *)price2Label;

- (BOOL)isShowPricing;
- (BOOL)isAtOncePricing;
- (BOOL)isTieredPricing;
- (int)priceTiersAvailable;
- (int)defaultPriceTierIndex;
- (NSString *)priceTierLabelAt:(int)index;

@end