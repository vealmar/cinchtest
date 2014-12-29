//
// Created by David Jafari on 12/24/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Order;


@interface OrderCoreDataManager : NSObject

+ (NSFetchRequest *)buildOrderFetch:(NSString *)queryString
             inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

+ (void)reloadOrders:(BOOL)partialReturn
           onSuccess:(void (^)())successBlock
           onFailure:(void (^)())failureBlock;

+ (void)syncOrder:(Order *)order
      attachHudTo:(UIView *)view
        onSuccess:(void (^)(Order *order))successBlock
        onFailure:(void (^)())failureBlock;

+ (void)saveOrder:(Order *)order
            async:(BOOL)shouldAsync
       beforeSave:(void (^)(Order *order))threadsafeOrderOperationBlock
        onSuccess:(void (^)())successBlock;

+ (void)saveOrder:(Order *)order
        inContext:(NSManagedObjectContext *)context;

+ (void)deleteOrder:(Order *)order
          onSuccess:(void (^)())successBlock
          onFailure:(void (^)())failureBlock;

@end