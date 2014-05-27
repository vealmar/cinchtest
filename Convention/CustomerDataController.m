//
//  CustomerDataController.m
//  Convention
//
//  Created by Kerry Sanders on 11/18/12.
//  Copyright (c) 2012 MotionMobs. All rights reserved.
//

#import "CustomerDataController.h"
#import "config.h"
#import "AFJSONRequestOperation.h"
#import "SettingsManager.h"
#import "NotificationConstants.h"

@implementation CustomerDataController

+ (void)loadCustomers:(NSString *)authToken {
    NSString *url = [NSString stringWithFormat:@"%@?%@=%@", kDBGETCUSTOMERS, kAuthToken, authToken];

    void(^finish)(NSArray *) = ^(NSArray *customers) {
        NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] initWithCapacity:1];
        if (customers) {
            [userInfo setObject:customers forKey:kCustomerUserInfoKey];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:CustomersLoadedNotification object:nil userInfo:(NSDictionary *) userInfo];
    };

    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
            success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {

                finish(JSON);

            } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {

                finish(nil);
            }];

    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperation:operation];
}

@end
