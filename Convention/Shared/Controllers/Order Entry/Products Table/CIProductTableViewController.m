//
// Created by David Jafari on 12/20/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <MGSwipeTableCell/MGSwipeButton.h>
#import "CIProductTableViewController.h"
#import "CITableViewColumns.h"
#import "CITableViewCell.h"
#import "Configurations.h"
#import "CITableViewColumn.h"
#import "CIProductTableViewCell.h"
#import "CIQuantityColumnView.h"
#import "ProductCellDelegate.h"
#import "CurrentSession.h"
#import "CIShowPriceColumnView.h"
#import "CoreDataManager.h"
#import "ProductSearch.h"
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
#import "OrderManager.h"
#import "DateRange.h"

@interface CIProductTableViewController()

@property id<ProductCellDelegate> productCellDelegate;
@property PullToRefreshView *pull;
@property NSArray *lastFilterOperationSortDescriptors;

@end

static NSString *PRODUCT_VIEW_CELL_KEY = @"PRODUCT_VIEW_CELL_KEY";

@implementation CIProductTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [NSMutableArray array];
    self.lastFilterOperationSortDescriptors = @[ ];

    self.pull = [[PullToRefreshView alloc] initWithScrollView:self.tableView];
    [self.pull setDelegate:self];
    [self.tableView addSubview:self.pull];
    self.tableView.allowsSelection = YES;
    self.tableView.allowsSelectionDuringEditing = NO;
    [self.tableView registerClass:[CIProductTableViewCell class] forCellReuseIdentifier:PRODUCT_VIEW_CELL_KEY];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productsReloading:) name:ProductsLoadRequestedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productsReloadComplete:) name:ProductsLoadedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orderPriceTierChanged:) name:OrderPriceTierChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(linePriceChanged:) name:LinePriceChangedNotification object:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)productsReloading:(NSNotification *)notification {
    self.fetchRequest = nil;
}

- (void)productsReloadComplete:(NSNotification *)notification {
    [self.tableView reloadData];
}

- (void)orderPriceTierChanged:(NSNotification *)notification {
    [self.tableView reloadData];
}

- (void)linePriceChanged:(NSNotification *)notification {
    [self.tableView reloadData];
}

- (void)prepareForDisplay:(id<ProductCellDelegate>)delegate {
    self.productCellDelegate = delegate;
    [super prepareForDisplay];
}

- (void)filterToVendorId:(int)vendorId bulletinId:(int)bulletinId inCart:(BOOL)inCart queryTerm:(NSString *)query summarySearch:(BOOL)summarySearch {
    //resign quantity first responder here if we are using non-shipdate style; we don't want a lineitem saving while we are changing the fetchresults
    [self.tableView endEditing:YES];
    
    NSFetchRequest *request = [CoreDataManager buildProductFetch:[ProductSearch searchFor:query inBulletin:bulletinId forVendor:vendorId sortedBy:[self currentSortDescriptors] limitResultSize:0 usingContext:self.managedObjectContext]];
    if (inCart && self.productCellDelegate.currentOrderForCell) {
        NSPredicate *inCartPredicate = [NSPredicate predicateWithFormat:@"ANY lineItems.order == %@ AND ANY lineItems.quantity != nil", self.productCellDelegate.currentOrderForCell.objectID];
        request.predicate = request.predicate ? [NSCompoundPredicate andPredicateWithSubpredicates:@[request.predicate, inCartPredicate]] : inCartPredicate;
    }
    
    self.lastFilterOperationSortDescriptors = request.sortDescriptors;
    request.sortDescriptors = [self prependSectionSortDescriptor:request.sortDescriptors];
    request.includesPendingChanges = NO;
    request.includesSubentities = NO;

    if (summarySearch) {
        request.fetchBatchSize = 20;
        request.fetchLimit = 20;
    }

//    if (self.fetchRequest) {
//        self.fetchedResultsController.fetchRequest.fetchBatchSize = request.fetchBatchSize;
//        self.fetchedResultsController.fetchRequest.fetchLimit = request.fetchLimit;
//        self.fetchedResultsController.fetchRequest.predicate = request.predicate;
//        self.fetchedResultsController.fetchRequest.sortDescriptors = request.sortDescriptors;
//        [self.fetchedResultsController performFetch:nil];
//        [self.tableView reloadData];
//    } else {
        self.fetchRequest = request;
//    }
}

- (NSArray *)prependSectionSortDescriptor:(NSArray *)sortDescriptors {
    if (sortDescriptors.count == 0 || ![((NSSortDescriptor *) sortDescriptors.firstObject).key isEqualToString:@"section"]) {
        // add write-in sorting
        NSSortDescriptor *sectionSort = [NSSortDescriptor sortDescriptorWithKey:@"section" ascending:YES];
        return [@[sectionSort] arrayByAddingObjectsFromArray:sortDescriptors];
    } else {
        return sortDescriptors;
    }

}

