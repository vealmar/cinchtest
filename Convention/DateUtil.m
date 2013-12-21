//
//  SettingsManager.m
//  PreopEval
//
//  Created by Chris Hardin on 2/9/11.
//  Copyright 2011 Acuitec. All rights reserved.
//

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

- (NSString *)userDateFormat {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    return [dateFormatter dateFormat];
}

+ (NSDateFormatter *)createFormatter {

    //	NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    //	//[dateFormat setTimeStyle:NSDateFormatterNoStyle];
    //	//[dateFormat setDateStyle:NSDateFormatterShortStyle];
    //	[dateFormat setDateFormat:@"MM/dd/yyyy hh:mm:ss a"];
    //
    //    return dateFormat;

    return [self createFormatter:@"MM/dd/yyyy hh:mm:ss a"];
}

+ (NSDateFormatter *)createFormatter:(NSString *)format {
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:format];
    return dateFormat;
}

+ (NSDate *)parseDate:(NSString *)dateString {
    NSDateFormatter *formatter = [self createFormatter];
    NSDate *date = [formatter dateFromString:dateString];
    return date;
}

+ (NSString *)stringFromGMTDate:(NSDate *)date {
    NSDateFormatter *dateFormat = [self createFormatter];
    [dateFormat setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
    NSString *dateString = [dateFormat stringFromDate:date];
    return dateString;
}

+ (NSString *)stringDate {
    NSDate *date = [NSDate date];
    NSDateFormatter *dateFormat = [self createFormatter];
    [dateFormat setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
    NSString *dateString = [dateFormat stringFromDate:date];
    return dateString;
}

- (NSDate *)processJSDate:(NSString *)value {
    NSString *rawDate = [[value componentsSeparatedByString:@"("] objectAtIndex:1];
    rawDate = [[rawDate componentsSeparatedByString:@"-"] objectAtIndex:0];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:([rawDate doubleValue] / 1000)];
    return date;
}

+ (NSDate *)convertYyyymmddToDate:(NSString *)jsonDate {
    NSMutableOrderedSet *dates = [[NSMutableOrderedSet alloc] init];
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"yyyy-MM-dd"];
    return [df dateFromString:jsonDate];
}

+ (NSDate *)convertYyyymmddthhmmsszToDate:(NSString *)jsonDate {
    NSMutableOrderedSet *dates = [[NSMutableOrderedSet alloc] init];
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
    return [df dateFromString:jsonDate];
}

+ (NSString *)convertDateToYyyymmdd:(NSDate *)nsDate {
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"yyyy-MM-dd"];
    return [df stringFromDate:nsDate];
}

+ (NSString *)convertDateToYyyymmddthhmmssz:(NSDate *)nsDate {
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
    return [df stringFromDate:nsDate];
}

+ (NSArray *)convertDateArrayToYyyymmddArray:(NSArray *)nsdates {
    NSMutableArray *jsonDates = [[NSMutableArray alloc] init];
    if (nsdates && [nsdates count] > 0) {
        for (NSDate *nsdate in nsdates) {
            [jsonDates addObject:[DateUtil convertDateToYyyymmdd:nsdate]];
        }
    }
    return jsonDates;
}

+ (NSArray *)convertYyyymmddArrayToDateArray:(NSArray *)jsonDateArray {
    NSMutableArray *nsDates = [[NSMutableArray alloc] init];
    if ([jsonDateArray count] > 0) {
        for (NSString *jsonDate in jsonDateArray) {
            [nsDates addObject:[DateUtil convertYyyymmddToDate:jsonDate]];
        }
    }
    return nsDates;
}


@end
