//
// Created by David Jafari on 2/6/15.
// Copyright (c) 2015 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CICoreDataTableViewController.h"

@protocol CISelectRecordDelegate <NSObject>

- (void)recordSelected:(NSManagedObject *)object;

@end

@interface CISelectRecordTableViewController : CICoreDataTableViewController

@property(nonatomic, assign) id <CISelectRecordDelegate> delegate;

- (NSFetchRequest *)query:(NSString *)queryString;

@end