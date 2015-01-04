//
//  SettingsManager.m
//  PreopEval
//
//  Created by Chris Hardin on 2/9/11.
//  Copyright 2011 Acuitec. All rights reserved.
//

#import <Underscore.m/Underscore.h>
#import "DateUtil.h"

static DateUtil *sharedInstance;


@implementation DateUtil


#pragma mark Singleton Implementation

+ (DateUtil *)sharedManager {
    @synchronized (self) {
        if (sharedInstance == nil) {
            sharedInstance = [[self alloc] init];
        }
    }
    return sharedInstance;
}


- (id)init {
    if (self = [super init]) {

    }
    return self;
}

#pragma mark - Description Override

- (NSString *)description {
    return @"DateUtil";
}

+ (NSDateFormatter *)createFormatter:(NSString *)format {
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:format];
    return dateFormat;
}

+ (NSDateFormatter *)newApiDateTimeFormatter {
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
    return df;
}

+ (NSDateFormatter *)newPsqlDateTimeFormatter {
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSSSSS"];
    return df;
}

+ (NSDateFormatter *)newApiDateFormatter {
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"yyyy-MM-dd"];
    return df;
}

+ (NSDate *)convertPsqlDateTimeToNSDate:(NSString *)jsonDate {
    NSDateFormatter *df = [DateUtil newPsqlDateTimeFormatter];
    return [df dateFromString:jsonDate];
}

+ (NSDate *)convertApiDateTimeToNSDate:(NSString *)jsonDate {
    NSDateFormatter *df = [DateUtil newApiDateTimeFormatter];
    return [df dateFromString:jsonDate];
}

+ (NSString *)convertNSDateToApiDate:(NSDate *)nsDate {
    if (nsDate) {
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"MM-dd-yyyy"];
        return [df stringFromDate:nsDate];
    } else
        return nil;

}

+ (NSString *)convertNSDateToApiDateTime:(NSDate *)nsDate {
    NSDateFormatter *df = [DateUtil newApiDateTimeFormatter];
    return [df stringFromDate:nsDate];
}

+ (NSArray *)convertNSDateArrayToApiDateArray:(NSArray *)nsdates {
    NSMutableArray *jsonDates = [[NSMutableArray alloc] init];
    if (nsdates && [nsdates count] > 0) {
        NSDateFormatter *df = [DateUtil newApiDateFormatter];
        for (NSDate *nsdate in nsdates) {
            [jsonDates addObject:[df stringFromDate:nsdate]];
        }
    }
    return jsonDates;
}

+ (NSArray *)convertApiDateArrayToNSDateArray:(NSArray *)jsonDateArray {
    NSDateFormatter *df = [DateUtil newApiDateFormatter];
    return Underscore.array(jsonDateArray)
                .map(^id(id obj) {
                    return [df dateFromString:obj];
                }).unwrap;
}


@end
