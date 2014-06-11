//
// Created by David Jafari on 6/10/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFHTTPSessionManager.h"


@interface CinchJSONAPIClient : AFHTTPSessionManager

+ (CinchJSONAPIClient *)sharedInstance;
+ (CinchJSONAPIClient *)sharedInstanceWithJSONRequestSerialization;

@end