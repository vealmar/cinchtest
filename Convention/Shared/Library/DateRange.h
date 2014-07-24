//
// Created by David Jafari on 3/14/14.
// Copyright (c) 2014 Convention Innovations. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface DateRange : NSObject

+ (DateRange *)createInstanceFromJson:(NSArray *)array;
- (NSArray *)fixedDates;
- (bool)covers:(NSDate *)date;

@end