//
// Created by David Jafari on 12/24/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CITableViewController.h"
#import "PullToRefreshView.h"
#import "CICoreDataTableViewController.h"

@class Order;

@interface CIOrdersTableViewController : CICoreDataTableViewController <PullToRefreshViewDelegate>

@property (readonly) BOOL hasOrders;

- (void)filterToQueryTerm:(NSString *)query;

/**
* Selects the given order. If nil, selects the first one.
*/
- (void)selectOrder:(NSManagedObjectID *)order;

@end