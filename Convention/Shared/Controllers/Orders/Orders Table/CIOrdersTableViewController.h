//
// Created by David Jafari on 12/24/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CITableViewController.h"
#import "PullToRefreshView.h"

@class Order;

@interface CIOrdersTableViewController : CoreDataTableViewController <PullToRefreshViewDelegate>

@property (readonly) BOOL hasOrders;

- (void)prepareForDisplay;

- (void)filterToQueryTerm:(NSString *)query;

/**
* Selects the given order. If nil, selects the first one.
*/
- (void)selectOrder:(Order *)order;

@end