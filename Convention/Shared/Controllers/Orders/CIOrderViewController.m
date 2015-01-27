//
//  CIOrderViewController.m
//  Convention
//
//  Created by Matthew Clark on 12/8/11.
//  Copyright (c) 2011 MotionMobs. All rights reserved.
//

#import "CIOrderViewController.h"
#import "config.h"
#import "SettingsManager.h"
#import "ShowConfigurations.h"
#import "CoreDataManager.h"
#import "UIAlertViewDelegateWithBlock.h"
#import "Customer.h"
#import "NotificationConstants.h"
#import "CinchJSONAPIClient.h"
#import "VALabel.h"
#import "ThemeUtil.h"
#import "CIBarButton.h"
#import "CIOrdersTableViewController.h"
#import "OrderManager.h"
#import "Order+Extensions.h"
#import "LineItem+Extensions.h"
#import "NumberUtil.h"
#import "OrderTotals.h"
#import "OrderSubtotalsByDate.h"
#import "MBProgressHUD.h"
#import "CoreDataUtil.h"
#import "CurrentSession.h"
#import "KeyCommander.h"
#import "Product.h"
#import "CIOrderDetailTableViewController.h"
#import "CITableViewHeader.h"

@interface CIOrderViewController () {
    ShowConfigurations *showConfig;
}

@property Order *currentOrder;
@property (weak, nonatomic) CIOrdersTableViewController *ordersTableViewController;
@property CINavViewManager *navViewManager;
@property BOOL isLoadingOrders;

@property (weak, nonatomic) IBOutlet UIView *orderDetailView;
@property (weak, nonatomic) IBOutlet UILabel *orderDetailOrderNumberLabel;
@property (weak, nonatomic) IBOutlet UIView *orderDetailCustomerView;
@property (weak, nonatomic) IBOutlet UILabel *orderDetailCustomerLabel;
@property (weak, nonatomic) IBOutlet UIView *orderDetailAuthorizedView;
@property (weak, nonatomic) IBOutlet UILabel *orderDetailAuthorizedLabel;
@property (weak, nonatomic) IBOutlet UIView *orderDetailNotesView;
@property (weak, nonatomic) IBOutlet VALabel *orderDetailNotesLabel;


@property (weak, nonatomic) IBOutlet UIButton *orderDetailSaveButton;
@property (weak, nonatomic) IBOutlet UIButton *orderDetailEditButton;
@property (weak, nonatomic) IBOutlet UIButton *orderDetailDeleteButton;

@property CIOrderDetailTableViewController *orderDetailTableViewController;
@property (weak, nonatomic) IBOutlet UIView *orderDetailTableParentView;
@property (weak, nonatomic) IBOutlet CITableViewHeader *orderDetailHeaderView;
@property (weak, nonatomic) IBOutlet UITableView *orderDetailTableView;

@end

@implementation CIOrderViewController

@synthesize currentOrder = _currentOrder;

