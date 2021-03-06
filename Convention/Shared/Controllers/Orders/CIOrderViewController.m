//
//  CIOrderViewController.m
//  Convention
//
//  Created by Matthew Clark on 12/8/11.
//  Copyright (c) 2011 MotionMobs. All rights reserved.
//

#import "CIOrderViewController.h"
#import "config.h"
#import "Configurations.h"
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
#import "MBProgressHUD.h"
#import "CoreDataUtil.h"
#import "CurrentSession.h"
#import "CIOrderDetailTableViewController.h"
#import "CITableViewHeaderView.h"
#import "CIAlertView.h"
#import "CIButton.h"
#import "View+MASAdditions.h"

@interface CIOrderViewController ()

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

@property UIButton *orderDetailEmailButton;
@property UIButton *orderDetailCopyButton;
@property UIButton *orderDetailEditButton;
@property UIButton *orderDetailDeleteButton;

@property CIOrderDetailTableViewController *orderDetailTableViewController;
@property (weak, nonatomic) IBOutlet UIView *orderDetailTableParentView;
@property (weak, nonatomic) IBOutlet CITableViewHeaderView *orderDetailHeaderView;
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

    [Configurations instance];
    self.orderDetailView.hidden = YES;
    self.orderDetailNotesLabel.verticalAlignment = VerticalAlignmentMiddle;

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

    [self initializeOrderDetailActions];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ordersReloading:) name:OrderReloadStartedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ordersReloadComplete:) name:OrderReloadCompleteNotification object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:OrderReloadStartedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:OrderReloadCompleteNotification object:nil];
}

- (void)initializeOrderDetailActions {
    self.orderDetailView;

    self.orderDetailEditButton = [[CIButton alloc] initWithOrigin:CGPointZero title:@"Edit" size:CIButtonSizeLarge style:CIButtonStyleNeutral];
    [self.orderDetailEditButton addTarget:self action:@selector(orderDetailEditButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.orderDetailView addSubview:self.orderDetailEditButton];
    [self.orderDetailEditButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(@0);
        make.bottom.equalTo(self.orderDetailView).offset(-15);
        make.height.equalTo(@(self.orderDetailEditButton.frame.size.height));
        make.width.equalTo(@(self.orderDetailEditButton.frame.size.width));
    }];

    self.orderDetailCopyButton = [[CIButton alloc] initWithOrigin:CGPointZero title:@"Copy" size:CIButtonSizeLarge style:CIButtonStyleNeutral];
    [self.orderDetailCopyButton addTarget:self action:@selector(orderDetailCopyButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.orderDetailView addSubview:self.orderDetailCopyButton];
    [self.orderDetailCopyButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.orderDetailEditButton.mas_left).offset(-8);
        make.bottom.equalTo(self.orderDetailView).offset(-15);
        make.height.equalTo(@(self.orderDetailCopyButton.frame.size.height));
        make.width.equalTo(@(self.orderDetailCopyButton.frame.size.width));
    }];

    self.orderDetailEmailButton = [[CIButton alloc] initWithOrigin:CGPointZero title:@"Email" size:CIButtonSizeLarge style:CIButtonStyleNeutral];
    [self.orderDetailEmailButton addTarget:self action:@selector(orderDetailEmailButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.orderDetailView addSubview:self.orderDetailEmailButton];
    [self.orderDetailEmailButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.orderDetailCopyButton.mas_left).offset(-8);
        make.bottom.equalTo(self.orderDetailView).offset(-15);
        make.height.equalTo(@(self.orderDetailEmailButton.frame.size.height));
        make.width.equalTo(@(self.orderDetailEmailButton.frame.size.width));
    }];

    self.orderDetailDeleteButton = [[CIButton alloc] initWithOrigin:CGPointZero title:@"Delete" size:CIButtonSizeLarge style:CIButtonStyleDestroy];
    [self.orderDetailDeleteButton addTarget:self action:@selector(orderDetailDeleteButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.orderDetailView addSubview:self.orderDetailDeleteButton];
    [self.orderDetailDeleteButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(@0);
        make.bottom.equalTo(self.orderDetailView).offset(-15);
        make.height.equalTo(@(self.orderDetailDeleteButton.frame.size.height));
        make.width.equalTo(@(self.orderDetailDeleteButton.frame.size.width));
    }];
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

- (void)orderDetailEditButtonTapped {
    [self openOrder:self.currentOrder];
}

- (void)orderDetailDeleteButtonTapped {
    [self requestDelete:self.currentOrder];
}

