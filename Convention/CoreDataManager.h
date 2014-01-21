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

+ (NSArray *)getVendors:(NSManagedObjectContext *)managedObjectContext;

+ (NSArray *)getBulletins:(NSManagedObjectContext *)managedObjectContext;

+ (void)reloadProducts:(NSString *)authToken vendorGroupId:(NSString *)vendorGroupId managedObjectContext:(NSManagedObjectContext *)managedObjectContext
        onSuccess:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, id JSON))successBlock
        onFailure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON))failureBlock;

+ (NSUInteger)getProductCount;
@end