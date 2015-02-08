//
// Created by David Jafari on 2/6/15.
// Copyright (c) 2015 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CurrentSession;

typedef enum  {
    VendorDataTypeCustomers,
    VendorDataTypeBulletins,
    VendorDataTypeVendors,
    VendorDataTypeProducts
} VendorDataType;

@interface VendorDataLoader : NSObject

+ (VendorDataLoader *)load:(NSArray *)dataTypes inView:(UIView *)view onComplete:(void (^)())onComplete;

@end