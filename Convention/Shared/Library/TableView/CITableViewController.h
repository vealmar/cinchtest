//
// Created by David Jafari on 12/20/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CoreDataTableViewController.h"

@class CITableViewHeader;
@class CITableViewColumns;

@interface CITableViewController : CoreDataTableViewController

@property IBOutlet CITableViewHeader *header;

@property CITableViewColumns *columns;
@property NSManagedObjectContext *managedObjectContext;
@property NSFetchRequest *fetchRequest;

- (void)prepareForDisplay:(NSManagedObjectContext *)managedObjectContext;

@end

@interface CITableViewController(AbstractMethods)

- (CITableViewColumns *)createColumns;
- (NSFetchRequest *)initialFetchRequest;

@end