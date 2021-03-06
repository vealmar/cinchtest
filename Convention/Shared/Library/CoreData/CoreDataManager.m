//
// Created by septerr on 8/27/13.
// Copyright (c) 2013 Convention Innovations. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "CoreDataManager.h"
#import "Customer.h"
#import "config.h"
#import "Product.h"
#import "Product+Extensions.h"
#import "CoreDataUtil.h"
#import "SynchronousResponse.h"
#import "CIAppDelegate.h"
#import "ProductCache.h"
#import "SetupInfo.h"
#import "ProductSearch.h"
#import "JSONResponseSerializerWithErrorData.h"
#import "CinchJSONAPIClient.h"
#import "NotificationConstants.h"
#import "CurrentSession.h"
#import "ResponseStatus.h"
#import "APLNormalizedStringTransformer.h"
#import "Show.h"

static NSPredicate *productSearchPredicate = nil;

@implementation CoreDataManager

+ (Customer *)getCustomer:(NSNumber *)customerId managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    Customer *customer;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Customer" inManagedObjectContext:managedObjectContext]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(customer_id ==[c] %@)", [customerId stringValue]];
    [fetchRequest setPredicate:predicate];
    NSError *error = nil;
    NSArray *fetchedObjects = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error == nil && fetchedObjects != nil && [fetchedObjects count] > 0) {
        customer = fetchedObjects[0];
    }
    return customer;
}

+ (NSArray *)getCustomers:(NSManagedObjectContext *)managedObjectContext {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Customer" inManagedObjectContext:managedObjectContext]];
    NSArray *sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"billname" ascending:YES]];
    [fetchRequest setSortDescriptors:sortDescriptors];
    NSError *error = nil;
    NSArray *fetchedObjects = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error) {
        NSLog(@"%@ Error fetching customers. %@", [self class], [error localizedDescription]);
        return [[NSArray alloc] init];
    } else
        return fetchedObjects;
}

+ (NSArray *)getProducts:(NSManagedObjectContext *)managedObjectContext {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Product" inManagedObjectContext:managedObjectContext]];
    NSArray *sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"invtid" ascending:YES]];
    [fetchRequest setSortDescriptors:sortDescriptors];
    NSError *error = nil;
    NSArray *fetchedObjects = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error) {
        NSLog(@"%@ Error fetching products. %@", [self class], [error localizedDescription]);
        return [[NSArray alloc] init];
    } else
        return fetchedObjects;
}

+ (NSArray *)getVendors:(NSManagedObjectContext *)managedObjectContext {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Vendor" inManagedObjectContext:managedObjectContext]];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    [fetchRequest setSortDescriptors:@[sortDescriptor]];
    NSError *error = nil;
    NSArray *fetchedObjects = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error) {
        NSLog(@"%@ Error fetching vendors. %@", [self class], [error localizedDescription]);
        return [[NSArray alloc] init];
    } else
        return fetchedObjects;
}

+ (NSArray *)getBulletins:(NSManagedObjectContext *)managedObjectContext {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Bulletin" inManagedObjectContext:managedObjectContext]];
    NSError *error = nil;
    NSArray *fetchedObjects = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error) {
        NSLog(@"%@ Error fetching bulletins. %@", [self class], [error localizedDescription]);
        return [[NSArray alloc] init];
    } else
        return fetchedObjects;
}

