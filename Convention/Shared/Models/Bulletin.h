//
//  Bulletin.h
//  Convention
//
//  Created by septerr on 9/9/13.
//  Copyright (c) 2013 Convention Innovations. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Bulletin : NSManagedObject

@property(nonatomic, retain) NSNumber *bulletinId;
@property(nonatomic, retain) NSNumber *number;
@property(nonatomic, retain) NSString *name;
@property(nonatomic, retain) NSString *note1;
@property(nonatomic, retain) NSString *note2;
@property(nonatomic, retain) NSDate *shipdate1;
@property(nonatomic, retain) NSDate *shipdate2;
@property(nonatomic, retain) NSNumber *vendor_id;
@property(nonatomic, retain) NSNumber *show_id;
@property(nonatomic, retain) NSString *status;
@property(nonatomic, retain) NSNumber *import_id;

- (id)initWithBulletinFromServer:(NSDictionary *)bulletinFromServer context:(NSManagedObjectContext *)context;

- (NSDictionary *)asDictionary;
@end
