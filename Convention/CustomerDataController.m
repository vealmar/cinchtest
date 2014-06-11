//
//  CustomerDataController.m
//  Convention
//
//  Created by Kerry Sanders on 11/18/12.
//  Copyright (c) 2012 MotionMobs. All rights reserved.
//

#import "CustomerDataController.h"
#import "config.h"
#import "SettingsManager.h"
#import "NotificationConstants.h"
#import "CinchJSONAPIClient.h"

@implementation CustomerDataController

+ (void)loadCustomers:(NSString *)authToken {
    void(^finish)(NSArray *) = ^(NSArray *customers) {
        NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] initWithCapacity:1];
        if (customers) {
            [userInfo setObject:customers forKey:kCustomerUserInfoKey];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:CustomersLoadedNotification object:nil userInfo:(NSDictionary *) userInfo];
    };

    [[CinchJSONAPIClient sharedInstance] GET:kDBGETCUSTOMERS parameters:@{ kAuthToken: authToken } success:^(NSURLSessionDataTask *task, id JSON) {
        finish(JSON);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        finish(nil);
    }];
}

@end
