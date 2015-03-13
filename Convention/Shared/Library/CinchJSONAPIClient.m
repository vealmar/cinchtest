//
// Created by David Jafari on 6/10/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import "CinchJSONAPIClient.h"
#import "config.h"
#import "SettingsManager.h"
#import "JSONResponseSerializerWithErrorData.h"

@interface CinchJSONAPIClient ()

@property AFHTTPSessionManager *sessionManager;

@end

@implementation CinchJSONAPIClient


- (AFHTTPRequestSerializer <AFURLRequestSerialization> *)requestSerializer {
    return self.sessionManager.requestSerializer;
}

- (void)setRequestSerializer:(AFHTTPRequestSerializer <AFURLRequestSerialization> *)requestSerializer {
    self.sessionManager.requestSerializer = requestSerializer;
}

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

/**
* When the server url in the app's settings is changed, reload needs to be called on the existing CinchJSONAPIClient instances (there can be at most two instances, one with serializer one without).
* Reload will recreate the internal AFHTTPSessionManager with the new url.
*/
- (void)reload {
    //If the manager instance had a serializer, make sure we maintain the serializer in the new manager instance.
    self.sessionManager = [CinchJSONAPIClient createSessionManager:self.sessionManager.requestSerializer];
}

+ (CinchJSONAPIClient *)newInstance:(AFJSONRequestSerializer *)requestSerializer {
    CinchJSONAPIClient *cinchClient = [[CinchJSONAPIClient alloc] init];
    cinchClient.sessionManager = [self createSessionManager:requestSerializer];
    return cinchClient;
}

+ (AFHTTPSessionManager *)createSessionManager:(AFJSONRequestSerializer *)requestSerializer {
    AFHTTPSessionManager *afManager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:kBASEURL]];
    [afManager setSecurityPolicy:[AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone]];
    [afManager setResponseSerializer:[JSONResponseSerializerWithErrorData serializer]];
    if (requestSerializer) {
        [afManager setRequestSerializer:requestSerializer];
    }
    afManager.requestSerializer.timeoutInterval = 150;
    [afManager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [afManager.reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        switch (status) {
            case AFNetworkReachabilityStatusReachableViaWWAN:
            case AFNetworkReachabilityStatusReachableViaWiFi:
                [afManager.operationQueue setSuspended:NO];
                break;
            case AFNetworkReachabilityStatusNotReachable:
            default:
                [afManager.operationQueue setSuspended:YES];
                break;
        }
    }];
    return afManager;
}

- (void)log:(NSString *)method request:(NSString *)URLString parameters:(id)parameters {
    NSLog(@"[API] %@ %@", method, URLString);
}

- (NSURLSessionDataTask *)GET:(NSString *)URLString parameters:(id)parameters success:(void (^)(NSURLSessionDataTask *task, id responseObject))success failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure {
    [self log:@"GET" request:URLString parameters:parameters];
    return [self.sessionManager GET:URLString parameters:parameters success:success failure:failure];
}

- (NSURLSessionDataTask *)HEAD:(NSString *)URLString parameters:(id)parameters success:(void (^)(NSURLSessionDataTask *task))success failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure {
    [self log:@"HEAD" request:URLString parameters:parameters];
    return [self.sessionManager HEAD:URLString parameters:parameters success:success failure:failure];
}

- (NSURLSessionDataTask *)POST:(NSString *)URLString parameters:(id)parameters success:(void (^)(NSURLSessionDataTask *task, id responseObject))success failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure {
    [self log:@"POST" request:URLString parameters:parameters];
    return [self.sessionManager POST:URLString parameters:parameters success:success failure:failure];
}

- (NSURLSessionDataTask *)POST:(NSString *)URLString parameters:(id)parameters constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block success:(void (^)(NSURLSessionDataTask *task, id responseObject))success failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure {
    [self log:@"POST" request:URLString parameters:parameters];
    return [self.sessionManager POST:URLString parameters:parameters constructingBodyWithBlock:block success:success failure:failure];
}

- (NSURLSessionDataTask *)PUT:(NSString *)URLString parameters:(id)parameters success:(void (^)(NSURLSessionDataTask *task, id responseObject))success failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure {
    [self log:@"PUT" request:URLString parameters:parameters];
    return [self.sessionManager PUT:URLString parameters:parameters success:success failure:failure];
}

- (NSURLSessionDataTask *)PATCH:(NSString *)URLString parameters:(id)parameters success:(void (^)(NSURLSessionDataTask *task, id responseObject))success failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure {
    [self log:@"PATCH" request:URLString parameters:parameters];
    return [self.sessionManager PATCH:URLString parameters:parameters success:success failure:failure];
}

- (NSURLSessionDataTask *)DELETE:(NSString *)URLString parameters:(id)parameters success:(void (^)(NSURLSessionDataTask *task, id responseObject))success failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure {
    [self log:@"DELETE" request:URLString parameters:parameters];
    return [self.sessionManager DELETE:URLString parameters:parameters success:success failure:failure];
}

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSMutableURLRequest *)request completionHandler:(void (^)(NSURLResponse *, id, NSError *))handler {
    return [self.sessionManager dataTaskWithRequest:request completionHandler:handler];
}
@end