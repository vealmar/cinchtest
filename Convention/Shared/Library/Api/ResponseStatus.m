//
// Created by David Jafari on 2/8/15.
// Copyright (c) 2015 Urban Coding. All rights reserved.
//

#import "ResponseStatus.h"

@implementation ResponseStatus

+ (ResponseStatusType)statusOfTask:(NSURLSessionDataTask *)dataTask {
    switch (dataTask.state) {
        case NSURLSessionTaskStateCanceling: return ResponseStatusTypeCancelling;
        case NSURLSessionTaskStateSuspended: return ResponseStatusTypeSuspended;
        case NSURLSessionTaskStateRunning: return ResponseStatusTypeInProgress;
        case NSURLSessionTaskStateCompleted: {
            if ([dataTask.response isKindOfClass:[NSHTTPURLResponse class]]) {
                return [self statusOfResponse:((NSHTTPURLResponse *) dataTask.response)];
            } else {
                return ResponseStatusTypeUnknown;
            }
        }
    }

    return ResponseStatusTypeUnknown;
}

+ (ResponseStatusType)statusOfResponse:(NSHTTPURLResponse *)response {
    switch (response.statusCode) {
        case 200: return ResponseStatusTypeSuccess;
        case 201: return ResponseStatusTypeCreated;
        case 202: return ResponseStatusTypeAccepted;
        case 204: return ResponseStatusTypeNoContent;
        case 304: return ResponseStatusTypeNotModified;
        case 400: return ResponseStatusTypeBadRequest;
        case 401: return ResponseStatusTypeUnauthorized;
        case 403: return ResponseStatusTypeForbidden;
        case 405: return ResponseStatusTypeMethodNotAllowed;
        case 408: return ResponseStatusTypeRequestTimeout;
        case 409: return ResponseStatusTypeConflict;
        case 500: return ResponseStatusTypeInternalServerError;
        case 501: return ResponseStatusTypeNotImplemented;
        case 503: return ResponseStatusTypeServiceUnavailable;
    }

    return ResponseStatusTypeUnknown;
}

@end