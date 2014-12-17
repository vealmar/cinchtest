//
//  Customer.h
//  Convention
//
//  Created by septerr on 9/6/13.
//  Copyright (c) 2013 Convention Innovations. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Customer : NSManagedObject

@property(nonatomic, retain) NSNumber *customer_id;
@property(nonatomic, retain) NSString *billname;
@property(nonatomic, retain) NSString *email;
@property(nonatomic, retain) NSString *stores;
@property(nonatomic, retain) NSString *custid;

- (id)initWithCustomerFromServer:(NSDictionary *)customerFromServer context:(NSManagedObjectContext *)context;

- (NSDictionary *)asDictionary;
@end
