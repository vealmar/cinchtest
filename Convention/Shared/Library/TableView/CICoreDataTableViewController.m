    //
//  CoreDataTableViewController.m
//
//  Created for Stanford CS193p Fall 2013.
//  Copyright 2013 Stanford University. All rights reserved.
//

#import "CICoreDataTableViewController.h"
#import "CurrentSession.h"
#import "CITableViewCell.h"

@interface CICoreDataTableViewController ()

@property BOOL pauseUpdates;
@property NSMutableArray *pendingContextMerges;

@end

@implementation CICoreDataTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.pendingContextMerges = [NSMutableArray array];
    self.pauseUpdates = NO;
}

- (void)prepareForDisplay {
    [super prepareForDisplay];
    // use our own separate context so we can control merges from other context
    self.managedObjectContext = [CurrentSession mainQueueContext];
    self.fetchRequest = [self initialFetchRequest];
}

- (void)pauseContextUpdates {
//    self.pauseUpdates = YES;
}

- (void)resumeContextUpdates {
    self.pauseUpdates = NO;
}

- (NSFetchRequest *)fetchRequest {
    return self.fetchedResultsController ? self.fetchedResultsController.fetchRequest : nil;
}

- (void)setFetchRequest:(NSFetchRequest *)fetchRequest {
    if (!self.managedObjectContext) {
        [NSException raise:NSObjectNotAvailableException format:@"Cannot set a NSFetchRequest until context has been created."];
    }
    if (fetchRequest) {
        self.fetchedResultsController = [self initializeFetchedResultsController:fetchRequest];
    } else {
        self.fetchedResultsController = nil;
    }
}

- (NSFetchedResultsController *)initializeFetchedResultsController:(NSFetchRequest *)fetchRequest {
    return [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                               managedObjectContext:self.managedObjectContext
                                                 sectionNameKeyPath:nil
                                                          cacheName:nil];
}

- (NSFetchRequest *)initialFetchRequest {
    assert(false);
    return nil;
}

#pragma mark - Fetching

- (void)performFetch
{
    if (self.fetchedResultsController) {
        if (self.fetchedResultsController.fetchRequest.predicate) {
            if (self.debug) NSLog(@"[%@ %@] fetching %@ with predicate: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), self.fetchedResultsController.fetchRequest.entityName, self.fetchedResultsController.fetchRequest.predicate);
        } else {
            if (self.debug) NSLog(@"[%@ %@] fetching all %@ (i.e., no predicate)", NSStringFromClass([self class]), NSStringFromSelector(_cmd), self.fetchedResultsController.fetchRequest.entityName);
        }
        NSError *error;
        BOOL success = [self.fetchedResultsController performFetch:&error];
        if (!success) NSLog(@"[%@ %@] performFetch: failed", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
        if (error) NSLog(@"[%@ %@] %@ (%@)", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [error localizedDescription], [error localizedFailureReason]);
    } else {
        if (self.debug) NSLog(@"[%@ %@] no NSFetchedResultsController (yet?)", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    }
    [self.tableView reloadData];
}

- (void)setFetchedResultsController:(NSFetchedResultsController *)newfrc
{
    NSFetchedResultsController *oldfrc = _fetchedResultsController;
    if (newfrc != oldfrc) {
        _fetchedResultsController = newfrc;
        newfrc.delegate = self;
        if ((!self.title || [self.title isEqualToString:oldfrc.fetchRequest.entity.name]) && (!self.navigationController || !self.navigationItem.title)) {
            self.title = newfrc.fetchRequest.entity.name;
        }
        if (newfrc) {
            if (self.debug) NSLog(@"[%@ %@] %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), oldfrc ? @"updated" : @"set");
            [self performFetch];
        } else {
            if (self.debug) NSLog(@"[%@ %@] reset to nil", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
            [self.tableView reloadData];
        }
    }
}

- (id)objectAtIndexPath:(NSIndexPath *)indexPath {
    return [self.fetchedResultsController objectAtIndexPath:indexPath];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.fetchedResultsController) {
        return [[self.fetchedResultsController sections] count];
    } else {
        return 0;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger rows = 0;
    if (self.fetchedResultsController && [[self.fetchedResultsController sections] count] > 0) {
        id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
        rows = [sectionInfo numberOfObjects];
    }
    return rows;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return self.fetchedResultsController ? [[[self.fetchedResultsController sections] objectAtIndex:section] name] : nil;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    return self.fetchedResultsController ? [self.fetchedResultsController sectionForSectionIndexTitle:title atIndex:index] : 0;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return self.fetchedResultsController ? [self.fetchedResultsController sectionIndexTitles] : nil;
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self pauseContextUpdates];
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type)
    {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationNone];
            break;

        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationNone];
            break;
    }
}


- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    switch(type)
    {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationNone];
            break;

        case NSFetchedResultsChangeDelete:
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
            break;

        case NSFetchedResultsChangeUpdate:
            [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;

        case NSFetchedResultsChangeMove:
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    @try {
        [self.tableView endUpdates];
        [self resumeContextUpdates];
    }
    @catch (NSException *exception) {
//        if (exception.name == NSInternalInconsistencyException) {
//            // there was an update in a background thread with changes that were just merged in
//        } else {
            @throw exception;
//        }
    }
    
}

@end