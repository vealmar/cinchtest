//
// Created by David Jafari on 12/14/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import "CurrentSession.h"
#import "NotificationConstants.h"


@implementation CurrentSession

static CurrentSession *currentSession = nil;

+ (CurrentSession *)instance {
    if (nil == currentSession) {
        currentSession = [CurrentSession new];
    }
    return currentSession;
}

- (void)dispatchSessionDidChange {
    [[NSNotificationCenter defaultCenter] postNotificationName:SessionDidChangeNotification object:self];
}


@end