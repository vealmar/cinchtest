//
// Created by David Jafari on 12/24/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Order;


@interface OrderCoreDataManager : NSObject

+ (NSFetchRequest *)buildOrderFetch:(NSString *)queryString
             inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

// Reloads all orders from the server, overwriting any local changes. By default, this will only
// request changes since the last reload.
+ (void)reloadOrders:(BOOL)partialReturn
           onSuccess:(void (^)())successBlock
           onFailure:(void (^)())failureBlock;

// Retrieves an order from the server. If it exists locally, it is overwritten. Otherwise, it is inserted.
+ (void)fetchOrder:(NSNumber *)orderId
       attachHudTo:(UIView *)view
         onSuccess:(void (^)(Order *order))successBlock
         onFailure:(void (^)())failureBlock;

// Saves order locally and then submits it to the server, syncing any returned changes.
+ (void)syncOrder:(Order *)order
      attachHudTo:(UIView *)view
        onSuccess:(void (^)(Order *order))successBlock
        onFailure:(void (^)())failureBlock;

// Saves order locally. May optionally perform this save asynchronously in a background thread if no insert/delete
// operations are required.
+ (void)saveOrder:(Order *)order
            async:(BOOL)shouldAsync
       beforeSave:(void (^)(Order *order))threadsafeOrderOperationBlock
        onSuccess:(void (^)())successBlock;

// Saves order locally.
+ (void)saveOrder:(Order *)order
        inContext:(NSManagedObjectContext *)context;

// Deletes order locally and on the server if it's ever been synced.
+ (void)deleteOrder:(Order *)order
          onSuccess:(void (^)())successBlock
          onFailure:(void (^)())failureBlock;

@end