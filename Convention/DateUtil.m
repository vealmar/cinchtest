//
//  SettingsManager.m
//  PreopEval
//
//  Created by Chris Hardin on 2/9/11.
//  Copyright 2011 Acuitec. All rights reserved.
//

#import "DateUtil.h"
#import "StringManipulation.h"

static DateUtil *sharedInstance;


@implementation DateUtil


#pragma mark Singleton Implementation

+ (DateUtil*)sharedManager
{
    @synchronized(self) {
        if (sharedInstance == nil) {
            sharedInstance = [[self alloc] init];
        }
    }
    return sharedInstance;
}
 

- (id)init
{
    if (self = [super init])
    {
		 
    }
    return self;
}



#pragma mark -
#pragma mark Description Override

- (NSString *)description {
	return @"DateUtil";
}

 

 


-(NSString *) userDateFormat {
	
	
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	
	[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	
	[dateFormatter setDateStyle:NSDateFormatterShortStyle];
	
	
	return [dateFormatter dateFormat];
	
}



-(NSDateFormatter *) createFormatter {


	NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
	//[dateFormat setTimeStyle:NSDateFormatterNoStyle];
	//[dateFormat setDateStyle:NSDateFormatterShortStyle];
	[dateFormat setDateFormat:@"MM/dd/yyyy hh:mm:ss a"];

    return dateFormat;
}

-(NSDate *) parseDate:(NSString *)dateString {
	
	
	NSDateFormatter *formatter = [self createFormatter];
	
	NSDate *date = [formatter dateFromString:dateString];
	
	DLog(@"Date: %@", date);
	
	return date;
	
	
}


-(NSString *) stringFromGMTDate:(NSDate *)date {
	
	NSDateFormatter *dateFormat = [self createFormatter];
	[dateFormat setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
 
	NSString *dateString = [dateFormat stringFromDate:date];  
  
     return dateString;
	
}

-(NSString *) stringDate {
	
	NSDate *date = [NSDate date];
	NSDateFormatter *dateFormat = [self createFormatter];
	[dateFormat setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
	
	NSString *dateString = [dateFormat stringFromDate:date];  
	
	return dateString;
	
}



-(NSDate *) processJSDate:(NSString *)value {
	
	
	NSString *rawDate = [[value componentsSeparatedByString:@"("] objectAtIndex:1];
	rawDate = [[rawDate componentsSeparatedByString:@"-"] objectAtIndex:0];
	DLog(@"Raw: %@", rawDate);
	NSDate *date = [NSDate dateWithTimeIntervalSince1970:([rawDate doubleValue]/1000)];
	DLog(@"Date: %@", date);
	return date;
 }



@end
