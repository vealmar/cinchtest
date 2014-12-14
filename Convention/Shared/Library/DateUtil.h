//
//  SettingsManager.h
//  PreopEval
//
//  Created by Chris Hardin on 2/9/11.
//  Copyright 2011 Acuitec. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface DateUtil : NSObject

#pragma mark Singleton
+ (DateUtil *)sharedManager;

- (id)init;

+ (NSDateFormatter *)createFormatter:(NSString *)format;

+ (NSDateFormatter *)newApiDateTimeFormatter;

+ (NSDateFormatter *)newApiDateFormatter;

+ (NSArray *)convertNSDateArrayToApiDateArray:(NSArray *)nsdates;

+ (NSArray *)convertApiDateArrayToNSDateArray:(NSArray *)jsonDateArray;

+ (NSDate *)convertApiDateTimeToNSDate:(NSString *)jsonDate;

+ (NSString *)convertNSDateToApiDate:(NSDate *)nsDate;

+ (NSString *)convertNSDateToApiDateTime:(NSDate *)nsDate;
@end
