//
// Created by David Jafari on 12/24/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import "CIOrdersTableViewController.h"
#import "CurrentSession.h"
#import "CIOrderCell.h"
#import "MBProgressHUD.h"
#import "UIAlertViewDelegateWithBlock.h"
#import "Order.h"
#import "OrderManager.h"
#import "Order+Extensions.h"
#import "NotificationConstants.h"
#import "CoreDataUtil.h"
#import "UIView+Boost.h"
#import "VendorDataLoader.h"

@interface CIOrdersTableViewController ()

@property PullToRefreshView *pull;
@property Order *currentOrder;
@property BOOL isLoadingOrders;

@end

@implementation CIOrdersTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.isLoadingOrders = NO;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.pull = [[PullToRefreshView alloc] initWithScrollView:self.tableView];
    [self.pull setDelegate:self];
    [self.tableView addSubview:self.pull];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ordersReloading:) name:OrderReloadStartedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ordersReloadComplete:) name:OrderReloadCompleteNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSessionDidChange:) name:SessionDidChangeNotification object:nil];

    // wait until the controller loads have completed for notification observation
    __weak CIOrdersTableViewController *weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf loadOrders:YES selectOrder:nil];
    });
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.view.hidden = NO;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.view.hidden = YES;
}

- (void)handleSessionDidChange:(NSNotification *)notification {
    //reload customers since the session change notification might have been discharged as a result of selecting a different show. This will require reloading customers, vendors, bulletins and products. todo sg vendors are no longer show specific, so we don't need to reload them.
    [VendorDataLoader load:@[@(VendorDataTypeCustomers), @(VendorDataTypeVendors), @(VendorDataTypeBulletins), @(VendorDataTypeProducts)] inView:self.view onComplete:^{
        [self loadOrders:YES selectOrder:nil];
    }];
}

- (void)ordersReloading:(NSNotification *)notification {
    [self selectOrder:nil];
    self.isLoadingOrders = YES;
    self.fetchRequest = nil;
}

- (void)ordersReloadComplete:(NSNotification *)notification {
    self.isLoadingOrders = NO;

    if (!self.fetchRequest) {
        self.fetchRequest = [OrderManager buildOrderFetch:nil inManagedObjectContext:self.managedObjectContext];
    } else {
        [self.tableView reloadData];
    }
}

- (NSFetchRequest *)initialFetchRequest {
    return nil; // we will wait until the partial load is complete from loadOrders
}

- (void)filterToQueryTerm:(NSString *)query {
    if (!self.isLoadingOrders) {
        self.fetchRequest = [OrderManager buildOrderFetch:query inManagedObjectContext:self.managedObjectContext];
    }
}

- (BOOL)hasOrders {
    return [self tableView:self.tableView numberOfRowsInSection:0] > 0;
}