- (void)orderDetailCopyButtonTapped {
    NSString *alertMessage = [NSString stringWithFormat:@"Create a copy of %@ order?",
                                                        self.currentOrder.customerName ? [NSString stringWithFormat:@"%@'s", self.currentOrder.customerName] : @"this", nil];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Order %@", self.currentOrder.orderId]
                                                    message:alertMessage
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"Copy", nil];
    [UIAlertViewDelegateWithBlock showAlertView:alert withCallBack:^(NSInteger buttonIndex) {
        if (buttonIndex == 1) {
            Order *newOrder = [OrderManager copyOrder:self.currentOrder];
            [self persistentOrderUpdated:newOrder];
            [self openOrder:newOrder];
        }
    }];
}

- (void)orderDetailEmailButtonTapped {
    if (self.currentOrder && [self.currentOrder.status isEqualToString:@"complete"]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Email Invoice"
                                                        message:@"Please provide the recipient's email address."
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Send", nil];
        alert.alertViewStyle = UIAlertViewStylePlainTextInput;
        Customer *customer = (Customer *) [[CoreDataUtil sharedManager] fetchObject:@"Customer" inContext:[CurrentSession mainQueueContext] withPredicate:[NSPredicate predicateWithFormat:@"customer_id = %@", self.currentOrder.customerId]];
        if (customer) {
            [alert textFieldAtIndex:0].text = customer.email;
        }
        [UIAlertViewDelegateWithBlock showAlertView:alert withCallBack:^(NSInteger buttonIndex) { 
            if (1 == buttonIndex) {
                NSString *emailTo = [alert textFieldAtIndex:0].text;
                if (emailTo) {
                    __weak CIOrderViewController *weakSelf = self;
                    [OrderManager syncOrderDetails:self.currentOrder sendEmailTo:emailTo attachHudTo:self.view onSuccess:^{
                        [weakSelf persistentOrderUpdated:weakSelf.currentOrder];
                        [CIAlertView alertSyncEvent:@"Invoice Emailed"];
                    } onFailure:nil];
                }
            }
        }];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Pending Order"
                                                        message:@"Order must be completed before emailing."
                                                       delegate:self
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles:nil];
        [UIAlertViewDelegateWithBlock showAlertView:alert withCallBack:^(NSInteger buttonIndex) { }];
    }
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
        
        Configurations *config = [Configurations instance];
        
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
        
        if (![order.notes isKindOfClass:[NSNull class]]) {
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

    if (orderAccessible && self.currentOrder && [self.currentOrder.status isEqualToString:@"complete"]) {
        self.orderDetailEmailButton.userInteractionEnabled = YES;
        self.orderDetailEmailButton.layer.borderColor = [UIColor colorWithRed:0.902 green:0.494 blue:0.129 alpha:1.000].CGColor;
        self.orderDetailEmailButton.backgroundColor = [UIColor colorWithRed:0.922 green:0.647 blue:0.416 alpha:1.000];
    } else {
        self.orderDetailEmailButton.userInteractionEnabled = NO;
        self.orderDetailEmailButton.layer.borderColor = [UIColor colorWithRed:0.922 green:0.800 blue:0.682 alpha:1.000].CGColor;
        self.orderDetailEmailButton.backgroundColor = [UIColor colorWithRed:0.922 green:0.800 blue:0.682 alpha:1.000];
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
    } else if (updateStatus == PartialOrderCancelled) {
        [self persistentOrderUpdated:nil];
    }
}

#pragma mark - Events

- (void)addNewOrder {
    [self.navViewManager clearSearch]; // our search uses a contains query, this cannot be used in conjunction with NSFetchResultsController when doing inserts/deletes
    CISelectCustomerViewController *ci = [[CISelectCustomerViewController alloc] initWithNibName:@"CICustomerInfoViewController" bundle:nil];
    ci.delegate = self;
    [self presentViewController:ci animated:YES completion:nil];
}

- (void)customerSelected:(NSDictionary *)info {
    [self startNewOrderForCustomer:info];
}

- (void)requestDelete:(Order *)order {
    if (order) {
        NSString *alertMessage = [NSString stringWithFormat:@"Are you sure you want to delete %@ order?",
                        order.customerName ? [NSString stringWithFormat:@"%@'s", order.customerName] : @"this", nil];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Order %@", self.currentOrder.orderId]
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
    NSNumber *customerId = order.customerId;
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


            [[CinchJSONAPIClient sharedInstance] GET:[NSString stringWithFormat:kDBGETCUSTOMER, [[[CurrentSession instance] showId] intValue], [customerId intValue]]
                                          parameters:@{kAuthToken : [CurrentSession instance].authToken}
                                             success:^(NSURLSessionDataTask *task, id JSON) {
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

    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:productViewController];
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

@end
