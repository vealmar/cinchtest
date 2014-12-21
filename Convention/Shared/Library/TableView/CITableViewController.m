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

- (void)prepareForDisplay:(NSManagedObjectContext *)managedObjectContext {
    self.columns = [self createColumns];
    self.managedObjectContext = managedObjectContext;
    self.fetchRequest = [self initialFetchRequest];

    if (self.header) {
        [self.header prepareForDisplay:self.columns];
    }
}

- (NSFetchRequest *)fetchRequest {
    return self.fetchedResultsController.fetchRequest;
}

- (void)setFetchRequest:(NSFetchRequest *)fetchRequest {
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                        managedObjectContext:self.managedObjectContext
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil];
}

- (CITableViewColumns *)createColumns {
    CITableViewColumns *columns = [CITableViewColumns new];
    return columns;
}

- (NSFetchRequest *)initialFetchRequest {
    assert(false);
    return nil;
}

#pragma UITableViewDelegate

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([cell isKindOfClass:[CITableViewCell class]]) {
        [((CITableViewCell *)cell) updateRowHighlight:indexPath];
    }
}

@end