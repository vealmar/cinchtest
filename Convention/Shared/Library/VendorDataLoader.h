//
// Created by David Jafari on 2/6/15.
// Copyright (c) 2015 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CurrentSession;


@interface VendorDataLoader : NSObject

+ (VendorDataLoader *)load:(CurrentSession *)currentSession inView:(UIView *)view onComplete:(void (^)())onComplete;
+ (VendorDataLoader *)reload:(CurrentSession *)currentSession inView:(UIView *)view onComplete:(void (^)())onComplete;

@end