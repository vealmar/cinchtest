//
// Created by David Jafari on 2/17/15.
// Copyright (c) 2015 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ApiDataService : NSObject

+ (void)sendRequest:(NSString *)httpMethod url:(NSString *)url parameters:(NSDictionary *)parameters
       successBlock:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, id JSON))successBlock
       failureBlock:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON))failureBlock
               view:(UIView *)hudView loadingText:(NSString *)loadingText;

@end