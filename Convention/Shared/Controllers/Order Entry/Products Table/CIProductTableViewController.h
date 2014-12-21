//
// Created by David Jafari on 12/20/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CoreDataTableViewController.h"
#import "CITableViewController.h"
#import "PullToRefreshView.h"

@protocol ProductCellDelegate;

@interface CIProductTableViewController : CITableViewController <PullToRefreshViewDelegate>

- (void)prepareForDisplay:(id<ProductCellDelegate>)delegate;

- (void)filterToVendorId:(int)vendorId bulletinId:(int)bulletinId queryTerm:(NSString *)query;

@end