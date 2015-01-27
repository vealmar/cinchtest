        //
// Created by David Jafari on 12/24/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <Underscore.m/Underscore.h>
#import "OrderCoreDataManager.h"
#import "JSONResponseSerializerWithErrorData.h"
#import "NotificationConstants.h"
#import "CoreDataUtil.h"
#import "Order.h"
#import "Order+Extensions.h"
#import "CinchJSONAPIClient.h"
#import "config.h"
#import "CurrentSession.h"
#import "SettingsManager.h"
#import "LineItem+Extensions.h"
#import "Product.h"
#import "MBProgressHUD.h"

@implementation OrderCoreDataManager

+ (NSFetchRequest *)buildOrderFetch:(NSString *)queryString
             inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Order" inManagedObjectContext:managedObjectContext]];
    [fetchRequest setIncludesSubentities:NO];
    [fetchRequest setFetchBatchSize:40];

    fetchRequest.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"updatedAt" ascending:NO],
                                      [NSSortDescriptor sortDescriptorWithKey:@"updatedAt" ascending:NO]
                                    ];

    NSMutableArray *predicates = [NSMutableArray arrayWithCapacity:4];
    if (queryString && queryString.length > 0) {
        [predicates addObject:[NSPredicate predicateWithFormat:@"customerName CONTAINS[cd] %@", queryString]];
        [predicates addObject:[NSPredicate predicateWithFormat:@"custId CONTAINS[cd] %@", queryString]];
        [predicates addObject:[NSPredicate predicateWithFormat:@"authorizedBy CONTAINS[cd] %@", queryString]];
        if ([queryString intValue] > 0) {
            [predicates addObject:[NSPredicate predicateWithFormat:@"orderId == %@", @([queryString integerValue])]];
        }
    }
    if (predicates.count > 0) {
        fetchRequest.predicate = [NSCompoundPredicate orPredicateWithSubpredicates:predicates];
    }

    return fetchRequest;
}

+ (void)headOrder:(NSNumber *)orderId
        updatedAt:(NSDate *)updatedAt
         onSuccess:(void (^)())successBlock {
    if (orderId && updatedAt) {
        [OrderCoreDataManager sendRequest:@"HEAD"
                                      url:kDBGETORDER(orderId)
                               parameters:@{ kAuthToken : [CurrentSession instance].authToken}
                             successBlock:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                                successBlock();
                             }
                             failureBlock:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {

                             }
                                     view:nil
                              loadingText:nil];
    }
}

