//
// Created by David Jafari on 2/8/15.
// Copyright (c) 2015 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    // meta-types - generic
    ResponseStatusTypeUnknown,

    // meta-types - request state
    ResponseStatusTypeCancelling,
    ResponseStatusTypeSuspended,
    ResponseStatusTypeInProgress,

    // http codes
    ResponseStatusTypeSuccess,
    ResponseStatusTypeCreated,
    ResponseStatusTypeAccepted,
    ResponseStatusTypeNoContent,
    ResponseStatusTypeNotModified,
    ResponseStatusTypeBadRequest,
    ResponseStatusTypeUnauthorized,
    ResponseStatusTypeForbidden,
    ResponseStatusTypeMethodNotAllowed,
    ResponseStatusTypeRequestTimeout,
    ResponseStatusTypeConflict,
    ResponseStatusTypeInternalServerError,
    ResponseStatusTypeNotImplemented,
    ResponseStatusTypeServiceUnavailable
} ResponseStatusType;

@interface ResponseStatus : NSObject

+ (ResponseStatusType)statusOfTask:(NSURLSessionDataTask *)dataTask;

@end