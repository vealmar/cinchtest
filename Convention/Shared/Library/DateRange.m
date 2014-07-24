//
// Created by David Jafari on 3/14/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import "DateRange.h"
#import "DateUtil.h"


@interface DateRange()

@property NSMutableArray *dates; // individual dates
// @todo use NSTimeInterval here?
@property NSMutableArray *ranges; // ranges of dates, depicted as NSArray[NSArray[NSDate1, NSDate2]]

@end

@implementation DateRange

- (id)init {
    if (self) {
        self.dates = [NSMutableArray array];
        self.ranges = [NSMutableArray array];
    }
    return self;
}

+ (DateRange *)createInstanceFromJson:(NSArray *)array {
    DateRange *dateRange = [[DateRange alloc] init];
    [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[NSString class]]) {
            [dateRange.dates addObject:[dateRange parseDate:obj]];
        } else { // should be an array of two values then
            NSArray *dateRangeArray = (NSArray *) obj;
            NSString *d1 = [dateRangeArray objectAtIndex:0];
            NSString *d2 = [dateRangeArray objectAtIndex:1];
            [dateRange.ranges addObject:@[[dateRange parseDate:d1], [dateRange parseDate:d2]]];
        }
    }];
    return dateRange;
}

- (NSDate *)parseDate:(NSString *)dateString {
    return [DateUtil convertYyyymmddthhmmsszToDate:dateString];
}

- (NSArray *)fixedDates {
    return [NSArray arrayWithArray:self.dates];
}

- (bool)covers:(NSDate *)date {
    __block bool result = false;

    [self.dates enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([((NSDate *) obj) isEqualToDate:date]) {
            result = true;
            stop = true;
        }
    }];

    if (result) return result;

    [self.ranges enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSComparisonResult day1Result = [[((NSArray *) obj) objectAtIndex:0] compare:date];
        NSComparisonResult day2Result = [[((NSArray *) obj) objectAtIndex:1] compare:date];
        if ((day1Result == NSOrderedSame || day1Result == NSOrderedAscending) && (day2Result == NSOrderedSame || day2Result == NSOrderedDescending)) {
            result = true;
            stop = true;
        }
    }];

    return result;
}


@end