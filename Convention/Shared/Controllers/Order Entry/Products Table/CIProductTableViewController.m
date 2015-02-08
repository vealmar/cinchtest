//
// Created by David Jafari on 12/20/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <MGSwipeTableCell/MGSwipeButton.h>
#import "CIProductTableViewController.h"
#import "CITableViewColumns.h"
#import "CITableViewCell.h"
#import "ShowConfigurations.h"
#import "CITableViewColumn.h"
#import "CIProductTableViewCell.h"
#import "CIQuantityColumnView.h"
#import "ProductCellDelegate.h"
#import "CurrentSession.h"
#import "CIShowPriceColumnView.h"
#import "CoreDataManager.h"
#import "ProductSearch.h"
#import "ProductSearchQueue.h"
#import "MBProgressHUD.h"
#import "Order.h"
#import "CITagColumnView.h"
#import "NotificationConstants.h"
#import "UIAlertViewDelegateWithBlock.h"
#import "Product.h"
#import "Order+Extensions.h"
#import "LineItem.h"
#import "LineItem+Extensions.h"
#import "CIProductDescriptionColumnView.h"
#import "ThemeUtil.h"

@interface CIProductTableViewController()

@property id<ProductCellDelegate> delegate;
@property ProductSearchQueue *productSearchQueue;
@property PullToRefreshView *pull;
@property BOOL isLoadingProducts;

// contains a collection of lineitems/products in the form:
//   lineitem - line written for product
//   lineitem - keep adding new lines when they write
//   product - lastly show a blank line
@property NSMutableArray *writeInLines;

@end

static NSString *PRODUCT_VIEW_CELL_KEY = @"PRODUCT_VIEW_CELL_KEY";

@implementation CIProductTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.writeInLines = [NSMutableArray array];

    self.isLoadingProducts = NO;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productsReloading:) name:ProductsLoadRequestedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productsReloadComplete:) name:ProductsLoadedNotification object:nil];

    self.pull = [[PullToRefreshView alloc] initWithScrollView:self.tableView];
    [self.pull setDelegate:self];
    [self.tableView addSubview:self.pull];

    [self.tableView registerClass:[CIProductTableViewCell class] forCellReuseIdentifier:PRODUCT_VIEW_CELL_KEY];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
//    self.productSearchQueue = [[ProductSearchQueue alloc] initWithProductController:self];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
//    self.productSearchQueue = nil;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ProductsLoadRequestedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ProductsLoadedNotification object:nil];
}

- (void)productsReloading:(NSNotification *)notification {
    self.isLoadingProducts = YES;
    self.fetchRequest = nil;
}

- (void)productsReloadComplete:(NSNotification *)notification {
    self.isLoadingProducts = NO;
    [self.tableView reloadData];
}

- (void)prepareForDisplay:(id<ProductCellDelegate>)delegate {
    self.delegate = delegate;
    [super prepareForDisplay];
}

- (void)filterToVendorId:(int)vendorId bulletinId:(int)bulletinId inCart:(BOOL)inCart queryTerm:(NSString *)query {
    //resign quantity first responder here if we are using non-shipdate style; we don't want a lineitem saving while we are changing the fetchresults
    [self.tableView endEditing:YES];
    
    NSFetchRequest *request = [CoreDataManager buildProductFetch:[ProductSearch searchFor:query inBulletin:bulletinId forVendor:vendorId sortedBy:[self currentSortDescriptors] limitResultSize:0 usingContext:self.managedObjectContext]];
    if (inCart && self.delegate.currentOrderForCell) {
        NSPredicate *inCartPredicate = [NSPredicate predicateWithFormat:@"ANY lineItems.order == %@ AND ANY lineItems.quantity != nil", self.delegate.currentOrderForCell.objectID];
        request.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[request.predicate, inCartPredicate]];
    }
    
    // add write-in sorting
    NSSortDescriptor *sectionSort = [NSSortDescriptor sortDescriptorWithKey:@"section" ascending:YES];
    request.sortDescriptors = [@[sectionSort] arrayByAddingObjectsFromArray:request.sortDescriptors];
    
    request.includesPendingChanges = YES;
    request.includesSubentities = NO;

    self.fetchRequest = request;
}

- (NSFetchedResultsController *)initializeFetchedResultsController:(NSFetchRequest *)fetchRequest {
    return [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                               managedObjectContext:self.managedObjectContext
                                                 sectionNameKeyPath:@"section"
                                                          cacheName:nil];
}

- (NSFetchRequest *)initialFetchRequest {
    return [CoreDataManager buildProductFetch:[ProductSearch searchFor:@"" inBulletin:0 forVendor:0 sortedBy:nil limitResultSize:0 usingContext:self.managedObjectContext]];
}

