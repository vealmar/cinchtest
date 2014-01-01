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
static NSNumber *zeroNSNumber = nil;
static NSNumberFormatter *currencyFormatter = nil;

+ (NSDecimalNumber *)hundredDecimal {
    if (!oneHundredDecimal)
        oneHundredDecimal = [NSDecimalNumber decimalNumberWithString:@"100"];
    return oneHundredDecimal;
}

+ (NSNumber *)zeroIntNSNumber {
    if (!zeroNSNumber)
        zeroNSNumber = @(0);
    return zeroNSNumber;
}

+ (NSNumberFormatter *)currencyFormatter {
    if (!currencyFormatter) {
        currencyFormatter = [[NSNumberFormatter alloc] init];
        [currencyFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    }
    return currencyFormatter;
}


+ (NSString *)formatDollarAmount:(NSNumber *)dollarAmount {
    if (dollarAmount) {
        NSNumberFormatter *nf = [[NSNumberFormatter alloc] init];
        nf.formatterBehavior = NSNumberFormatterBehavior10_4;
        nf.maximumFractionDigits = 2;
        nf.minimumFractionDigits = 2;
        nf.minimumIntegerDigits = 1;
        return [nf stringFromNumber:[NSNumber numberWithDouble:[dollarAmount doubleValue]]];
    } else
        return @"";
}

+ (NSString *)formatCentsAsCurrency:(NSNumber *)cents {
    if (cents) {
        return [self.currencyFormatter stringFromNumber:@([cents intValue] / 100.0)];
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

@end