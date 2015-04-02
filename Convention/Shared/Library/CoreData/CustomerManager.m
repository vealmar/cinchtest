//
// Created by David Jafari on 2/17/15.
// Copyright (c) 2015 Urban Coding. All rights reserved.
//

#import "CustomerManager.h"
#import "Customer.h"
#import "CIAlertView.h"
#import "ApiDataService.h"
#import "CurrentSession.h"
#import "config.h"
#import "MBProgressHUD.h"
#import "SettingsManager.h"


@implementation CustomerManager

+ (void)syncNewCustomer:(NSDictionary *)customerParameters
                  attachHudTo:(UIView *)view
                    onSuccess:(void (^)(Customer *))successBlock
                    onFailure:(void (^)())failureBlock {

    NSString *url = [NSString stringWithFormat:kDBGETCUSTOMERS, [[[CurrentSession instance] showId] intValue] ];

    void(^saveBlock)(id) = ^(id JSON) {
        [[CurrentSession mainQueueContext] performBlock:^{
            if (JSON) {
                Customer *newCustomer = [[Customer alloc] initWithCustomerFromServer:JSON context:[CurrentSession mainQueueContext]];
                [[CurrentSession mainQueueContext] insertObject:newCustomer];
                [[CurrentSession mainQueueContext] save:nil];
                successBlock(newCustomer);
            } else {
                failureBlock();
            }
        }];
    };

    NSString *method = @"POST";
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary:customerParameters];
    parameters[kAuthToken] = [CurrentSession instance].authToken;

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
//                           [submit hide:NO];
                           if (failureBlock) failureBlock();
                           [CIAlertView alertErrorEvent:[error localizedDescription]];
                           NSLog(@"%@ Error Syncing Customer: %@", [self class], [error localizedDescription]);
                       }
                   }
                           view:view
                    loadingText:@"Creating Customer"];

}

//+ (void)saveOrder:(Customer *)customer
//        onSuccess:(void (^)())successBlock {
//
//}


@end