- (void)persistentOrderUpdated:(Order *)updatedOrder {
    self.NoOrdersLabel.hidden = self.ordersTableViewController.hasOrders;

    self.currentOrder = updatedOrder;
    [self.ordersTableViewController selectOrder:updatedOrder.objectID];
    [self displayOrderDetail:self.currentOrder];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.currentOrder = nil;

    self.NoOrdersLabel.font = [UIFont fontWithName:kFontName size:25.f];
    self.customer.font = [UIFont fontWithName:kFontName size:14.f];

    showConfig = [ShowConfigurations instance];
    self.orderDetailView.hidden = YES;
    self.orderDetailNotesLabel.verticalAlignment = VerticalAlignmentMiddle;

    self.orderDetailEditButton.layer.borderWidth = 1.0f;
    self.orderDetailEditButton.layer.cornerRadius = 3.0f;
    self.orderDetailSaveButton.layer.borderWidth = 1.0f;
    self.orderDetailSaveButton.layer.cornerRadius = 3.0f;
    self.orderDetailDeleteButton.layer.cornerRadius = 3.0f;
    self.orderDetailDeleteButton.layer.borderWidth = 1.0f;
    self.orderDetailDeleteButton.layer.borderColor = [UIColor colorWithRed:0.906 green:0.298 blue:0.235 alpha:1.000].CGColor;
    self.orderDetailDeleteButton.backgroundColor = [UIColor colorWithRed:0.937 green:0.541 blue:0.502 alpha:1.000];

    [self.ordersTableViewController prepareForDisplay];

    self.navViewManager = [[CINavViewManager alloc] init:YES];
    self.navViewManager.delegate = self;
    self.navViewManager.title = [ThemeUtil titleTextWithFontSize:18 format:@"%s", @"Orders", nil];
    [self.navViewManager setupNavBar];

    self.orderDetailTableViewController = [[CIOrderDetailTableViewController alloc] initWithStyle:UITableViewStylePlain];
    self.orderDetailTableViewController.header = self.orderDetailHeaderView;
    self.orderDetailTableViewController.tableView = self.orderDetailTableView;
    self.orderDetailTableView.dataSource = self.orderDetailTableViewController;
    self.orderDetailTableView.delegate = self.orderDetailTableViewController;
    [self.orderDetailTableViewController prepareForDisplay];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ordersReloading:) name:OrderReloadStartedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ordersReloadComplete:) name:OrderReloadCompleteNotification object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:OrderReloadStartedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:OrderReloadCompleteNotification object:nil];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orderSelected:) name:OrderSelectionNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orderDeleted:) name:OrderDeleteRequestedNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:OrderSelectionNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:OrderDeleteRequestedNotification object:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return UIInterfaceOrientationIsLandscape(interfaceOrientation); //we only support landscape orientation.
}

#pragma mark - Order detail display

- (IBAction)orderDetailSaveButtonTapped:(id)sender {
    [self saveOrder];
}

- (IBAction)orderDetailEditButtonTapped:(id)sender {
    [self openOrder:self.currentOrder];
}

- (IBAction)orderDetailDeleteButtonTapped:(id)sender {
    [self requestDelete:self.currentOrder];
}

- (void)ordersReloading:(NSNotification *)notification {
    [self.navViewManager clearSearch];
    self.isLoadingOrders = YES;
}

- (void)ordersReloadComplete:(NSNotification *)notification {
    self.isLoadingOrders = NO;
}

- (void)orderSelected:(NSNotification *)notification {
    self.currentOrder = (Order *) [[CurrentSession mainQueueContext] objectRegisteredForID:((Order *) notification.object).objectID];
    [self displayOrderDetail:self.currentOrder];
}

- (void)orderDeleted:(NSNotification *)notification {
    [self requestDelete:(Order *)notification.object];
}

