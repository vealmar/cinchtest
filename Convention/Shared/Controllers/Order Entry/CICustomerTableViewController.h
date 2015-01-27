//
// Created by David Jafari on 1/27/15.
// Copyright (c) 2015 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CICoreDataTableViewController.h"
#import "PullToRefreshView.h"


@interface CICustomerTableViewController : CICoreDataTableViewController <PullToRefreshViewDelegate>

- (NSFetchRequest *)queryCustomers:(NSString *)queryString;

@end