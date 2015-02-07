//
// Created by David Jafari on 12/20/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CICoreDataTableViewController.h"
#import "CITableViewController.h"
#import "PullToRefreshView.h"
#import "CITableSortDelegate.h"

@protocol ProductCellDelegate;

@interface CIProductTableViewController : CICoreDataTableViewController <PullToRefreshViewDelegate, CITableSortDelegate>

- (void)prepareForDisplay:(id<ProductCellDelegate>)delegate;

- (void)filterToVendorId:(int)vendorId bulletinId:(int)bulletinId inCart:(BOOL)inCart queryTerm:(NSString *)query;

@end