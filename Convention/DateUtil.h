//
//  SettingsManager.h
//  PreopEval
//
//  Created by Chris Hardin on 2/9/11.
//  Copyright 2011 Acuitec. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 
 
 Very Important class in the system. This class is designed to be a central place where you can
 retrieve and store settings
 
 
 */

@interface DateUtil : NSObject {


}




#pragma mark Singleton
+ (DateUtil *)sharedManager;


- (id)init;


+ (NSString *)userDateFormat;

+ (NSDateFormatter *)createFormatter;

+ (NSDate *)parseDate:(NSString *)dateString;

+ (NSString *)stringFromGMTDate:(NSDate *)date;

+ (NSDate *)processJSDate:(NSString *)value;

+ (NSString *)stringDate;

+ (NSString *)convertDateToYyyymmdd:(NSDate *)nsDate;

+ (NSDate *)convertYyyymmddToDate:(NSString *)jsonDate;

+ (NSArray *)convertDateArrayToYyyymmddArray:(NSArray *)nsdates;

+ (NSArray *)convertYyyymmddArrayToDateArray:(NSArray *)jsonDateArray;

+ (NSDate *)convertYyyymmddthhmmsszToDate:(NSString *)jsonDate;

+ (NSString *)convertDateToMmddyyyy:(NSDate *)nsDate;

+ (NSString *)convertDateToYyyymmddthhmmssz:(NSDate *)nsDate;
@end
