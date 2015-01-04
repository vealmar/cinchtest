//
// Created by septerr on 8/31/13.
// Copyright (c) 2013 Convention Innovations. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "NumberUtil.h"


@implementation NumberUtil {

}
static NSDecimalNumber *oneHundredDecimal = nil;
static NSDecimalNumber *zeroDecimal = nil;
static NSNumber *zeroNSNumber = nil;
static NSNumberFormatter *currencyFormatter = nil;

+ (NSDecimalNumber *)hundredDecimal {
    if (!oneHundredDecimal)
        oneHundredDecimal = [NSDecimalNumber decimalNumberWithString:@"100"];
    return oneHundredDecimal;
}

+ (NSDecimalNumber *)zeroDecimal {
    if (!zeroDecimal)
        zeroDecimal = [NSDecimalNumber decimalNumberWithString:@"0"];
    return zeroDecimal;

}

+ (NSNumber *)zeroIntNSNumber {
    if (!zeroNSNumber)
        zeroNSNumber = @(0);
    return zeroNSNumber;
}

+ (NSNumberFormatter *)currencyFormatter {
    if (!currencyFormatter) {
        currencyFormatter = [[NSNumberFormatter alloc] init];
        currencyFormatter.formatterBehavior = NSNumberFormatterBehavior10_4;
        currencyFormatter.maximumFractionDigits = 2;
        currencyFormatter.minimumFractionDigits = 2;
        currencyFormatter.minimumIntegerDigits = 1;
    }
    return currencyFormatter;
}

+ (NSNumber *)convertDollarStringToDollars:(NSString *)dollarAmount {
    if (dollarAmount) {
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        formatter.numberStyle = NSNumberFormatterCurrencyStyle;
        return [formatter numberFromString:dollarAmount];
    } else
        return @(0);
}

+ (NSString *)formatDollarAmount:(NSNumber *)dollarAmount {
    if (dollarAmount) {
        return [NSNumberFormatter localizedStringFromNumber:dollarAmount numberStyle:NSNumberFormatterCurrencyStyle];
    } else
        return @"";
}

+ (NSString *)formatDollarAmountWithoutSymbol:(NSNumber *)dollarAmount {
    if (dollarAmount) {
        return [[self currencyFormatter] stringFromNumber:dollarAmount];
    } else
        return @"";
}

+ (NSString *)formatCentsAsCurrency:(NSNumber *)cents {
    if (cents) {
        return [self formatDollarAmount:[NSNumber numberWithDouble:[cents intValue] / 100.0]];
    } else
        return @"";
}

+ (NSString *)formatCentsAsDollarsWithoutSymbol:(NSNumber *)cents {
    if (cents) {
        return [[self currencyFormatter] stringFromNumber:[NSNumber numberWithDouble:[cents intValue] / 100.0]];
    } else
        return @"";
}

+ (NSNumber *)convertDollarsToCents:(NSNumber *)dollars {
    if (dollars) {
        NSDecimalNumber *dollarsDecimal = [NSDecimalNumber decimalNumberWithString:[dollars description]];
        NSDecimalNumber *centsDecimal = [dollarsDecimal decimalNumberByMultiplyingBy:[self hundredDecimal]];
        int cents = [centsDecimal intValue];
        return [NSNumber numberWithInt:cents];
    } else
        return [self zeroIntNSNumber];
}

+ (NSNumber *)convertCentsToDollars:(NSNumber *)cents {
    if (cents) {
        return [NSNumber numberWithDouble:[cents intValue] / 100.0];
    } else
        return [self zeroIntNSNumber];
}

+ (NSNumber *)convertStringToDollars:(NSString *)string {
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    return [formatter numberFromString:string];
}
@end