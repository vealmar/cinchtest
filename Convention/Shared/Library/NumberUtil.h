//
// Created by septerr on 8/31/13.
// Copyright (c) 2013 Convention Innovations. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>


@interface NumberUtil : NSObject
+ (NSDecimalNumber *)zeroDecimal;

+ (NSNumber *)zeroIntNSNumber;

+ (NSNumber *)convertDollarStringToDollars:(NSString *)dollarAmount;

+ (NSString *)formatDollarAmount:(NSNumber *)dollarAmount;

+ (NSString *)formatDollarAmountWithoutSymbol:(NSNumber *)dollarAmount;

+ (NSNumber *)convertDollarsToCents:(NSNumber *)dollars;

+ (NSNumber *)convertCentsToDollars:(NSNumber *)cents;

+ (NSString *)formatCentsAsCurrency:(NSNumber *)cents;

+ (NSString *)formatCentsAsDollarsWithoutSymbol:(NSNumber *)cents;

+ (NSNumber *)convertStringToDollars:(NSString *)string;
@end