- (void)selectOrder:(NSManagedObjectID *)orderObjectID {
    if ((orderObjectID && !self.currentOrder) || (!orderObjectID && self.currentOrder) || (orderObjectID && self.currentOrder && ![orderObjectID isEqual:self.currentOrder.objectID])) {

        Order *order = nil;
        if (orderObjectID) {
            order = (Order *) [[CurrentSession mainQueueContext] existingObjectWithID:orderObjectID error:nil];
        }

        //deselect current order
        if (self.currentOrder) {
            NSIndexPath *path = [self.fetchedResultsController indexPathForObject:self.currentOrder];
            if (path) {
                CIOrderCell *cell = (CIOrderCell *) [self.tableView cellForRowAtIndexPath:path];
                if (cell) {
                    [cell setActive:NO];
                }
            }
        }

        self.currentOrder = order;

        if (order && !self.isLoadingOrders) {
            NSIndexPath *path = nil;
            path = [self.fetchedResultsController indexPathForObject:order];
            
            if (path) {
                CIOrderCell *cell = (CIOrderCell *) [self.tableView cellForRowAtIndexPath:path];
                // select new order
                if (cell) {
                    [cell setActive:YES];
                }
                // scroll to new order
                if (!(cell && cell.visible)) {
                    [self.tableView scrollToRowAtIndexPath:path atScrollPosition:UITableViewScrollPositionTop animated:NO];
                }
            }
        } else {
//            [self.tableView scrollToNearestSelectedRowAtScrollPosition:UITableViewScrollPositionTop animated:NO];
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:OrderSelectionNotification object:order];
    } else if (self.currentOrder) {
        NSIndexPath *path = [self.fetchedResultsController indexPathForObject:self.currentOrder];
        // This branch is if they copy an order. Even though it was technically already selected, copied orders do not have an updatedAt
        // which is how the table is sorted. Thus, after they get synced with the server, their position in the table may have changed.
        if (path) [self.tableView scrollToRowAtIndexPath:path atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {

    Order *order = (Order *) anObject;

    switch(type)
    {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;

        case NSFetchedResultsChangeDelete:
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;

        case NSFetchedResultsChangeUpdate:
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            break;

        case NSFetchedResultsChangeMove:
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }

    if (0 == indexPath.section && self.currentOrder && [self.currentOrder.objectID isEqual:order.objectID]) {
        if (NSFetchedResultsChangeInsert == type) {
            // it's possible the order became the currentOrder before coredata was updated
            NSIndexPath *selectedPath = [self.tableView indexPathForSelectedRow];
            Order *selectedOrder = (Order *) [self.fetchedResultsController objectAtIndexPath:selectedPath];
            if (!selectedPath || ![self.currentOrder.objectID isEqual:selectedOrder.objectID]) {
                [self selectOrder:selectedOrder.objectID];
            }
        } else if (NSFetchedResultsChangeDelete == type) {
            [self selectOrder:nil];
        }
    }
}

#pragma mark - Private

- (void)loadOrders:(BOOL)showLoadingIndicator selectOrder:(NSManagedObjectID *)orderObjectID {
    if (!self.isLoadingOrders) {
        Order *order = nil;
        if (orderObjectID) order = (Order *) [[CurrentSession mainQueueContext] existingObjectWithID:orderObjectID error:nil];

        NSNumber *selectOrderId = order ? order.orderId : nil;
        [self selectOrder:nil];

        //if load orders is triggered because view is appearing, then the loading hud is shown. if it is triggered because of the pull action in orders list, there already will be a loading indicator so don't show the hud.
        MBProgressHUD *hud;
        if (showLoadingIndicator) {
            hud = [MBProgressHUD showHUDAddedTo:self.tableView animated:YES];
            hud.removeFromSuperViewOnHide = YES;
            hud.labelText = @"Getting orders";
            [hud show:NO];
        }

        __weak CIOrdersTableViewController *weakSelf = self;
        void (^cleanup)(void) = ^{
            if (![hud isHidden]) [hud hide:NO];
            [weakSelf.pull finishedLoading];
        };

        [OrderManager reloadOrdersOnSuccess:^{
            cleanup();
            dispatch_async(dispatch_get_main_queue(), ^{
                if (weakSelf && !weakSelf.fetchRequest) weakSelf.fetchRequest = [OrderManager buildOrderFetch:nil inManagedObjectContext:weakSelf.managedObjectContext];
            });
            [[CurrentSession privateQueueContext] performBlock:^{
                if (selectOrderId) {
                    Order *reloadedOrderWithId = (Order *) [[CoreDataUtil sharedManager] fetchObject:@"Order"
                                                                                           inContext:[CurrentSession privateQueueContext]
                                                                                       withPredicate:[NSPredicate predicateWithFormat:@"orderId == %@", selectOrderId]];
                    if (reloadedOrderWithId) [weakSelf selectOrder:reloadedOrderWithId.objectID];
                }
            }];
        }                         onFailure:^{
            cleanup();
        }];
    } else {
        [self.pull finishedLoading];
    }
}

#pragma mark - PullToRefreshViewDelegate

- (void)pullToRefreshViewShouldRefresh:(PullToRefreshView *)view; {
    __weak CIOrdersTableViewController *weakSelf = self;
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Reload Data"
                                                    message:@"Would you like to update your orders from the server?"
                                                   delegate:self
                                          cancelButtonTitle:@"No"
                                          otherButtonTitles:@"Yes", nil];
    [UIAlertViewDelegateWithBlock showAlertView:alert withCallBack:^(NSInteger buttonIndex) {
        NSString *action = [alert buttonTitleAtIndex:buttonIndex];
        if (weakSelf && [action isEqualToString:@"Yes"]) {
            [weakSelf loadOrders:NO selectOrder:nil];
        } else {
            [weakSelf.pull finishedLoading];
        }
    }];
}

#pragma mark - UITableViewDelegate

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([cell isKindOfClass:[CIOrderCell class]]) {
        [((CIOrderCell *)cell) updateRowHighlight:indexPath];
    }
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSIndexPath *indexPathToReturn = indexPath;
    if (self.currentOrder &&
            ![self.currentOrder.objectID isEqual:((Order *)[self.fetchedResultsController objectAtIndexPath:indexPath]).objectID] &&
            !self.currentOrder.inSync &&
            self.currentOrder.hasNontransientChanges) {

        indexPathToReturn = nil;

        __weak CIOrdersTableViewController *weakSelf = self;
        Order *currentOrder = self.currentOrder;
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Exit Without Saving?"
                                                            message:@"Do you want to exit without saving your changes?"
                                                           delegate:self
                                                  cancelButtonTitle:@"No"
                                                  otherButtonTitles:@"Yes", nil];
        [UIAlertViewDelegateWithBlock showAlertView:alertView withCallBack:^(NSInteger buttonIndex) {
            if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Yes"]) {
                [weakSelf.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionBottom];
            } else {
                [currentOrder.managedObjectContext refreshObject:currentOrder mergeChanges:NO];
            }
        }];
    }
    return indexPathToReturn;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Order *order = (Order *) [self.fetchedResultsController objectAtIndexPath:indexPath];
    if (order) [self selectOrder:order.objectID];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleNone;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 114;
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"CIOrderCell";
    CIOrderCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"CIOrderCell" owner:nil options:nil];
        cell = topLevelObjects[0];
    }

    Order *order = [self.fetchedResultsController objectAtIndexPath:indexPath];

    [cell prepareForDisplay:order setActive:self.currentOrder && [order.orderId isEqual:self.currentOrder.orderId]];

    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
//    if (editingStyle == UITableViewCellEditingStyleDelete) {
//        Order *order = [self.fetchedResultsController objectAtIndexPath:indexPath];
//        [[NSNotificationCenter defaultCenter] postNotificationName:OrderDeleteRequestedNotification object:order];
//    }
}


@end