- (void)displayOrderDetail:(Order *)order {
    self.orderDetailTableViewController.currentOrder = order;
    if (order) {
        self.orderDetailView.hidden = NO;
        
        ShowConfigurations *config = [ShowConfigurations instance];
        
        self.orderDetailOrderNumberLabel.text = [NSString stringWithFormat:@"Order #%@", order.orderId];
        self.orderDetailCustomerLabel.text = order.customerName;
        
        if (order.authorizedBy && order.authorizedBy.length) {
            self.orderDetailAuthorizedView.hidden = NO;
            self.orderDetailAuthorizedLabel.text = order.authorizedBy;
            self.orderDetailCustomerView.frame = CGRectMake(0, 44, 331, 96);
        } else {
            self.orderDetailAuthorizedView.hidden = YES;
            self.orderDetailCustomerView.frame = CGRectMake(0, 44, 670, 96);
        }
        
        float orderDetailTableOriginY = self.orderDetailCustomerView.frame.origin.y + self.orderDetailCustomerView.frame.size.height + 8;
        if (config.enableOrderNotes && order.notes && order.notes.length > 0) {
            self.orderDetailNotesLabel.text = [order.notes stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            self.orderDetailNotesView.hidden = NO;
            orderDetailTableOriginY += self.orderDetailNotesView.frame.size.height + 8;
        } else {
            self.orderDetailNotesView.hidden = YES;
        }
        self.orderDetailTableParentView.frame = CGRectMake(0, orderDetailTableOriginY, self.orderDetailTableParentView.frame.size.width, 630 - orderDetailTableOriginY);

        self.customer.text = [self.currentOrder getCustomerDisplayName];
        self.authorizer.text = order.authorizedBy != nil? order.authorizedBy : @"";
        
        if (order && ![order.notes isKindOfClass:[NSNull class]]) {
            self.notes.text = [order.notes stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        } else {
            self.notes.text = @"";
        }
        
        [self updateOrderActions];
    } else {
        self.orderDetailView.hidden = YES;
    }
}

- (void)updateOrderActions {
    BOOL orderAccessible = NO;
    if (self.currentOrder) {
        NSString *orderStatus = [self.currentOrder.status lowercaseString];
        if (![orderStatus rangeOfString:@"submit"].length > 0) {
            orderAccessible = YES;
        }
    }

    if (orderAccessible) {
        self.orderDetailEditButton.userInteractionEnabled = YES;
        self.orderDetailEditButton.layer.borderColor = [UIColor colorWithRed:0.902 green:0.494 blue:0.129 alpha:1.000].CGColor;
        self.orderDetailEditButton.backgroundColor = [UIColor colorWithRed:0.922 green:0.647 blue:0.416 alpha:1.000];
    } else {
        self.orderDetailEditButton.userInteractionEnabled = NO;
        self.orderDetailEditButton.layer.borderColor = [UIColor colorWithRed:0.922 green:0.800 blue:0.682 alpha:1.000].CGColor;
        self.orderDetailEditButton.backgroundColor = [UIColor colorWithRed:0.922 green:0.800 blue:0.682 alpha:1.000];
    }

    if (orderAccessible && self.currentOrder && self.currentOrder.hasNontransientChanges) {
        self.orderDetailSaveButton.userInteractionEnabled = YES;
        self.orderDetailSaveButton.layer.borderColor = [UIColor colorWithRed:0.902 green:0.494 blue:0.129 alpha:1.000].CGColor;
        self.orderDetailSaveButton.backgroundColor = [UIColor colorWithRed:0.922 green:0.647 blue:0.416 alpha:1.000];
    } else {
        self.orderDetailSaveButton.userInteractionEnabled = NO;
        self.orderDetailSaveButton.layer.borderColor = [UIColor colorWithRed:0.922 green:0.800 blue:0.682 alpha:1.000].CGColor;
        self.orderDetailSaveButton.backgroundColor = [UIColor colorWithRed:0.922 green:0.800 blue:0.682 alpha:1.000];
    }
}

#pragma mark - CIProductViewDelegate

- (void)returnOrder:(NSManagedObjectID *)orderObjectID updateStatus:(OrderUpdateStatus)updateStatus {
    [self.ordersTableViewController.tableView reloadData];
    if (updateStatus != NewOrderCancelled && orderObjectID) { //new order created
        NSManagedObjectContext *context = self.ordersTableViewController.managedObjectContext;
        __weak CIOrderViewController *weakSelf = self;
        [context performBlockAndWait:^{
            Order *contextReadyOrder = (Order *) [context existingObjectWithID:orderObjectID error:nil];
            [weakSelf persistentOrderUpdated:contextReadyOrder];
        }];
    }
}

#pragma mark - Events

- (void)addNewOrder {
    [self.navViewManager clearSearch]; // our search uses a contains query, this cannot be used in conjunction with NSFetchResultsController when doing inserts/deletes
    CICustomerInfoViewController *ci = [[CICustomerInfoViewController alloc] initWithNibName:@"CICustomerInfoViewController" bundle:nil];
    ci.modalPresentationStyle = UIModalPresentationFormSheet;
    ci.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    ci.delegate = self;
    [self presentViewController:ci animated:YES completion:nil];
}

- (void)customerSelected:(NSDictionary *)info {
    [self startNewOrderForCustomer:info];
}

- (void)saveOrder {
    if (nil == self.currentOrder) {
        return;
    }
    __weak CIOrderViewController *weakSelf = self;
    [OrderManager syncOrder:self.currentOrder attachHudTo:self.view onSuccess:^{
        [weakSelf persistentOrderUpdated:weakSelf.currentOrder];
    }             onFailure:nil];
}

- (void)requestDelete:(Order *)order {
    if (order) {
        NSString *alertMessage = [NSString stringWithFormat:@"Are you sure you want to delete %@ order?",
                        order.customerName ? [NSString stringWithFormat:@"%@'s", order.customerName] : @"this", nil];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"DELETE"
                                                        message:alertMessage
                                                       delegate:self 
                                              cancelButtonTitle:@"Cancel" 
                                              otherButtonTitles:@"Delete", nil];
        [UIAlertViewDelegateWithBlock showAlertView:alert withCallBack:^(NSInteger buttonIndex) {
            if (buttonIndex == 1) {
                [self deleteOrder:order];
            }
        }];
    }
}

#pragma mark - ReachabilityDelegate

- (void)networkLost {
}

- (void)networkRestored {
}

- (void)deleteOrder:(Order *)order {
    MBProgressHUD *deleteHUD = [MBProgressHUD showHUDAddedTo:self.view animated:NO];
    deleteHUD.removeFromSuperViewOnHide = YES;
    deleteHUD.labelText = @"Deleting order";
    [deleteHUD show:NO];

    BOOL isSelectedOrder = self.currentOrder && [order.objectID isEqual:self.currentOrder.objectID];
    __weak CIOrderViewController *weakSelf = self;
    [OrderManager deleteOrder:order onSuccess:^{
        if (isSelectedOrder) {
            weakSelf.orderDetailView.hidden = YES;
            weakSelf.currentOrder = nil;
        }
        [deleteHUD hide:NO];
    }               onFailure:^{
        [deleteHUD hide:NO];
    }];
}

# pragma mark - Storyboard

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"orderTableViewControllerEmbed"]) {
        self.ordersTableViewController = segue.destinationViewController;
    }
}

