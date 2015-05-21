//
//  Vendor.h
//  Convention
//
//  Created by septerr on 9/9/13.
//  Copyright (c) 2013 Convention Innovations. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Vendor : NSManagedObject

@property(nonatomic, retain) NSNumber *vendorId;
@property(nonatomic, retain) NSString *email;
@property(nonatomic, retain) NSString *company;
@property(nonatomic, retain) NSString *vendid;
@property(nonatomic, retain) NSString *name;
@property(nonatomic, retain) NSString *groupName;
@property(nonatomic, retain) NSString *season;
@property(nonatomic, retain) NSNumber *hidewsprice;
@property(nonatomic, retain) NSNumber *hideshprice;
@property(nonatomic, retain) NSNumber *commodity;
@property(nonatomic, retain) NSString *owner;
@property(nonatomic, retain) NSNumber *complete;
@property(nonatomic, retain) NSString *dlybill;
@property(nonatomic, retain) NSNumber *lines;
@property(nonatomic, retain) NSString *username;
@property(nonatomic, retain) NSNumber *vendorgroup_id;
@property(nonatomic, retain) NSString *isle;
@property(nonatomic, retain) NSString *booth;
@property(nonatomic, retain) NSString *dept;
@property(nonatomic, retain) NSNumber *broker_id;
@property(nonatomic, retain) NSString *status;

- (id)initWithVendorFromServer:(NSDictionary *)vendorFromServer context:(NSManagedObjectContext *)context;

- (NSDictionary *)asDictionary;
@end
