//
// Created by septerr on 3/27/15.
// Copyright (c) 2015 Urban Coding. All rights reserved.
//

#import "Show+Extensions.h"
#import "config.h"
#import "NilUtil.h"
#import "DateUtil.h"


@implementation Show (Extensions)

- (id)initWithShowFromServer:(NSDictionary *)showFromServer context:(NSManagedObjectContext *)context {
    self = [super initWithEntity:[NSEntityDescription entityForName:@"Show" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
    if (self) {
        self.showId = (NSNumber *) [NilUtil nilOrObject:showFromServer[kShowId]];
        self.host_id = (NSNumber *) [NilUtil nilOrObject:showFromServer[kShowHostId]];
        self.title = (NSString *) [NilUtil nilOrObject:[showFromServer objectForKey:kShowTitle]];
        self.showDescription = (NSString *) [NilUtil nilOrObject:[showFromServer objectForKey:kShowDescription]];
        self.status = (NSString *) [NilUtil nilOrObject:[showFromServer objectForKey:kShowStatus]];
        NSString *beginDateStr = (NSString *) [NilUtil nilOrObject:[showFromServer objectForKey:kShowBeginDate]];
        self.begin_date = beginDateStr ? [DateUtil convertApiDateTimeToNSDate:beginDateStr] : nil;
        NSString *endDateStr = (NSString *) [NilUtil nilOrObject:[showFromServer objectForKey:kShowEndDate]];
        self.end_date = beginDateStr ? [DateUtil convertApiDateTimeToNSDate:endDateStr] : nil;
    }
    return self;
}

- (NSDictionary *)asDictionary {
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    if (self.showId)
        dictionary[kShowId] = self.showId;
    if (self.host_id)
        dictionary[kShowHostId] = self.host_id;
    if (self.title)
        dictionary[kShowTitle] = self.title;
    if (self.showDescription)
        dictionary[kShowDescription] = self.showDescription;
    if (self.begin_date)
        dictionary[kShowBeginDate] = self.begin_date;
    if (self.end_date)
        dictionary[kShowEndDate] = self.end_date;
    if (self.status)
        dictionary[kShowStatus] = self.status;
    return dictionary;
}

@end