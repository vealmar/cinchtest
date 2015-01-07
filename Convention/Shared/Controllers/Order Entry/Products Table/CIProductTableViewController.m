//
// Created by David Jafari on 12/20/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

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

@interface CIProductTableViewController()

@property id<ProductCellDelegate> delegate;
@property ProductSearchQueue *productSearchQueue;
@property PullToRefreshView *pull;
@property BOOL isLoadingProducts;

@end

static NSString *PRODUCT_VIEW_CELL_KEY = @"PRODUCT_VIEW_CELL_KEY";

@implementation CIProductTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

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
    // todo not sure if we need to use productsearchqueue anymore, it may have solved a performance problem that no longer exists
    //         [self.productSearchQueue search:productSearch];

    NSFetchRequest *request = [CoreDataManager buildProductFetch:[ProductSearch searchFor:query inBulletin:bulletinId forVendor:vendorId limitResultSize:0 usingContext:self.managedObjectContext]];
    if (inCart && self.delegate.currentOrderForCell) {
        NSPredicate *inCartPredicate = [NSPredicate predicateWithFormat:@"ANY lineItems.order == %@ AND ANY lineItems.quantity != nil", self.delegate.currentOrderForCell.objectID];
        request.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[request.predicate, inCartPredicate]];
    }
    request.includesPendingChanges = YES;
    request.includesSubentities = NO;
    self.fetchRequest = request;
}

- (NSFetchRequest *)initialFetchRequest {
    return [CoreDataManager buildProductFetch:[ProductSearch searchFor:@"" inBulletin:0 forVendor:0 limitResultSize:0 usingContext:self.managedObjectContext]];
}

- (CITableViewColumns *)createColumns {
    ShowConfigurations *config = [ShowConfigurations instance];
    CITableViewColumns *columns = [CITableViewColumns new];
    [columns add:ColumnTypeString titled:@"Item #" using:@{
            ColumnOptionContentKey: @"invtid",
            ColumnOptionDesiredWidth: [NSNumber numberWithInt:100]
    }];
    if (config.productEnableManufacturerNo) {
        [columns add:ColumnTypeString titled:@"MFG #" using:@{
                ColumnOptionContentKey: @"partnbr",
                ColumnOptionDesiredWidth: [NSNumber numberWithInt:100]
        }];
    }
    [columns add:ColumnTypeString titled:@"Description" using:@{
            ColumnOptionContentKey: @"descr",
            ColumnOptionContentKey2: @"descr2"
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
            ColumnOptionCustomTypeClass: [CIShowPriceColumnView class]
    }];
    [columns add:ColumnTypeCurrency titled:config.price2Label using:@{
            ColumnOptionContentKey: @"regprc",
            ColumnOptionTextAlignment: [NSNumber numberWithInt:NSTextAlignmentRight],
            ColumnOptionDesiredWidth: [NSNumber numberWithInt:90]
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
                      vendorGroupId:[NSNumber numberWithInt:[[CurrentSession instance].loggedInVendorGroupId intValue]]
                              async:YES
                  usingQueueContext:[CurrentSession privateQueueContext]
                          onSuccess:successBlock
                          onFailure:failureBlock];
}

#pragma UITableViewDelegate

#pragma UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CIProductTableViewCell *cell = (CIProductTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:PRODUCT_VIEW_CELL_KEY forIndexPath:indexPath];
    [cell prepareForDisplay:self.columns delegate:self.delegate];
    [cell render:[self.fetchedResultsController objectAtIndexPath:indexPath]];
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


@end