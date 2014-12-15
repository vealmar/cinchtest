//
// Created by David Jafari on 12/14/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface CurrentSession : NSObject

@property NSString *authToken;
@property NSDictionary* vendorInfo;

+(CurrentSession *)instance;
- (void)dispatchSessionDidChange;

@end