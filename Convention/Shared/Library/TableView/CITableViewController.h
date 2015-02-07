//
// Created by David Jafari on 12/20/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CITableViewHeaderView;
@class CITableViewColumns;

@interface CITableViewController : UITableViewController

@property IBOutlet CITableViewHeaderView *header;
@property CITableViewColumns *columns;
@property NSArray *fixedData;

- (NSArray *)currentSortDescriptors;
- (id)objectAtIndexPath:(NSIndexPath *)indexPath;
- (void)prepareForDisplay;

@end

@interface CITableViewController(AbstractMethods)

- (CITableViewColumns *)createColumns;

@end