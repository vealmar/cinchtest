//
// Created by David Jafari on 6/10/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import "JSONResponseSerializerWithErrorData.h"

@implementation JSONResponseSerializerWithErrorData

- (id)responseObjectForResponse:(NSURLResponse *)response
                           data:(NSData *)data
                          error:(NSError *__autoreleasing *)error
{
    id JSONObject = [super responseObjectForResponse:response data:data error:error];

    if (*error != nil) {
        NSMutableDictionary *userInfo = [(*error).userInfo mutableCopy];
        if (data == nil) {
            userInfo[JSONResponseSerializerWithErrorDataKey] = nil;
        } else if (JSONObject != nil) {
            userInfo[JSONResponseSerializerWithErrorDataKey] = JSONObject;
        }
        NSError *newError = [NSError errorWithDomain:(*error).domain code:(*error).code userInfo:userInfo];
        (*error) = newError;
    }

    return (JSONObject);
}

@end