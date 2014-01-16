//
// Created by septerr on 8/11/13.
// Copyright (c) 2013 MotionMobs. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>


@interface ShowConfigurations : NSObject
@property BOOL discounts;
@property BOOL shipDates;
@property BOOL printing;
@property BOOL vouchers;
@property BOOL contracts;
@property BOOL contactBeforeShipping;
@property BOOL cancelOrder;
@property NSDate *boothPaymentsDate;
@property UIImage *loginScreen;
@property UIImage *logo;

+ (ShowConfigurations *)instance;

+ (void)createInstanceFromJson:(NSDictionary *)json;

@end