//
// Created by septerr on 8/27/13.
// Copyright (c) 2013 Convention Innovations. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>

@class Order;
@class Customer;


@interface CoreDataManager : NSObject
+ (Order *)getOrder:(NSNumber *)orderId managedObjectContext:(NSManagedObjectContext *)managedObjectContext;

+ (Customer *)getCustomer:(NSNumber *)customerId managedObjectContext:(NSManagedObjectContext *)managedObjectContext;

+ (NSArray *)getCustomers:(NSManagedObjectContext *)managedObjectContext;

+ (NSArray *)getProducts:(NSManagedObjectContext *)managedObjectContext;
@end