+ (void)reloadOrders:(BOOL)partialReturn
           onSuccess:(void (^)())successBlock
           onFailure:(void (^)())failureBlock {
    NSLog(@"Reloading Orders");

    [[NSNotificationCenter defaultCenter] postNotificationName:OrderReloadStartedNotification object:nil];


    [[CurrentSession privateQueueContext] performBlockAndWait:^{
        [[CoreDataUtil sharedManager] deleteAllObjectsAndSave:@"Order" withContext:[CurrentSession privateQueueContext]];
    }];

    [[CinchJSONAPIClient sharedInstance] GET:kDBORDER parameters:@{ kAuthToken: [CurrentSession instance].authToken } success:^(NSURLSessionDataTask *task, id JSON) {
        if (JSON && ([(NSArray *) JSON count] > 0)) {
            NSArray *orders = (NSArray *) JSON;

            int batchSize = 75;
            int orderCount = [orders count];
            NSRange range = NSMakeRange(0, orderCount > batchSize ? batchSize : orderCount);

            NSDate *start = [NSDate date];
            NSMutableArray *remainingBatches = [NSMutableArray array];
            while (range.length > 0) {
                NSArray *orderBatch = [orders subarrayWithRange:range];
                if (range.location > 0) {
                    [remainingBatches addObject:orderBatch];
                } else {
                    [[CurrentSession privateQueueContext] performBlockAndWait:^{
                        for (NSDictionary *orderJson in orderBatch) {
                            Order *order = [[Order alloc] initWithJsonFromServer:orderJson insertInto:[CurrentSession privateQueueContext]];
                            [[CurrentSession privateQueueContext] insertObject:order];
                        }
                        [[CurrentSession privateQueueContext] save:nil];
                    }];
                }
                int newStartLocation = range.location + range.length;
                range = NSMakeRange(newStartLocation, orderCount - newStartLocation > batchSize ? batchSize : orderCount - newStartLocation);
            }

            //release unneeded data for memory
            JSON = nil;
            orders = nil;

            __block int remainingBatchCount = 0;
            int totalRemainingBatchCount = remainingBatches.count;

            if (totalRemainingBatchCount == 0) {
                [[NSNotificationCenter defaultCenter] postNotificationName:OrderReloadCompleteNotification object:nil];
            }

            for (NSArray *orderBatch in remainingBatches) {
                [[CurrentSession privateQueueContext] performBlock:^{
                    for (NSDictionary *orderJson in orderBatch) {
                        Order *order = [[Order alloc] initWithJsonFromServer:orderJson insertInto:[CurrentSession privateQueueContext]];
                        [[CurrentSession privateQueueContext] insertObject:order];
                    }
                    [[CurrentSession privateQueueContext] save:nil];

                    remainingBatchCount += 1;
                    if (remainingBatchCount >= totalRemainingBatchCount) {
                        [[NSNotificationCenter defaultCenter] postNotificationName:OrderReloadCompleteNotification object:nil];
                    }
                }];
            }

            NSDate *methodFinish = [NSDate date];
            NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:start];

            NSLog(@"Execution Time: %f", executionTime);
        }
        if (successBlock) successBlock();

    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        if (failureBlock) failureBlock();
        NSInteger statusCode = [[[error userInfo] objectForKey:AFNetworkingOperationFailingURLResponseErrorKey] statusCode];
        NSString *alertMessage = nil;
        if (statusCode == 0) {
            alertMessage = @"Request timed out.";
        } else {
            alertMessage = [error localizedDescription];
        }
        [[[UIAlertView alloc] initWithTitle:@"Error!" message:alertMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        NSLog(@"%@ Error Loading Orders: %@", [self class], [error localizedDescription]);
    }];
}

+ (void)fetchOrder:(NSNumber *)orderId
       attachHudTo:(UIView *)view
         onSuccess:(void (^)(Order *order))successBlock
         onFailure:(void (^)())failureBlock {
    NSLog(@"Fetching Order");
    
    // Get the existing object, if available.
    Order *existingOrder = (Order *) [[CoreDataUtil sharedManager] fetchObject:@"Order" withPredicate:[NSPredicate predicateWithFormat:@"orderId = %@", orderId]];
    
    NSString *loadingText = existingOrder ? @"Restoring Order" : @"Retrieving Order";
    NSDictionary *parameters = @{ kAuthToken: [CurrentSession instance].authToken };
    
    [OrderCoreDataManager sendRequest:@"GET"
                                  url:kDBGETORDER(orderId)
                           parameters:parameters
                         successBlock:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                             dispatch_async(dispatch_get_main_queue(), ^{
                                 [[CurrentSession mainQueueContext] performBlock:^{
                                     Order *returnOrder;
                                     if (existingOrder) {
                                         returnOrder = existingOrder;
                                         [existingOrder updateWithJsonFromServer:JSON withContext:[CurrentSession mainQueueContext]];
                                     } else {
                                         returnOrder = [[Order alloc] initWithJsonFromServer:JSON insertInto:[CurrentSession mainQueueContext]];
                                     }
                                     [[CurrentSession mainQueueContext] save:nil];
                                     if (successBlock) successBlock(returnOrder);
                                 }];
                             });
                         }
                         failureBlock:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                             //failure
                             if (failureBlock) failureBlock();
                         }
                                 view:view
                          loadingText:loadingText];
    
}

+ (void)syncOrder:(Order *)order
      attachHudTo:(UIView *)view
        onSuccess:(void (^)(Order *order))successBlock
        onFailure:(void (^)())failureBlock {

    NSLog(@"Syncing Order");
    
    MBProgressHUD *submit = [MBProgressHUD showHUDAddedTo:view animated:NO];
    
    submit.removeFromSuperViewOnHide = YES;
    submit.labelText = @"Saving Order";
    
    NSString *method = [order.orderId intValue] > 0 ? @"PUT" : @"POST";
    NSString *url = [order.orderId intValue] == 0 ? kDBORDER : kDBORDEREDITS([order.orderId intValue]);
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary:[order asJsonReqParameter]];
    parameters[kAuthToken] = [CurrentSession instance].authToken;

    NSManagedObjectID *orderObjectID = order.objectID;

    void(^saveBlock)(id) = ^(id JSON) {
        [[CurrentSession mainQueueContext] performBlock:^{
            Order *contextOrder = (Order *) [[CurrentSession mainQueueContext] existingObjectWithID:orderObjectID error:nil];
            if (contextOrder) {
                [contextOrder updateWithJsonFromServer:JSON withContext:[CurrentSession mainQueueContext]];
                contextOrder.inSync = YES;
                [[CurrentSession mainQueueContext] save:nil];
            }
            [submit hide:NO];
            successBlock(contextOrder);
        }];
    };

    if (order.hasNontransientChanges || !order.inSync) {
        
        [self sendRequest:method
                      url:url
               parameters:parameters
             successBlock:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                 saveBlock(JSON);
             }
             failureBlock:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                 if ((response.statusCode == 422 || response.statusCode == 409) && JSON) {
                     saveBlock(JSON);
                 } else {
                     [submit hide:NO];
                     if (failureBlock) failureBlock();
                     NSLog(@"%@ Error Loading Orders: %@", [self class], [error localizedDescription]);
                 }
             }
                     view:nil
              loadingText:@"Saving order"];
    } else {
        [submit hide:NO];
        successBlock(order);
    }
}

