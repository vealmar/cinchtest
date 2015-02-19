//
// Created by David Jafari on 2/17/15.
// Copyright (c) 2015 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Customer;


@interface CustomerManager : NSObject

// Saves customer locally, if it exists, and then submits it to the server, syncing and saving any returned changes.
+ (void)syncNewCustomer:(NSDictionary *)customerParameters
      attachHudTo:(UIView *)view
        onSuccess:(void (^)(Customer *))successBlock
        onFailure:(void (^)())failureBlock;

// Saves customer locally
//+ (void)saveOrder:(Customer *)customer
//        onSuccess:(void (^)())successBlock;

@end