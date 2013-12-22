//
// Created by septerr on 8/31/13.
// Copyright (c) 2013 Convention Innovations. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>


@interface NumberUtil : NSObject
+ (NSString *)formatDollarAmount:(NSNumber *)dollarAmount;

+ (NSNumber *)convertDollarsToCents:(NSNumber *)dollars;
@end