#pragma mark - Load Product View Controller

- (void)startNewOrderForCustomer:(NSDictionary *)customer {
    __weak CIOrderViewController *weakSelf = self;
    [[CurrentSession mainQueueContext] performBlock:^{
        NSArray *existingOrders = [[CoreDataUtil sharedManager] fetchArray:@"Order" 
                                                             withPredicate:[NSPredicate predicateWithFormat:@"customerId == %@ and vendorId == %@", customer[kID], [CurrentSession instance].vendorId] 
                                                               withContext:[CurrentSession mainQueueContext]];
        if (existingOrders && existingOrders.count > 0 && weakSelf) {
            Order *existingOrder = (Order *) existingOrders[0];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Order Exists"
                                                            message:@"You already have an active order for this customer, would you like to open it instead?"
                                                           delegate:weakSelf
                                                  cancelButtonTitle:@"No, Create New Order"
                                                  otherButtonTitles:@"Yes, Use Existing Order", nil];
            [UIAlertViewDelegateWithBlock showAlertView:alert withCallBack:^(NSInteger buttonIndex) {
                if (weakSelf) {
                    if (buttonIndex == 1) {
                        [weakSelf launchCIProductViewController:NO order:existingOrder.objectID customer:customer];
                    } else {
                        [weakSelf launchCIProductViewController:YES order:nil customer:customer];
                    }
                }
            }];
        } else {
            if (weakSelf) {
                [weakSelf launchCIProductViewController:YES order:nil customer:customer];
            }
        }
    }];
}