- (CITableViewColumns *)createColumns {
    ShowConfigurations *config = [ShowConfigurations instance];
    CITableViewColumns *columns = [CITableViewColumns new];
    [columns add:ColumnTypeString titled:@"Item #" using:@{
            ColumnOptionContentKey: @"invtid",
            ColumnOptionDesiredWidth: @100,
            ColumnOptionSortableKey: @YES
    }];
    if (config.productEnableManufacturerNo) {
        [columns add:ColumnTypeString titled:@"MFG #" using:@{
                ColumnOptionContentKey: @"partnbr",
                ColumnOptionDesiredWidth: @100,
                ColumnOptionSortableKey: @YES
        }];
    }
    [columns add:ColumnTypeString titled:@"Description" using:@{
            ColumnOptionContentKey: @"descr",
            ColumnOptionContentKey2: @"descr2",
            ColumnOptionCustomTypeClass: [CIProductDescriptionColumnView class],
            ColumnOptionSortableKey: @YES
    }];
    if (config.discounts) {
        [columns add:ColumnTypeCustom titled:@"Tags" using:@{
                ColumnOptionContentKey: @"tags",
                ColumnOptionDesiredWidth: [NSNumber numberWithInt:180],
                ColumnOptionCustomTypeClass: [CITagColumnView class]
        }];
    }
    [columns add:ColumnTypeCustom titled:@"Quantity" using:@{
            ColumnOptionDesiredWidth: [NSNumber numberWithInt:75],
            ColumnOptionTextAlignment: [NSNumber numberWithInt:NSTextAlignmentRight],
            ColumnOptionCustomTypeClass: [CIQuantityColumnView class]
    }];
    [columns add:ColumnTypeCustom titled:config.price1Label using:@{
            ColumnOptionContentKey: @"showprc",
            ColumnOptionTextAlignment: [NSNumber numberWithInt:NSTextAlignmentRight],
            ColumnOptionDesiredWidth: [NSNumber numberWithInt:90],
            ColumnOptionCustomTypeClass: [CIShowPriceColumnView class],
            ColumnOptionSortableKey: @YES
    }];
    [columns add:ColumnTypeCurrency titled:config.price2Label using:@{
            ColumnOptionContentKey: @"regprc",
            ColumnOptionTextAlignment: [NSNumber numberWithInt:NSTextAlignmentRight],
            ColumnOptionDesiredWidth: [NSNumber numberWithInt:90],
            ColumnOptionSortableKey: @YES
    }];
    return columns;
}

- (void)reloadProducts {
    MBProgressHUD *submit = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    submit.removeFromSuperViewOnHide = YES;
    submit.labelText = @"Loading Products";
    [submit show:YES];

    __weak CIProductTableViewController *weakSelf = self;
    void (^successBlock)() = ^() {
        [weakSelf.pull finishedLoading];
        [submit hide:NO];
    };
    void (^failureBlock)() = ^() {
        [weakSelf.pull finishedLoading];
        [submit hide:NO];
    };

    [CoreDataManager reloadProducts:[CurrentSession instance].authToken
                      vendorGroupId:[NSNumber numberWithInt:[[CurrentSession instance].vendorGroupId intValue]]
                              async:YES
                  usingQueueContext:[CurrentSession privateQueueContext]
                          onSuccess:successBlock
                          onFailure:failureBlock];
}

- (NSArray *)mapIndexPathsFromFetchResultsController:(NSIndexPath *)indexPath {
    NSMutableArray *indexPaths = [NSMutableArray array];
    
    if (indexPath.section == 1) {
        Product *product = [self.fetchedResultsController objectAtIndexPath:indexPath];

        [self.writeInLines enumerateObjectsUsingBlock:^(id line, NSUInteger idx, BOOL *stop) {
            if (([line isKindOfClass:[Product class]] && [product.productId isEqualToNumber:((Product *)line).productId]) ||
                    ([line isKindOfClass:[LineItem class]] && [product.productId isEqualToNumber:((LineItem *)line).productId]))
            [indexPaths addObject:[NSIndexPath indexPathForRow:idx inSection:1]];
        }];
    } else {
        [indexPaths addObject:indexPath];
    }

    return [NSArray arrayWithArray:indexPaths];
}

- (NSIndexPath *)mapIndexPathToFetchResultsController:(NSIndexPath *)indexPath {
    if (indexPath.section == 1) {
        id line = self.writeInLines[indexPath.row];
        if ([line isKindOfClass:[Product class]]) {
            return [self.fetchedResultsController indexPathForObject:line];
        } else {
            return [self.fetchedResultsController indexPathForObject:((LineItem *)line).product];
        }
    } else {
        return indexPath;
    }
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {

    NSArray *indexPaths = [self mapIndexPathsFromFetchResultsController:indexPath];
    NSArray *newIndexPaths = [self mapIndexPathsFromFetchResultsController:newIndexPath];
    [indexPaths enumerateObjectsUsingBlock:^(NSIndexPath *indexPath, NSUInteger idx, BOOL *stop) {
        [super controller:controller
          didChangeObject:anObject 
              atIndexPath:indexPath 
            forChangeType:type 
             newIndexPath:newIndexPaths[idx]];
    }];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [super controllerDidChangeContent:controller];

    [self.writeInLines removeAllObjects];

    id<NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController.sections objectAtIndex:1];
    for (Product *product in sectionInfo.objects) {
        NSArray *lines = [self.delegate.currentOrderForCell findLinesByProductId:product.productId];
        [self.writeInLines addObjectsFromArray:lines];
        [self.writeInLines addObject:product];
    }
}

