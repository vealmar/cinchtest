//
// Created by David Jafari on 6/10/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import "CinchJSONAPIClient.h"
#import "config.h"
#import "SettingsManager.h"
#import "JSONResponseSerializerWithErrorData.h"

@implementation CinchJSONAPIClient

+ (CinchJSONAPIClient *)sharedInstance {
    static CinchJSONAPIClient *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [self newInstance:nil];
    });
    return _sharedInstance;
}

+ (CinchJSONAPIClient *)sharedInstanceWithJSONRequestSerialization {
    static CinchJSONAPIClient *_sharedInstanceWithJSON = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        AFJSONRequestSerializer *requestSerializer = [AFJSONRequestSerializer serializerWithWritingOptions:NSJSONWritingPrettyPrinted];
        _sharedInstanceWithJSON = [self newInstance:requestSerializer];
    });
    return _sharedInstanceWithJSON;
}

+ (CinchJSONAPIClient *)newInstance:(AFJSONRequestSerializer *)requestSerializer {
    CinchJSONAPIClient *client = [[CinchJSONAPIClient alloc] initWithBaseURL:[NSURL URLWithString:kBASEURL]];
    [client setSecurityPolicy:[AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone]];
    [client setResponseSerializer:[JSONResponseSerializerWithErrorData serializer]];

    if (requestSerializer) {
        [client setRequestSerializer:requestSerializer];
    }
    client.requestSerializer.timeoutInterval = 150;
    [client.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];

    [client.reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        switch (status) {
            case AFNetworkReachabilityStatusReachableViaWWAN:
            case AFNetworkReachabilityStatusReachableViaWiFi:
                [client.operationQueue setSuspended:NO];
                break;
            case AFNetworkReachabilityStatusNotReachable:
            default:
                [client.operationQueue setSuspended:YES];
                break;
        }
    }];

    return client;
}

- (void)log:(NSString *)method request:(NSString *)URLString parameters:(id)parameters {
    NSLog(@"[API] %@ %@", method, URLString);
}

- (NSURLSessionDataTask *)GET:(NSString *)URLString parameters:(id)parameters success:(void (^)(NSURLSessionDataTask *task, id responseObject))success failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure {
    [self log:@"GET" request:URLString parameters:parameters];
    return [super GET:URLString parameters:parameters success:success failure:failure];
}

- (NSURLSessionDataTask *)HEAD:(NSString *)URLString parameters:(id)parameters success:(void (^)(NSURLSessionDataTask *task))success failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure {
    [self log:@"HEAD" request:URLString parameters:parameters];
    return [super HEAD:URLString parameters:parameters success:success failure:failure];
}

- (NSURLSessionDataTask *)POST:(NSString *)URLString parameters:(id)parameters success:(void (^)(NSURLSessionDataTask *task, id responseObject))success failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure {
    [self log:@"POST" request:URLString parameters:parameters];
    return [super POST:URLString parameters:parameters success:success failure:failure];
}

- (NSURLSessionDataTask *)POST:(NSString *)URLString parameters:(id)parameters constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block success:(void (^)(NSURLSessionDataTask *task, id responseObject))success failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure {
    [self log:@"POST" request:URLString parameters:parameters];
    return [super POST:URLString parameters:parameters constructingBodyWithBlock:block success:success failure:failure];
}

- (NSURLSessionDataTask *)PUT:(NSString *)URLString parameters:(id)parameters success:(void (^)(NSURLSessionDataTask *task, id responseObject))success failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure {
    [self log:@"PUT" request:URLString parameters:parameters];
    return [super PUT:URLString parameters:parameters success:success failure:failure];
}

- (NSURLSessionDataTask *)PATCH:(NSString *)URLString parameters:(id)parameters success:(void (^)(NSURLSessionDataTask *task, id responseObject))success failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure {
    [self log:@"PATCH" request:URLString parameters:parameters];
    return [super PATCH:URLString parameters:parameters success:success failure:failure];
}

- (NSURLSessionDataTask *)DELETE:(NSString *)URLString parameters:(id)parameters success:(void (^)(NSURLSessionDataTask *task, id responseObject))success failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure {
    [self log:@"DELETE" request:URLString parameters:parameters];
    return [super DELETE:URLString parameters:parameters success:success failure:failure];
}


@end