+ (void)saveOrder:(Order *)order
            async:(BOOL)shouldAsync
       beforeSave:(void (^)(Order *order))threadsafeOrderOperationBlock
        onSuccess:(void (^)())successBlock {
    
    // we're about to save, we will consider this order out-of-sync with the server regardless of it's actual state
    // outside of the transient properties
    if (order.hasNontransientChanges) order.inSync = NO;
    if (shouldAsync) {
        NSDictionary *orderProperties = [order dictionaryWithValuesForKeys:order.entity.attributesByName.allKeys];

        USArrayWrapper *lineItemsArray = Underscore.array(order.lineItems.allObjects);
        if (lineItemsArray.any(^BOOL(LineItem *lineItem) { return lineItem.inserted; })) {
            NSLog(@"Cannot asynchronously save inserted objects. There will be nothing to update on the main thread when merging changes.");
            return [self saveOrder:order async:NO beforeSave:threadsafeOrderOperationBlock onSuccess:successBlock];
        }
        NSArray *insertedLineProperties = lineItemsArray.map(^id(LineItem *lineItem) {
            return @[
                    lineItem.objectID,
                    [lineItem dictionaryWithValuesForKeys:lineItem.entity.attributesByName.allKeys],
            ];
        }).unwrap;

        NSLog(@"Saving Order Asynchronously");
        [[CurrentSession privateQueueContext] performBlock:^{
            Order *asyncOrder = [OrderCoreDataManager load:@"Order" withId:order.objectID fromContext:[CurrentSession privateQueueContext]];
            [asyncOrder setValuesForKeysWithDictionary:orderProperties];

            for (NSArray *lineItemIdAndProps in insertedLineProperties) {
                NSManagedObjectID *objectID = [[NSNull null] isEqual:lineItemIdAndProps[0]] ? nil : lineItemIdAndProps[0];
                NSDictionary *lineItemProperties = lineItemIdAndProps[1];
                LineItem *asyncLineItem = [OrderCoreDataManager load:@"LineItem" withId:objectID fromContext:[CurrentSession privateQueueContext]];
                [asyncLineItem setValuesForKeysWithDictionary:lineItemProperties];
                if (!objectID && asyncLineItem.productId && (!asyncLineItem.product || ![asyncLineItem.productId isEqualToNumber:asyncLineItem.product.productId])) {
                    //in an insert, make sure we have the right product
                    asyncLineItem.product = (Product *) [[CoreDataUtil sharedManager] fetchObject:@"Product"
                                                                                        inContext:[CurrentSession privateQueueContext]
                                                                                    withPredicate:[NSPredicate predicateWithFormat:@"productId == %@", asyncLineItem.productId]];
                }
            }

            if (threadsafeOrderOperationBlock) threadsafeOrderOperationBlock(asyncOrder);
            [[CurrentSession privateQueueContext] save:nil];
            NSLog(@"Asynchronous Save Complete");
            if (successBlock) successBlock();
        }];
    } else {
        if (threadsafeOrderOperationBlock) threadsafeOrderOperationBlock(order);
        [OrderCoreDataManager saveOrder:order inContext:order.managedObjectContext];
        if (successBlock) successBlock();
    }
}

