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

@end