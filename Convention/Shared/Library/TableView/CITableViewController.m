//
// Created by David Jafari on 12/20/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import "CITableViewController.h"
#import "CITableViewColumns.h"
#import "CITableViewHeader.h"
#import "CITableViewCell.h"

@interface CITableViewController()

@end

@implementation CITableViewController

- (void)prepareForDisplay {
    [super prepareForDisplay];
    self.columns = [self createColumns];

    if (self.header) {
        [self.header prepareForDisplay:self.columns];
    }
}

- (CITableViewColumns *)createColumns {
    CITableViewColumns *columns = [CITableViewColumns new];
    return columns;
}

#pragma UITableViewDelegate

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([cell isKindOfClass:[CITableViewCell class]]) {
        [((CITableViewCell *)cell) updateRowHighlight:indexPath];
    }
}

@end