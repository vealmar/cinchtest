//
// Created by septerr on 12/30/13.
// Copyright (c) 2013 Convention Innovations. All rights reserved.
//

#import "SynchronousRequestUtil.h"
#import "SynchronousResponse.h"


@implementation SynchronousRequestUtil {

}
+ (SynchronousResponse *)sendRequestTo:(NSString *)url {
    return [self sendRequestTo:url method:@"GET" parameters:nil];
}

+ (SynchronousResponse *)sendRequestTo:(NSString *)url method:(NSString *)method parameters:(NSDictionary *)parameters {
    NSHTTPURLResponse *responseCode = nil;
    NSError *jsonParamError, *error, *jsonError;
    NSDictionary *json;
    NSURL *nsUrl = [NSURL URLWithString:url];
    NSData *requestParameters = parameters ? [NSJSONSerialization dataWithJSONObject:parameters options:0 error:&jsonParamError] : [[NSData alloc] init];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:nsUrl cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:50];
    [request setHTTPMethod:method];
    [request setHTTPBody:requestParameters];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&responseCode error:&error];
    if (data) {
        json = [self parseJson:data error:&jsonError];
    }
    return [[SynchronousResponse alloc] initWithStatusCode:[responseCode statusCode] andJson:json];
}

+ (NSDictionary *)parseJson:(NSData *)data error:(NSError **)error {
    return [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:error];
}

@end