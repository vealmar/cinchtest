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

+ (NSDecimalNumber *)hundredDecimal {
    if (!oneHundredDecimal)
        oneHundredDecimal = [NSDecimalNumber decimalNumberWithString:@"100"];
    return oneHundredDecimal;
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

+ (int32_t)convertDollarsToCents:(NSNumber *)dollars {
    if (dollars) {
        NSDecimalNumber *dollarsDecimal = [NSDecimalNumber decimalNumberWithString:[dollars description]];
        NSDecimalNumber *centsDecimal = [dollarsDecimal decimalNumberByMultiplyingBy:[self hundredDecimal]];
        int32_t cents = [centsDecimal intValue];
        return cents;
    } else
        return 0;
}

@end