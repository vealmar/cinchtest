//
// Created by David Jafari on 2/6/15.
// Copyright (c) 2015 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CISelectRecordViewController.h"

@interface CISelectVendorViewController : CISelectRecordViewController

@property (nonatomic, copy) void (^onComplete)();

@end