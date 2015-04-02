//
// Created by David Jafari on 12/24/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <Underscore.m/Underscore.h>
#import "OrderManager.h"
#import "JSONResponseSerializerWithErrorData.h"
#import "NotificationConstants.h"
#import "CoreDataUtil.h"
#import "Order.h"
#import "Order+Extensions.h"
#import "CinchJSONAPIClient.h"
#import "config.h"
#import "CurrentSession.h"
#import "LineItem+Extensions.h"
#import "Product.h"
#import "MBProgressHUD.h"
#import "NISignatureView.h"
#import "CIAlertView.h"
#import "ApiDataService.h"

@implementation OrderManager

+ (NSFetchRequest *)buildOrderFetch:(NSString *)queryString
             inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Order" inManagedObjectContext:managedObjectContext]];
    [fetchRequest setIncludesSubentities:NO];
    [fetchRequest setFetchBatchSize:40];

    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"updatedAt" ascending:NO],
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

+ (void)reloadOrdersOnSuccess:(void (^)())successBlock onFailure:(void (^)())failureBlock {
    NSLog(@"Reloading Orders");

    [[NSNotificationCenter defaultCenter] postNotificationName:OrderReloadStartedNotification object:nil];


    [[CurrentSession privateQueueContext] performBlockAndWait:^{
        [[CoreDataUtil sharedManager] deleteAllObjectsAndSave:@"Order" withContext:[CurrentSession privateQueueContext]];
    }];

    [[CinchJSONAPIClient sharedInstance] GET:[NSString stringWithFormat:kDBORDER, [[[CurrentSession instance] showId] intValue]] parameters:@{kAuthToken : [CurrentSession instance].authToken, kVendorGroupID : [CurrentSession instance].vendorGroupId} success:^(NSURLSessionDataTask *task, id JSON) {
        if (JSON) {
            NSArray *orders = (NSArray *) JSON;

            int batchSize = 75;
            int orderCount = [orders count];
            NSRange range = NSMakeRange(0, (NSUInteger) (orderCount > batchSize ? batchSize : orderCount));

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
                range = NSMakeRange((NSUInteger) newStartLocation, (NSUInteger) (orderCount - newStartLocation > batchSize ? batchSize : orderCount - newStartLocation));
            }

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

    }                                failure:^(NSURLSessionDataTask *task, NSError *error) {
        if (failureBlock) failureBlock();
        NSInteger statusCode = [[error userInfo][AFNetworkingOperationFailingURLResponseErrorKey] statusCode];
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
    NSDictionary *parameters = @{kAuthToken : [CurrentSession instance].authToken};

    [ApiDataService sendRequest:@"GET"
                            url:[NSString stringWithFormat:kDBGETORDER, [[[CurrentSession instance] showId] intValue], [orderId intValue]]
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
        onSuccess:(void (^)())successBlock
        onFailure:(void (^)())failureBlock {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary:[order asJsonReqParameter]];
    NSString *url = [order.orderId intValue] == 0 ? [NSString stringWithFormat:kDBORDER, [[[CurrentSession instance] showId] intValue]] : [NSString stringWithFormat:kDBORDEREDITS, [[[CurrentSession instance] showId] intValue], [order.orderId intValue]];

    NSManagedObjectID *orderObjectID = order.objectID;
    void(^saveBlock)(id) = ^(id JSON) {
        [[CurrentSession mainQueueContext] performBlock:^{
            if (JSON) {
                Order *contextOrder = (Order *) [[CurrentSession mainQueueContext] existingObjectWithID:orderObjectID error:nil];
                if (contextOrder) {
                    [contextOrder updateWithJsonFromServer:JSON withContext:[CurrentSession mainQueueContext]];
                    contextOrder.inSync = YES;  //todo  sg I don't think this statement is needed. updateWithJsonFromServer already sets inSync to YES.
                    [[CurrentSession mainQueueContext] save:nil];
                }
            }
            successBlock();
        }];
    };

    [self syncOrderParameters:parameters order:order view:view url:url successBlock:saveBlock failureBlock:failureBlock];
}

+ (void)syncOrderDetails:(Order *)order
             sendEmailTo:(NSString *)email
             attachHudTo:(UIView *)view
               onSuccess:(void (^)())successBlock
               onFailure:(void (^)())failureBlock {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary:[order asJsonReqParameterWithoutLines]];
    if (email) parameters[@"send_email_to"] = email;
    NSString *url = [order.orderId intValue] == 0 ? [NSString stringWithFormat:kDBORDER, [[[CurrentSession instance] showId] intValue]] : [NSString stringWithFormat:kDBORDERDETAILEDITS, [[[CurrentSession instance] showId] intValue], [order.orderId intValue]];

    NSManagedObjectID *orderObjectID = order.objectID;
    void(^saveBlock)(id) = ^(id JSON) {
        [[CurrentSession mainQueueContext] performBlock:^{
            if (JSON) {
                Order *contextOrder = (Order *) [[CurrentSession mainQueueContext] existingObjectWithID:orderObjectID error:nil];
                if (contextOrder) {
                    [contextOrder updateWithJsonFromServer:JSON withContext:[CurrentSession mainQueueContext]];
                    [[CurrentSession mainQueueContext] save:nil];
                }
            }
            successBlock();
        }];
    };

    [self syncOrderParameters:parameters order:order view:view url:url successBlock:saveBlock failureBlock:failureBlock];
}

+ (void)syncSignature:(NISignatureView *)signatureView
              orderId:(NSNumber *)orderId
       showHUDAddedTo:(UIView *)view
         successBlock:(void (^)())successBlock
         failureBlock:(void (^)(NSError *error))failureBlock {
    if (signatureView.drawnSignature) {
        UIImage *signatureImage = [signatureView snapshot];
        [self sendSignature:signatureImage orderId:orderId showHUDAddedTo:view successBlock:successBlock failureBlock:failureBlock];
    } else {
        successBlock();
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
        if (lineItemsArray.any(^BOOL(LineItem *lineItem) {
            return lineItem.inserted;
        })) {
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
            Order *asyncOrder = [OrderManager load:@"Order" withId:order.objectID fromContext:[CurrentSession privateQueueContext]];
            [asyncOrder setValuesForKeysWithDictionary:orderProperties];

            for (NSArray *lineItemIdAndProps in insertedLineProperties) {
                NSManagedObjectID *objectID = [[NSNull null] isEqual:lineItemIdAndProps[0]] ? nil : lineItemIdAndProps[0];
                NSDictionary *lineItemProperties = lineItemIdAndProps[1];
                LineItem *asyncLineItem = [OrderManager load:@"LineItem" withId:objectID fromContext:[CurrentSession privateQueueContext]];
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
        [OrderManager saveOrder:order inContext:order.managedObjectContext];
        if (successBlock) successBlock();
    }
}

+ (void)saveOrder:(Order *)order inContext:(NSManagedObjectContext *)context {
    NSLog(@"Saving Order");
    // we're about to save, we will consider this order out-of-sync with the server regardless of it's actual state
    // outside of the transient properties
    // we don't want to flip the sync flag if the sync value had just been changed to YES (a sync just occurred)

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
            [[CinchJSONAPIClient sharedInstance] DELETE: [NSString stringWithFormat:kDBORDEREDITS, [[[CurrentSession instance] showId] intValue], [order.orderId intValue]]  parameters:@{kAuthToken : [CurrentSession instance].authToken} success:^(NSURLSessionDataTask *task, id JSON) {
                [[CoreDataUtil sharedManager] deleteObject:order];
                if (successBlock) successBlock();
            }                                   failure:^(NSURLSessionDataTask *task, NSError *error) {
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

+ (void)syncOrderParameters:(NSMutableDictionary *)parameters
                      order:(Order *)order
                       view:(UIView *)view
                        url:(NSString *)url
               successBlock:(void (^)(id JSON))successBlock
               failureBlock:(void (^)())failureBlock {
    NSLog(@"Syncing Order");

    MBProgressHUD *submit = [MBProgressHUD showHUDAddedTo:view animated:NO];

    submit.removeFromSuperViewOnHide = YES;
    submit.labelText = @"Saving Order";

    NSString *method = [order.orderId intValue] > 0 ? @"PUT" : @"POST";
    parameters[kAuthToken] = [CurrentSession instance].authToken;
    parameters[@"vendor_id"] = [CurrentSession instance].vendorId;

    void(^saveBlock)(id) = ^(id JSON) {
        [[CurrentSession mainQueueContext] performBlock:^{
            [submit hide:NO];
            successBlock(JSON);
        }];
    };

    if (order.hasNontransientChanges || !order.inSync || parameters[@"send_email_to"]) {

        [ApiDataService sendRequest:method
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
                               [CIAlertView alertErrorEvent:[error localizedDescription]];
                               NSLog(@"%@ Error Syncing Order: %@", [self class], [error localizedDescription]);
                           }
                       }
                               view:nil
                        loadingText:@"Saving Order"];
    } else {
        [submit hide:NO];
        successBlock(nil);
    }
}


+ (void)sendSignature:(UIImage *)signature
              orderId:(NSNumber *)orderId
       showHUDAddedTo:(UIView *)view
         successBlock:(void (^)())successBlock
         failureBlock:(void (^)(NSError *error))failureBlock {
    NSData *imageData = nil;
    imageData = UIImagePNGRepresentation(signature);
    if (imageData) {
        MBProgressHUD *submit = [MBProgressHUD showHUDAddedTo:view animated:YES];
        submit.removeFromSuperViewOnHide = YES;
        submit.labelText = @"Saving Signature";
        [submit show:NO];

        [[CinchJSONAPIClient sharedInstanceWithJSONRequestSerialization] POST: [NSString stringWithFormat: kDBCAPTURESIG, [orderId intValue]]
                                                                   parameters:@{kAuthToken : [CurrentSession instance].authToken}
                                                    constructingBodyWithBlock:^(id <AFMultipartFormData> formData) {
                                                        [formData appendPartWithFileData:imageData name:@"signature" fileName:@"signature" mimeType:@"image/png"];
                                                    } success:^(NSURLSessionDataTask *task, id JSON) {
                    [submit hide:NO];
                    if (successBlock) successBlock();
                }                                                     failure:^(NSURLSessionDataTask *task, NSError *error) {
                    [submit hide:NO];
                    if (failureBlock) failureBlock(error);
                    NSInteger statusCode = [[error userInfo][AFNetworkingOperationFailingURLResponseErrorKey] statusCode];
                    NSString *alertMessage = [NSString stringWithFormat:@"There was an error processing this request. Status Code: %d", statusCode];
                    [[[UIAlertView alloc] initWithTitle:@"Error!" message:alertMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                }];
    } else {
        [[[UIAlertView alloc] initWithTitle:@"Error!" message:@"There was an error in capturing your signature. Please try again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }
}

@end