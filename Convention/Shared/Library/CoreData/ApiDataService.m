//
// Created by David Jafari on 2/17/15.
// Copyright (c) 2015 Urban Coding. All rights reserved.
//

#import "ApiDataService.h"
#import "MBProgressHUD.h"
#import "CinchJSONAPIClient.h"
#import "config.h"
#import "SettingsManager.h"


@implementation ApiDataService

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
    NSMutableURLRequest *request = [client.requestSerializer requestWithMethod:httpMethod URLString:[NSString stringWithFormat:@"%@%@", [[SettingsManager sharedManager] getServerUrl], url] parameters:parameters error:nil];
    __block NSURLSessionDataTask *task = [client dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id json, NSError *error) {
        if (error) {
            if (submit) [submit hide:NO];
            if (failureBlock) failureBlock(request, (NSHTTPURLResponse *)response, error, json);
            NSInteger statusCode = [[error userInfo][AFNetworkingOperationFailingURLResponseErrorKey] statusCode];
            NSString *alertMessage = [NSString stringWithFormat:@"There was an error processing this request. Status Code: %d", statusCode];
            if (statusCode == 422) {
                NSArray *validationErrors = json ? ((NSDictionary *) json)[kErrors] : nil;
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