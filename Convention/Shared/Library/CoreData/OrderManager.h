//
// Created by David Jafari on 12/24/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Order;
@class NISignatureView;


@interface OrderManager : NSObject

+ (NSFetchRequest *)buildOrderFetch:(NSString *)queryString
             inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

// Reloads all orders from the server, overwriting any local changes. By default, this will only
// request changes since the last reload.
+ (void)reloadOrders:(BOOL)partialReturn
           onSuccess:(void (^)())successBlock
           onFailure:(void (^)())failureBlock;

+ (void)headOrder:(NSNumber *)orderId
        updatedAt:(NSDate *)updatedAt
        onSuccess:(void (^)())successBlock;

// Retrieves an order from the server. If it exists locally, it is overwritten. Otherwise, it is inserted.
+ (void)fetchOrder:(NSNumber *)orderId
       attachHudTo:(UIView *)view
         onSuccess:(void (^)(Order *order))successBlock
         onFailure:(void (^)())failureBlock;

// Saves order locally and then submits it to the server, syncing any returned changes.
+ (void)syncOrder:(Order *)order
      attachHudTo:(UIView *)view
        onSuccess:(void (^)())successBlock
        onFailure:(void (^)())failureBlock;

// Saves order locally and then submits only the order details to the server.
+ (void)syncOrderDetails:(Order *)order sendEmailTo:(NSString *)email attachHudTo:(UIView *)view onSuccess:(void (^)())successBlock onFailure:(void (^)())failureBlock;

// Saves order signature to the server.
+ (void)syncSignature:(NISignatureView *)signatureView
              orderId:(NSNumber *)orderId
       showHUDAddedTo:(UIView *)view
         successBlock:(void (^)())successBlock
         failureBlock:(void (^)(NSError *error))failureBlock;

// Saves order locally. May optionally perform this save asynchronously in a background thread if no insert/delete
// operations are required.
+ (void)saveOrder:(Order *)order
            async:(BOOL)shouldAsync
       beforeSave:(void (^)(Order *order))threadsafeOrderOperationBlock
        onSuccess:(void (^)())successBlock;

// Saves order locally.
+ (void)saveOrder:(Order *)order
        inContext:(NSManagedObjectContext *)context;

+ (id)load:(NSString *)name withId:(NSManagedObjectID *)objectID fromContext:(NSManagedObjectContext *)context;

// Deletes order locally and on the server if it's ever been synced.
+ (void)deleteOrder:(Order *)order
          onSuccess:(void (^)())successBlock
          onFailure:(void (^)())failureBlock;

@end