//
// Created by septerr on 12/30/13.
// Copyright (c) 2013 Convention Innovations. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SynchronousResponse;


@interface SynchronousRequestUtil : NSObject

+ (SynchronousResponse *)sendRequestTo:(NSString *)url;

+ (SynchronousResponse *)sendRequestTo:(NSString *)url method:(NSString *)method parameters:(NSDictionary *)parameters;
@end