+ (void)reloadProductsAsync:(BOOL)async usingQueueContext:(NSManagedObjectContext *)queueContext onSuccess:(void (^)())successBlock onFailure:(void (^)())failureBlock {
    [[NSNotificationCenter defaultCenter] postNotificationName:ProductsLoadRequestedNotification object:nil];

    void (^completeWithSuccess)() = ^() {
        [[NSNotificationCenter defaultCenter] postNotificationName:ProductsLoadedNotification object:nil];
        if (successBlock) successBlock();
    };

    [[CinchJSONAPIClient sharedInstance] getProductsWithSession:[CurrentSession instance]
                                                         success:^(NSURLSessionDataTask *task, id JSON) {
                                                             if (JSON) {

                                                                 if (ResponseStatusTypeNotModified != [ResponseStatus statusOfTask:task]) {
                                                                     //always perform the delete synchronously so we dont delete stuff we pull from the server later
                                                                     [queueContext performBlockAndWait:^{
                                                                         [[CoreDataUtil sharedManager] deleteAllObjectsAndSave:@"Product" withContext:queueContext];
                                                                     }];
                                                                 }

                                                                 NSDate *start=nil;
                                                                 if (([(NSArray *) JSON count] > 0)) {
                                                                     NSArray *products = (NSArray *) JSON;
                                                                     int batchSize = 1000;
                                                                     int productsCount = [products count];
                                                                     NSRange range = NSMakeRange(0, (NSUInteger) (productsCount > batchSize ? batchSize : productsCount));

                                                                     start = [NSDate date];
                                                                     NSMutableArray *remainingBatches = [NSMutableArray array];
                                                                     while (range.length > 0) {
                                                                         NSArray *productsBatch = [products subarrayWithRange:range];
                                                                         // always wait for the first iteration, we can return from this method with data to display immediately
                                                                         @autoreleasepool {
                                                                             [queueContext performBlockAndWait:^{
                                                                                 for (NSDictionary *productJson in productsBatch) {
                                                                                     //                            [queueContext insertObject:[[Product alloc] initWithProductFromServer:productJson context:queueContext]];
                                                                                     [[Product alloc] initWithProductFromServer:productJson context:queueContext];
                                                                                 }
                                                                                 [queueContext save:nil];
                                                                             }];
                                                                         }
                                                                         int newStartLocation = range.location + range.length;
                                                                         range = NSMakeRange((NSUInteger) newStartLocation, (NSUInteger) (productsCount - newStartLocation > batchSize ? batchSize : productsCount - newStartLocation));
                                                                     }


                                                                     __block int remainingBatchCount = 0;
                                                                     int totalRemainingBatchCount = remainingBatches.count;

                                                                     if (totalRemainingBatchCount == 0) {
                                                                         completeWithSuccess();
                                                                     }

                                                                     for (NSArray *productsBatch in remainingBatches) {
                                                                         if (async) {
                                                                             [queueContext performBlock:^{
                                                                                 for (NSDictionary *productJson in productsBatch) {
                                                                                     [queueContext insertObject:[[Product alloc] initWithProductFromServer:productJson context:queueContext]];
                                                                                 }
                                                                                 [queueContext save:nil];

                                                                                 remainingBatchCount += 1;
                                                                                 if (remainingBatchCount >= totalRemainingBatchCount) {
                                                                                     completeWithSuccess();
                                                                                 }
                                                                             }];
                                                                         } else {
                                                                             [queueContext performBlockAndWait:^{
                                                                                 for (NSDictionary *productJson in productsBatch) {
                                                                                     [queueContext insertObject:[[Product alloc] initWithProductFromServer:productJson context:queueContext]];
                                                                                 }
                                                                                 [queueContext save:nil];

                                                                                 remainingBatchCount += 1;
                                                                                 if (remainingBatchCount >= totalRemainingBatchCount) {
                                                                                     completeWithSuccess();
                                                                                 }
                                                                             }];
                                                                         }
                                                                     }
                                                                 } else {
                                                                     completeWithSuccess();
                                                                 }

                                                                 NSDate *methodFinish = [NSDate date];
                                                                 NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:start];

                                                                 NSLog(@"Execution Time: %f", executionTime);
                                                             } else {
                                                                 completeWithSuccess();
                                                             }
                                                         } failure:^(NSURLSessionDataTask *task, NSError *error) {
                id JSON = error.userInfo[JSONResponseSerializerWithErrorDataKey];
                if (failureBlock) failureBlock();
                NSInteger statusCode = [[error userInfo][AFNetworkingOperationFailingURLResponseErrorKey] statusCode];
                NSString *alertMessage = [NSString stringWithFormat:@"There was an error processing this request. Status Code: %d", statusCode];
                if (statusCode == 422) {
                    NSArray *validationErrors = JSON ? ((NSDictionary *) JSON)[kErrors] : nil;
                    if (validationErrors && validationErrors.count > 0) {
                        alertMessage = validationErrors.count > 1 ? [NSString stringWithFormat:@"%@ ...", validationErrors[0]] : validationErrors[0];
                    }
                } else if (statusCode == 0) {
                    alertMessage = @"Request timed out.";
                } else {
                    alertMessage = [error localizedDescription];
                }
                [[[UIAlertView alloc] initWithTitle:@"Error!" message:alertMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                NSLog(@"%@ Error Loading Products: %@", [self class], [error localizedDescription]);
            }];
}

+ (NSUInteger)getProductCount {
    NSManagedObjectContext *context = [CurrentSession mainQueueContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"Product" inManagedObjectContext:context]];
    [request setIncludesSubentities:NO];
    NSError *err;
    NSUInteger count = [context countForFetchRequest:request error:&err];
    if (count == NSNotFound) {
        NSLog(@"An error occurred when fetching product count. %@", err == nil ? @"" : [err localizedDescription]);
        return 0;
    }
    return count;
}

+ (NSUInteger)getCustomerCount {
    NSManagedObjectContext *context = [CurrentSession mainQueueContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"Customer" inManagedObjectContext:context]];
    [request setIncludesSubentities:NO];
    NSError *err;
    NSUInteger count = [context countForFetchRequest:request error:&err];
    if (count == NSNotFound) {
        NSLog(@"An error occurred when fetching product count. %@", err == nil ? @"" : [err localizedDescription]);
        return 0;
    }
    return count;
}

+ (NSArray *)getProductsMatching:(ProductSearch *)search addToCache:(BOOL)addToCache {
    NSFetchRequest *fetchRequest = [self buildProductFetch:search];
    NSError *error = nil;
    NSArray *fetchedObjects = [search.context executeFetchRequest:fetchRequest error:&error];
    if (error) {
        NSLog(@"%@ Error fetching products matching query string '%@'. %@", [self class], search.queryString, [error localizedDescription]);
        return [NSArray array];
    } else {
        if (addToCache) [[ProductCache sharedCache] addRecentlyQueriedProducts:fetchedObjects];
        return fetchedObjects;
    }
}

