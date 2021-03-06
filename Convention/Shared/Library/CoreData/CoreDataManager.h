//
// Created by septerr on 8/27/13.
// Copyright (c) 2013 Convention Innovations. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>

@class Customer;
@class SetupInfo;
@class ProductSearch;
@class Show;

@interface CoreDataManager : NSObject

+ (Customer *)getCustomer:(NSNumber *)customerId managedObjectContext:(NSManagedObjectContext *)managedObjectContext;

+ (NSArray *)getCustomers:(NSManagedObjectContext *)managedObjectContext;

+ (NSArray *)getProducts:(NSManagedObjectContext *)managedObjectContext;

+ (NSArray *)getVendors:(NSManagedObjectContext *)managedObjectContext;

+ (NSArray *)getBulletins:(NSManagedObjectContext *)managedObjectContext;

+ (void)reloadProductsAsync:(BOOL)async usingQueueContext:(NSManagedObjectContext *)queueContext onSuccess:(void (^)())successBlock onFailure:(void (^)())failureBlock;

+ (NSUInteger)getProductCount;

+ (NSUInteger)getCustomerCount;

+ (NSFetchRequest *)buildProductFetch:(ProductSearch *)search;

+ (NSArray *)getProductIdsMatching:(ProductSearch *)search;

+ (SetupInfo *)getSetupInfo:(NSString *)itemName;

+ (Show *)getLatestShow:(NSManagedObjectContext *)managedObjectContext;
@end