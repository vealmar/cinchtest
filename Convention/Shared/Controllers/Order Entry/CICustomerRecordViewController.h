//
// Created by David Jafari on 2/17/15.
// Copyright (c) 2015 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CIModalFormViewController.h"

@class Customer;

@interface CICustomerRecordViewController : CIModalFormViewController

-(void)prepareForDisplay:(Customer *)customer;

@end