- (void)openOrder:(Order *)order {
    if (self.currentOrder) {
        NSNumber *customerId = self.currentOrder.customerId;
        NSManagedObjectID *orderObjectID = order.objectID;

        __weak CIOrderViewController *weakSelf = self;
        [[CurrentSession mainQueueContext] performBlock:^{
            Customer *customer = [CoreDataManager getCustomer:customerId managedObjectContext:[CurrentSession mainQueueContext]];
            if (customer) {
                [weakSelf launchCIProductViewController:NO order:orderObjectID customer:[customer asDictionary]];
            } else {
                MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:NO];
                hud.removeFromSuperViewOnHide = YES;
                hud.labelText = @"Loading customer";
                [hud show:NO];

                [[CinchJSONAPIClient sharedInstance] GET:kDBGETCUSTOMER([customerId stringValue]) parameters:@{ kAuthToken:[CurrentSession instance].authToken } success:^(NSURLSessionDataTask *task, id JSON) {
                    [weakSelf launchCIProductViewController:NO order:orderObjectID customer:(NSDictionary *) JSON];
                    [hud hide:NO];
                } failure:^(NSURLSessionDataTask *task, NSError *error) {
                    [hud hide:NO];
                    [[[UIAlertView alloc] initWithTitle:@"Error!" message:[NSString stringWithFormat:@"There was an error loading customers%@", [error localizedDescription]] delegate:nil
                                      cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                    NSLog(@"%@", [error localizedDescription]);
                }];
            }
        }];
    }
}

- (void)launchCIProductViewController:(bool)newOrder order:(NSManagedObjectID *)orderID customer:(NSDictionary *)customer {
    static CIProductViewController *productViewController;
    static dispatch_once_t loadProductViewControllerOnce;
    dispatch_once(&loadProductViewControllerOnce, ^{
        productViewController = [[CIProductViewController alloc] initWithNibName:@"CIProductViewController" bundle:nil];
    });

    [productViewController reinit];
    productViewController.delegate = self;
    productViewController.newOrder = newOrder;
    productViewController.customer = customer;

    if (!newOrder && orderID) {
        [[CurrentSession mainQueueContext] performBlockAndWait:^{
            // let it use a separate instance for safety
            Order *order = (Order *) [[CurrentSession mainQueueContext] existingObjectWithID:orderID error:nil];
            productViewController.order = order;
        }];
    } else {
        productViewController.order = nil;
    }

    static CISlidingProductViewController *slidingProductViewController;
    static dispatch_once_t loadSlidingViewControllerOnce;
    dispatch_once(&loadSlidingViewControllerOnce, ^{
        slidingProductViewController = [[CISlidingProductViewController alloc] initWithTopViewController:productViewController];
    });

    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:slidingProductViewController];
    navController.navigationBarHidden = NO;
    [self presentViewController:navController animated:YES completion:nil];
}

#pragma mark - CINavViewManagerDelegate

- (UINavigationController *)navigationControllerForNavViewManager {
    return self.navigationController;
}

- (UINavigationItem *)navigationItemForNavViewManager {
    return self.navigationItem;
}

- (NSArray *)rightActionItems {
    UIBarButtonItem *addItem = [CIBarButton buttonItemWithText:@"\uf067" style:CIBarButtonStyleRoundButton orientation:(CIBarButtonOrientationRight) handler:^(id sender) {
        [self addNewOrder];
    }];
    return @[addItem];
}

- (void)navViewDidSearch:(NSString *)searchTerm inputCompleted:(BOOL)inputCompleted {
    if (!self.isLoadingOrders) {
        [self.ordersTableViewController filterToQueryTerm:searchTerm];
    }
}

- (BOOL)navViewWillSearch {
    if (self.isLoadingOrders) {
        [[[UIAlertView alloc] initWithTitle:@"Orders Reloading" message:@"Orders are currently being reloaded from the server in the background. Order searches cannot be conducted until complete." delegate:nil
                          cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }
    return !self.isLoadingOrders;
}

- (void)navViewDidEndSearch {
    //[self.keyCommander mayBecomeFirstResponder];
}

#pragma mark - Keyboard

//- (BOOL)canBecomeFirstResponder {
//    return YES;
//}
//
//- (NSArray *)keyCommands {
//    return @[];
////    return [self.keyCommander allKeys];
//}
//
//- (void)alphaNumericKeyPressed {
//    [self.navViewManager ]
//}
//
//- (void)upKeyPressed {
//    [self.ordersTableViewController selectSibling:YES];
//}
//
//- (void)downKeyPressed {
//    [self.ordersTableViewController selectSibling:NO];
//}
//
//- (void)enterKeyPressed {
//    [self addNewOrder];
//}
//
//- (void)escapeKeyPressed {
//    NSLog(@"key pressed");
//}

@end
