//
// Created by David Jafari on 12/24/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import "CIOrdersTableViewController.h"
#import "CurrentSession.h"
#import "CIOrderCell.h"
#import "ThemeUtil.h"
#import "MBProgressHUD.h"
#import "UIAlertViewDelegateWithBlock.h"
#import "Order.h"
#import "OrderCoreDataManager.h"
#import "ShowConfigurations.h"
#import "Order+Extensions.h"
#import "LineItem+Extensions.h"
#import "NotificationConstants.h"
#import "NumberUtil.h"
#import "OrderTotals.h"
#import "CoreDataUtil.h"
#import "UIView+Boost.h"

@interface CIOrdersTableViewController ()

@property PullToRefreshView *pull;
@property Order *currentOrder;
@property BOOL isLoadingOrders;

@end

@implementation CIOrdersTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.isLoadingOrders = NO;
    [self loadOrders:YES selectOrder:nil];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.pull = [[PullToRefreshView alloc] initWithScrollView:self.tableView];
    [self.pull setDelegate:self];
    [self.tableView addSubview:self.pull];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.view.hidden = NO;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.view.hidden = YES;
}

- (void)prepareForDisplay {
    [super prepareForDisplay:[CurrentSession instance].managedObjectContext];
}

- (NSFetchRequest *)initialFetchRequest {
    return [OrderCoreDataManager buildOrderFetch:nil inManagedObjectContext:self.managedObjectContext];
}

- (void)filterToQueryTerm:(NSString *)query {
    self.fetchRequest = [OrderCoreDataManager buildOrderFetch:query inManagedObjectContext:self.managedObjectContext];
}

- (BOOL)hasOrders {
    return [self tableView:self.tableView numberOfRowsInSection:0] > 0;
}

- (void)selectOrder:(Order *)order {
    if (order != self.currentOrder || (order && self.currentOrder && ![order.objectID isEqual:self.currentOrder.objectID])) {

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

        NSIndexPath *path = nil;
        if (order) {
            // if we dont have a path, it's possible that coredata hasn't saved it yet thus it's not in the table
            path = [self.fetchedResultsController indexPathForObject:order];
        }

        if (path) {
            CIOrderCell *cell = (CIOrderCell *) [self.tableView cellForRowAtIndexPath:path];
            // select new order
            if (cell) {
                [cell setActive:YES];
            }
            // scroll to new order
            if (!(cell && cell.visible)) {
                [self.tableView scrollToRowAtIndexPath:path atScrollPosition:UITableViewScrollPositionTop animated:YES];
            }
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:OrderSelectionNotification object:order];
    }
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject 
       atIndexPath:(NSIndexPath *)indexPath 
     forChangeType:(NSFetchedResultsChangeType)type 
      newIndexPath:(NSIndexPath *)newIndexPath {

    Order *order = (Order *) anObject;

//    if (NSFetchedResultsChangeUpdate == type) {
//        __weak CIOrdersTableViewController *weakSelf = self;
//
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            if (order.hasChanges) {
//                [order.managedObjectContext refreshObject:order mergeChanges:YES];
//            }
//            [weakSelf.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
//        });
//    }

    switch(type)
    {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;

        case NSFetchedResultsChangeDelete:
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;

        case NSFetchedResultsChangeUpdate:
            // we will manually handle this case because of the way we do asynchronous saves during calculateTotals
            break;

        case NSFetchedResultsChangeMove:
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
        
    if (0 == indexPath.section && self.currentOrder && [self.currentOrder.objectID isEqual:order.objectID]) {
        if (NSFetchedResultsChangeInsert == type) {
            // it's possible the order became the currentOrder before coredata was updated
            NSIndexPath *selectedPath = [self.tableView indexPathForSelectedRow];
            Order *selectedOrder = (Order *) [self.fetchedResultsController objectAtIndexPath:selectedPath];
            if (!selectedPath || ![self.currentOrder.objectID isEqual:selectedOrder.objectID]) {
                [self selectOrder:selectedOrder];
            }
        } else if (NSFetchedResultsChangeDelete == type) {
            [self selectOrder:nil];
        }
    }
}

#pragma mark - Private

- (void)loadOrders:(BOOL)showLoadingIndicator selectOrder:(Order *)order {
    if (!self.isLoadingOrders) {
        NSNumber *selectOrderId = order.orderId;
        [self selectOrder:nil];
        self.isLoadingOrders = YES;

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
            weakSelf.isLoadingOrders = NO;
        };

        [OrderCoreDataManager reloadOrders:NO onSuccess:^{
            cleanup();
            dispatch_async(dispatch_get_main_queue(), ^{
                Order *reloadedOrderWithId = (Order *) [[CoreDataUtil sharedManager] fetchObject:@"Order"
                                                                                       inContext:[CurrentSession instance].managedObjectContext
                                                                                   withPredicate:[NSPredicate predicateWithFormat:@"orderId == %@", selectOrderId]];
                [weakSelf selectOrder:reloadedOrderWithId];
            });
        } onFailure:^{
            cleanup();
        }];
    }
}

#pragma mark - PullToRefreshViewDelegate

- (void)pullToRefreshViewShouldRefresh:(PullToRefreshView *)view; {
    [self loadOrders:NO selectOrder:self.currentOrder];
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
    [self selectOrder:order];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
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
        cell = [topLevelObjects objectAtIndex:0];
    }

    Order *order = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    [cell prepareForDisplay:order setActive:self.currentOrder && [order.orderId isEqual:self.currentOrder.orderId]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Order *order = [self.fetchedResultsController objectAtIndexPath:indexPath];
        [[NSNotificationCenter defaultCenter] postNotificationName:OrderDeleteRequestedNotification object:order];
    }
}


@end