+ (void)saveOrder:(Order *)order inContext:(NSManagedObjectContext *)context {
    NSLog(@"Saving Order");
    // we're about to save, we will consider this order out-of-sync with the server regardless of it's actual state
    // outside of the transient properties
    // we dont want to flip the sync flag if the sync value had just been changed to YES (a sync just occurred)
    
    @try {
        if (order.changedValues) {
            BOOL wasInSync = [order changedValues][@"inSync"] && [[order changedValues][@"inSync"] boolValue];
            if (order.hasNontransientChanges && !(wasInSync)) {
                order.inSync = NO;
            }
        } else {
            NSLog(@"ok");
        }
    }
    @catch (id exception) {
        NSLog(@"Exception occured checking order state before save.");
        order.inSync = NO;
    }

    if (![order.managedObjectContext isEqual:context]) {
        [NSException raise:@"IllegalStateException" format:@"Cannot save order. Saving context is different from the one the order was loaded on."];
    }

    NSError *error = nil;
    if (![context save:&error]) {
        NSString *msg = [NSString stringWithFormat:@"There was an error saving your order. %@", error.localizedDescription];
        [[[UIAlertView alloc] initWithTitle:@"Error" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
    }
}

+ (id)load:(NSString *)name withId:(NSManagedObjectID *)objectID fromContext:(NSManagedObjectContext *)context {
    if (objectID) {
        return [context existingObjectWithID:objectID error:nil];
    } else {
        NSEntityDescription *entity = [NSEntityDescription entityForName:name inManagedObjectContext:context];
        return [[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:context];
    }
}

+ (void)deleteOrder:(Order *)order
          onSuccess:(void (^)())successBlock
          onFailure:(void (^)())failureBlock {
    if (order) {
        if (order.orderId != nil && [order.orderId intValue] != 0 && !order.isPartial) {
            [[CinchJSONAPIClient sharedInstance] DELETE:kDBORDEREDITS([order.orderId integerValue]) parameters:@{ kAuthToken: [CurrentSession instance].authToken } success:^(NSURLSessionDataTask *task, id JSON) {
                [[CoreDataUtil sharedManager] deleteObject:order];
                if (successBlock) successBlock();
            } failure:^(NSURLSessionDataTask *task, NSError *error) {
                if (failureBlock) failureBlock();
                NSString *errorMsg = [NSString stringWithFormat:@"Error deleting order. %@", error.localizedDescription];
                [[[UIAlertView alloc] initWithTitle:@"Error" message:errorMsg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
            }];
            
        } else {
            [[CoreDataUtil sharedManager] deleteObject:order];
            if (successBlock) successBlock();
        }
    }
}

#pragma mark - Private

+ (void)sendRequest:(NSString *)httpMethod url:(NSString *)url parameters:(NSDictionary *)parameters
       successBlock:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, id JSON))successBlock
       failureBlock:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON))failureBlock
               view:(UIView *)hudView loadingText:(NSString *)loadingText {

    MBProgressHUD *submit = nil;
    if (hudView) {
        submit = [MBProgressHUD showHUDAddedTo:hudView animated:YES];
        submit.removeFromSuperViewOnHide = YES;
        submit.labelText = loadingText;
        [submit show:NO];
    }

    CinchJSONAPIClient *client = [CinchJSONAPIClient sharedInstanceWithJSONRequestSerialization];
    NSMutableURLRequest *request = [client.requestSerializer requestWithMethod:httpMethod URLString:[NSString stringWithFormat:@"%@%@", kBASEURL, url] parameters:parameters error:nil];
    __block NSURLSessionDataTask *task = [client dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id json, NSError *error) {
        if (error) {
            if (submit) [submit hide:NO];
            if (failureBlock) failureBlock(request, (NSHTTPURLResponse *)response, error, json);
            NSInteger statusCode = [[[error userInfo] objectForKey:AFNetworkingOperationFailingURLResponseErrorKey] statusCode];
            NSString *alertMessage = [NSString stringWithFormat:@"There was an error processing this request. Status Code: %d", statusCode];
            if (statusCode == 422) {
                NSArray *validationErrors = json ? [((NSDictionary *) json) objectForKey:kErrors] : nil;
                if (validationErrors && validationErrors.count > 0) {
                    alertMessage = validationErrors.count > 1 ? [NSString stringWithFormat:@"%@ ...", validationErrors[0]] : validationErrors[0];
                }
            } else if (statusCode == 0) {
                alertMessage = @"Request timed out.";
            }
            [[[UIAlertView alloc] initWithTitle:@"Error!" message:alertMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        } else {
            if (submit) [submit hide:NO];

            if (successBlock) successBlock(request, (NSHTTPURLResponse *)response, json);
        }
    }];

    [task resume];
}

@end