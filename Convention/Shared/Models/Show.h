//
//  Show.h
//  Convention
//
//  Created by septerr on 3/27/15.
//  Copyright (c) 2015 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Show : NSManagedObject

@property (nonatomic, retain) NSNumber * showId;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * showDescription;
@property (nonatomic, retain) NSNumber * host_id;
@property (nonatomic, retain) NSDate * begin_date;
@property (nonatomic, retain) NSDate * end_date;
@property (nonatomic, retain) NSString * status;

@end