- (NSFetchedResultsController *)initializeFetchedResultsController:(NSFetchRequest *)fetchRequest {
    id c = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                               managedObjectContext:self.managedObjectContext
                                                 sectionNameKeyPath:@"section"
                                                          cacheName:nil];
    
    return c;
}

- (NSFetchRequest *)initialFetchRequest {
    NSFetchRequest *request = [CoreDataManager buildProductFetch:[ProductSearch searchFor:@"" inBulletin:0 forVendor:0 sortedBy:nil limitResultSize:0 usingContext:self.managedObjectContext]];
    request.sortDescriptors = [self prependSectionSortDescriptor:request.sortDescriptors];
    return request;
}

- (CITableViewColumns *)createColumns {
    Configurations *config = [Configurations instance];
    CITableViewColumns *columns = [CITableViewColumns new];
    [columns add:ColumnTypeString titled:@"Item #" using:@{
            ColumnOptionContentKey: @"invtid",
            ColumnOptionDesiredWidth: config.discounts ? @100 : @150,
            ColumnOptionSortableKey: @YES
    }];
    if (config.productEnableManufacturerNo) {
        [columns add:ColumnTypeString titled:@"MFG #" using:@{
                ColumnOptionContentKey: @"partnbr",
                ColumnOptionDesiredWidth: @100,
                ColumnOptionSortableKey: @YES
        }];
    }
    [columns add:ColumnTypeCustom titled:@"Description" using:@{
            ColumnOptionContentKey: @"descr",
            ColumnOptionContentKey2: @"descr2",
            ColumnOptionCustomTypeClass: [CIProductDescriptionColumnView class],
            ColumnOptionSortableKey: @YES
    }];
    if (config.discounts) {
        [columns add:ColumnTypeCustom titled:@"Tags" using:@{
                ColumnOptionContentKey: @"tags",
                ColumnOptionDesiredWidth: @180,
                ColumnOptionCustomTypeClass: [CITagColumnView class]
        }];
    }
    [columns add:ColumnTypeCustom titled:@"Quantity" using:@{
            ColumnOptionDesiredWidth: @75,
            ColumnOptionTextAlignment: @(NSTextAlignmentRight),
            ColumnOptionCustomTypeClass: [CIQuantityColumnView class]
    }];
    [columns add:ColumnTypeCustom titled:config.price1Label using:@{
            ColumnOptionContentKey: @"showprc",
            ColumnOptionTextAlignment: @(NSTextAlignmentRight),
            ColumnOptionDesiredWidth: @90,
            ColumnOptionCustomTypeClass: [CIShowPriceColumnView class],
            ColumnOptionSortableKey: @YES
    }];
    [columns add:ColumnTypeCurrency titled:config.price2Label using:@{
            ColumnOptionContentKey: ([Configurations instance].isTieredPricing ? @"showprc" : @"regprc"),
            ColumnOptionTextAlignment: @(NSTextAlignmentRight),
            ColumnOptionDesiredWidth: @90,
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

    [CoreDataManager reloadProductsAsync:YES usingQueueContext:[CurrentSession privateQueueContext] onSuccess:successBlock onFailure:failureBlock];
}

#pragma UITableViewDelegate

#pragma UITableViewDataSource

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return nil; //no headers
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CIProductTableViewCell *cell = (CIProductTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:PRODUCT_VIEW_CELL_KEY forIndexPath:indexPath];
    cell.delegate = self;
    [cell prepareForDisplay:self.columns productCellDelegate:self.productCellDelegate];

    Product *product = [self objectAtIndexPath:indexPath];
    LineItem *line = [self.productCellDelegate.currentOrderForCell findLinesByProductId:product.productId].firstObject;
    [cell render:product lineItem:line];

    return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    CIProductTableViewCell *cell = (CIProductTableViewCell *) [self tableView:tableView cellForRowAtIndexPath:indexPath];
    if ([Configurations instance].shipDates) {
        [self.productCellDelegate toggleProductDetail:((Product *) cell.rowData).productId lineItem:cell.lineItem];
    }

    return nil;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
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
    //resign quantity first responder here if we are using non-shipdate style; we don't want a lineitem saving while we are changing the fetchresults
    [self.tableView endEditing:YES];

    NSFetchRequest *newFetchRequest = [self.fetchRequest copy];
    NSArray *sortSelectionOnExistingSort = [sortDescriptors arrayByAddingObjectsFromArray:self.lastFilterOperationSortDescriptors];
    newFetchRequest.sortDescriptors = [self prependSectionSortDescriptor:sortSelectionOnExistingSort];
    self.fetchRequest = newFetchRequest;
}

#pragma mark - MGSwipeTableCellDelegate

/**
* Delegate method to enable/disable swipe gestures
* @return YES if swipe is allowed
**/
-(BOOL) swipeTableCell:(MGSwipeTableCell*) cell canSwipe:(MGSwipeDirection) direction {
    return NO;
//    BOOL hasFixedShipDates = ([ShowConfigurations instance].shipDates && [ShowConfigurations instance].orderShipDates.fixedDates.count > 0);
//    return MGSwipeDirectionRightToLeft == direction || (![ShowConfigurations instance].shipDates || hasFixedShipDates);
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
-(BOOL) swipeTableCell:(MGSwipeTableCell*) cell tappedButtonAtIndex:(NSInteger)index direction:(MGSwipeDirection)direction fromExpansion:(BOOL) fromExpansion {
    CIProductTableViewCell *productCell = (CIProductTableViewCell *)cell;

    if (MGSwipeDirectionRightToLeft == direction) {
        if (0 == index) {
            if (productCell.lineItem) {
                if ([Configurations instance].shipDates && [Configurations instance].orderShipDates.fixedDates.count > 0) {
                    for (NSDate *shipDate in productCell.lineItem.shipDates) {
                        [productCell.lineItem setQuantity:0 forShipDate:shipDate];
                    }
                } else if (![Configurations instance].shipDates) {
                    [productCell.lineItem setQuantity:@"0"];
                }

                Order *order = [self.productCellDelegate currentOrderForCell];
                [OrderManager saveOrder:order inContext:[CurrentSession mainQueueContext]];

                [self.tableView reloadData];
            }
        }
    } else {
        LineItem *lineItem = productCell.lineItem;
        Order *order = [self.productCellDelegate currentOrderForCell];

        if (!lineItem) {
            lineItem = [order createLineForProductId:((Product *) productCell.rowData).productId context:[CurrentSession mainQueueContext]];
        }

        int quantityIncrement = 0;
        if (0 == index) {
            quantityIncrement = 1;
        } else if (1 == index) {
            quantityIncrement = 10;
        } else if (2 == index) {
            quantityIncrement = 100;
        }

        if ([Configurations instance].shipDates && [Configurations instance].orderShipDates.fixedDates.count > 0) {
            NSDate *shipDate = (NSDate *) [Configurations instance].orderShipDates.fixedDates.firstObject;
            [lineItem setQuantity:( [lineItem getQuantityForShipDate:shipDate] + quantityIncrement ) forShipDate:shipDate];
        } else if (![Configurations instance].shipDates) {
            [lineItem setQuantity:@( lineItem.totalQuantity + quantityIncrement ).stringValue];
        }

        [OrderManager saveOrder:order inContext:[CurrentSession mainQueueContext]];
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
    NSArray *buttons;
    
    if (MGSwipeDirectionRightToLeft == direction) {
        expansionSettings.buttonIndex = 0;
        expansionSettings.fillOnTrigger = YES;

        CIProductTableViewCell *productCell = (CIProductTableViewCell *)cell;
        if (productCell.lineItem) {
            buttons = @[ [MGSwipeButton buttonWithTitle:@"Remove" backgroundColor:[UIColor redColor]] ];
        } else {
            buttons = @[ ];
        }
    } else {
//        UIColor *baseColor = [ThemeUtil greenColor];
//        buttons = @[ [MGSwipeButton buttonWithTitle:@"+1" backgroundColor:[ThemeUtil lighten:baseColor by:0.76]],
//                [MGSwipeButton buttonWithTitle:@"+10" backgroundColor:[ThemeUtil lighten:baseColor by:0.82]],
//                [MGSwipeButton buttonWithTitle:@"+100" backgroundColor:[ThemeUtil lighten:baseColor by:0.9]] ];
        
//        UIColor *baseColor = [ThemeUtil greenColor];
        buttons = @[ [MGSwipeButton buttonWithTitle:@"+1" backgroundColor:[UIColor colorWithRed:0.153 green:0.682 blue:0.376 alpha:0.900]],
                     [MGSwipeButton buttonWithTitle:@"+10" backgroundColor:[UIColor colorWithRed:0.153 green:0.682 blue:0.376 alpha:0.800]],
                     [MGSwipeButton buttonWithTitle:@"+100" backgroundColor:[UIColor colorWithRed:0.153 green:0.682 blue:0.376 alpha:0.700]] ];

    }
    
    return buttons;
}


@end