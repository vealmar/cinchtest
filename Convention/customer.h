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
@property(nonatomic, retain) NSNumber *import_id;
@property(nonatomic, retain) NSString *email;
@property(nonatomic, retain) NSNumber *initial_show;
@property(nonatomic, retain) NSString *stores;

@end