+ (NSFetchRequest *)buildProductFetch:(ProductSearch *)search {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Product" inManagedObjectContext:search.context]];
    [fetchRequest setIncludesSubentities:NO];
    [fetchRequest setIncludesPendingChanges:NO];
    [fetchRequest setFetchBatchSize:200];
    if (search.limit > 0) {
        [fetchRequest setFetchLimit:(NSUInteger) search.limit];
    }
    if (search.sortDescriptors) {
        fetchRequest.sortDescriptors = search.sortDescriptors;
    }
    NSMutableArray *predicates = [NSMutableArray arrayWithCapacity:3];
    if (search.currentVendor > 0) {
        [predicates addObject:[NSPredicate predicateWithFormat:@"vendor_id = %d", search.currentVendor]];
    }
    if (search.currentBulletin > 0) {
        [predicates addObject:[NSPredicate predicateWithFormat:@"bulletin_id = %d", search.currentBulletin]];
    }
    if (search.queryString.length > 0) {
        if (nil == productSearchPredicate) {
            productSearchPredicate = [NSPredicate predicateWithFormat:@"normalizedSearchText CONTAINS[CD] $lowBound"];
        }
        NSPredicate *searchQuery = [productSearchPredicate predicateWithSubstitutionVariables:@{@"lowBound" : [APLNormalizedStringTransformer normalizeString:search.queryString]}];
        [predicates addObject:searchQuery];
    }
    if (predicates.count > 0) {
        fetchRequest.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
    }
    return fetchRequest;
}

+ (NSArray *)getProductIdsMatching:(ProductSearch *)search {
    //if it is a limited search, fetch all product attributes and add them to the cache. They will probably be needed soon.
    if (search.limit > 0) {
        NSMutableArray *productIds = [[NSMutableArray alloc] init];
        NSArray *products = [self getProductsMatching:search addToCache:YES];
        if (products) {
            [products enumerateObjectsUsingBlock:^(Product *obj, NSUInteger idx, BOOL *stop) {
                [productIds addObject:obj.productId];
            }];
        }
        return productIds;
    } else {
        //if it is an unlimited search, just query the ids and return them.
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        [fetchRequest setEntity:[NSEntityDescription entityForName:@"Product" inManagedObjectContext:search.context]];
        [fetchRequest setPropertiesToFetch:@[@"productId"]];
        [fetchRequest setResultType:NSDictionaryResultType];
        [fetchRequest setIncludesSubentities:NO];
        if (search.limit > 0) {
            [fetchRequest setFetchLimit:(NSUInteger) search.limit];
        }
        if (search.sortDescriptors) {
            fetchRequest.sortDescriptors = search.sortDescriptors;
        }
        NSMutableArray *predicates = [NSMutableArray arrayWithCapacity:3];
        if (search.currentVendor > 0) {
            [predicates addObject:[NSPredicate predicateWithFormat:@"vendor_id = %d", search.currentVendor]];
        }
        if (search.currentBulletin > 0) {
            [predicates addObject:[NSPredicate predicateWithFormat:@"bulletin_id = %d", search.currentBulletin]];
        }
        [predicates addObject:[NSPredicate predicateWithFormat:@"invtid CONTAINS[cd] %@ or descr CONTAINS[cd] %@ or descr2 CONTAINS[cd] %@", search.queryString, search.queryString, search.queryString]];
        fetchRequest.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
        NSError *error = nil;
        NSArray *fetchedObjects = [search.context executeFetchRequest:fetchRequest error:&error];
        if (error) {
            NSLog(@"%@ Error fetching products matching query string '%@'. %@", [self class], search.queryString, [error localizedDescription]);
            return [NSArray array];
        } else {
            NSMutableArray *productIds = [NSMutableArray array];
            [fetchedObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {  //todo this iterating over the results should be avoided. there is an NSResultType of ObjectId, if we can modify product view to work off of object id, we can avoid this iteration.
                [productIds addObject:((NSDictionary *) obj)[@"productId"]];
            }];
            return productIds;
        }
    }
}

+ (SetupInfo *)getSetupInfo:(NSString *)itemName {
    NSDictionary *subs = @{@"ITEMNAME" : itemName};
    CIAppDelegate *appDelegate = (CIAppDelegate *) [[UIApplication sharedApplication] delegate];
    NSManagedObjectModel *model = appDelegate.managedObjectModel;
    NSFetchRequest *req = [model fetchRequestFromTemplateWithName:@"getSetupItem" substitutionVariables:subs]; //todo: this code looks nasty
    NSError *error = nil;
    NSArray *results = [[CurrentSession mainQueueContext] executeFetchRequest:req error:&error];
    return (!error && results != nil && [results count] > 0) ? results[0] : nil;
}

+ (Show *)getLatestShow:(NSManagedObjectContext *)managedObjectContext {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Show"];
    fetchRequest.fetchLimit = 1;
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"begin_date" ascending:NO]];
    NSError *error = nil;
    return [managedObjectContext executeFetchRequest:fetchRequest error:&error].lastObject;
}


@end