#pragma UITableViewDelegate

#pragma UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 1) {
        return [self.writeInLines count];
    } else {
        return [super tableView:tableView numberOfRowsInSection:section];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return nil; //no headers
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CIProductTableViewCell *cell = (CIProductTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:PRODUCT_VIEW_CELL_KEY forIndexPath:indexPath];
    cell.delegate = self;
    [cell prepareForDisplay:self.columns delegate:self.delegate];

    Product *product = [self objectAtIndexPath:[self mapIndexPathToFetchResultsController:indexPath]];

    if (indexPath.section == 1) {
        id line = self.writeInLines[indexPath.row];
        if (![line isKindOfClass:[LineItem class]]) line = nil;
        [cell render:product lineItem:line];
    } else {
        LineItem *line = [self.delegate.currentOrderForCell findLinesByProductId:product.productId].firstObject;
        [cell render:product lineItem:line];
    }

    return cell;
}

#pragma mark - PullToRefreshViewDelegate

- (void)pullToRefreshViewShouldRefresh:(PullToRefreshView *)view; {
    __weak CIProductTableViewController *weakSelf = self;
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Reload Data"
                                                    message:@"Would you like to update your product catalog from the server?"
                                                   delegate:self
                                          cancelButtonTitle:@"No"
                                          otherButtonTitles:@"Yes", nil];
    [UIAlertViewDelegateWithBlock showAlertView:alert withCallBack:^(NSInteger buttonIndex) {
        NSString *action = [alert buttonTitleAtIndex:buttonIndex];
        if (weakSelf && [action isEqualToString:@"Yes"]) {
            [weakSelf reloadProducts];
        } else {
            [weakSelf.pull finishedLoading];
        }
    }];
}

#pragma mark - CITableSortDelegate

- (void)sortSelected:(NSArray *)sortDescriptors {
    NSFetchRequest *newFetchRequest = [self.fetchRequest copy];
    newFetchRequest.sortDescriptors = sortDescriptors;
    self.fetchRequest = newFetchRequest;
}



#pragma mark - MGSwipeTableCellDelegate

/**
* Delegate method to enable/disable swipe gestures
* @return YES if swipe is allowed
**/
-(BOOL) swipeTableCell:(MGSwipeTableCell*) cell canSwipe:(MGSwipeDirection) direction {
    return YES;
}

/**
* Delegate method invoked when the current swipe state changes
@param state the current Swipe State
@param gestureIsActive YES if the user swipe gesture is active. No if the uses has already ended the gesture
**/
-(void) swipeTableCell:(MGSwipeTableCell*) cell didChangeSwipeState:(MGSwipeState) state gestureIsActive:(BOOL) gestureIsActive {

}

/**
* Called when the user clicks a swipe button or when a expandable button is automatically triggered
* @return YES to autohide the current swipe buttons
**/
-(BOOL) swipeTableCell:(MGSwipeTableCell*) cell tappedButtonAtIndex:(NSInteger) index direction:(MGSwipeDirection)direction fromExpansion:(BOOL) fromExpansion {
    CIProductTableViewCell *producCell = (CIProductTableViewCell *)cell;

    if (producCell.lineItem) {
        Order *order = [self.delegate currentOrderForCell];
        [order removeLineItems:[NSSet setWithObject:producCell.lineItem]];
    }

    return YES;
}

/**
* Delegate method to setup the swipe buttons and swipe/expansion settings
* Buttons can be any kind of UIView but it's recommended to use the convenience MGSwipeButton class
* Setting up buttons with this delegate instead of using cell properties improves memory usage because buttons are only created in demand
* @param swipeTableCell the UITableVieCel to configure. You can get the indexPath using [tableView indexPathForCell:cell]
* @param direction The swipe direction (left to right or right to left)
* @param swipeSettings instance to configure the swipe transition and setting (optional)
* @param expansionSettings instance to configure button expansions (optional)
* @return Buttons array
**/
-(NSArray*) swipeTableCell:(MGSwipeTableCell*) cell swipeButtonsForDirection:(MGSwipeDirection)direction
             swipeSettings:(MGSwipeSettings*) swipeSettings expansionSettings:(MGSwipeExpansionSettings*) expansionSettings {
    if (MGSwipeDirectionRightToLeft == direction) {
        expansionSettings.buttonIndex = 0;
        expansionSettings.fillOnTrigger = YES;

        CIProductTableViewCell *producCell = (CIProductTableViewCell *)cell;
        if (producCell.lineItem) {
            return @[[MGSwipeButton buttonWithTitle:@"Remove from Order" backgroundColor:[ThemeUtil orangeColor]];
        } else {
            return @[ ];
        }
    } else {
        return @[ ];
    }
}


@end