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
#import "OrderCoreDataManager.h"
#import "Order+Extensions.h"
#import "LineItem+Extensions.h"
#import "NumberUtil.h"
#import "OrderTotals.h"
#import "OrderSubtotalsByDate.h"
#import "MBProgressHUD.h"
#import "CoreDataUtil.h"
#import "CurrentSession.h"
#import "KeyCommander.h"

@interface CIOrderViewController () {
    ShowConfigurations *showConfig;
}

@property Order *currentOrder;
@property NSArray *currentLineItems; //NSArray[LineItem]
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

@property (weak, nonatomic) IBOutlet UIView *orderDetailTableParentView;
@property (weak, nonatomic) IBOutlet UITableView *orderDetailTable;

@property (weak, nonatomic) IBOutlet UIButton *orderDetailSaveButton;
@property (weak, nonatomic) IBOutlet UIButton *orderDetailEditButton;
@property (weak, nonatomic) IBOutlet UIButton *orderDetailDeleteButton;

@property (weak, nonatomic) IBOutlet UILabel *orderDetailTableItemIdLabel;
@property (weak, nonatomic) IBOutlet UILabel *orderDetailTableDescriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *orderDetailTableShipdatesLabel;
@property (weak, nonatomic) IBOutlet UILabel *orderDetailTableQuantityLabel;
@property (weak, nonatomic) IBOutlet UILabel *orderDetailTablePriceLabel;
@property (weak, nonatomic) IBOutlet UILabel *orderDetailTableTotalLabel;

@property (assign) float totalGross;
@property (assign) float totalDiscounts;
@property (assign) float totalFinal;

@property (strong, nonatomic) NSMutableArray *subtotalLines;

@end

@implementation CIOrderViewController

@synthesize currentOrder = _currentOrder;

- (void)persistentOrderUpdated:(Order *)updatedOrder {
    self.NoOrdersLabel.hidden = self.ordersTableViewController.hasOrders;
    
    self.currentOrder = updatedOrder;
    [self.ordersTableViewController selectOrder:updatedOrder.objectID];
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

    self.orderDetailTable.separatorColor = [UIColor colorWithRed:0.808 green:0.808 blue:0.827 alpha:1];
    self.orderDetailTable.rowHeight = 40;

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

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ordersReloading:) name:OrderReloadStartedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ordersReloadComplete:) name:OrderReloadCompleteNotification object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:OrderReloadStartedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:OrderReloadCompleteNotification object:nil];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    if ([self.orderDetailTable respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.orderDetailTable setSeparatorInset:UIEdgeInsetsZero];
    }
    if ([self.orderDetailTable respondsToSelector:@selector(setLayoutMargins:)]) {
        [self.orderDetailTable setLayoutMargins:UIEdgeInsetsZero];
    }
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

- (Order *)currentOrder {
    return _currentOrder;
}

- (void)setCurrentOrder:(Order *)currentOrder {
    if (currentOrder) {
        _currentOrder = currentOrder;
        NSArray *lineItemsArray = _currentOrder.lineItems.allObjects;
        self.currentLineItems = [lineItemsArray sortedArrayUsingDescriptors:@[
                [[NSSortDescriptor alloc] initWithKey:@"product.sequence" ascending:TRUE],
                [[NSSortDescriptor alloc] initWithKey:@"product.invtid" ascending:TRUE]
        ]];
    } else {
        _currentOrder = nil;
        self.currentLineItems = nil;
    }
}

- (void)displayOrderDetail:(Order *)order {
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
            self.orderDetailNotesLabel.text = order.notes;
            self.orderDetailNotesView.hidden = NO;
            orderDetailTableOriginY += self.orderDetailNotesView.frame.size.height + 8;
        } else {
            self.orderDetailNotesView.hidden = YES;
        }
        self.orderDetailTableParentView.frame = CGRectMake(0, orderDetailTableOriginY, self.orderDetailTableParentView.frame.size.width, 630 - orderDetailTableOriginY);
        
        self.subtotalLines = [NSMutableArray array];
        
        self.customer.text = @"";
        self.authorizer.text = @"";
        self.customer.text = [self.currentOrder getCustomerDisplayName];
        self.authorizer.text = order.authorizedBy != nil? order.authorizedBy : @"";
        
        if (order && ![order.notes isKindOfClass:[NSNull class]]) {
            self.notes.text = order.notes;
        } else {
            self.notes.text = @"";
        }
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"MM/dd/yyyy"];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
        
        [order.calculateShipDateSubtotals each:^(NSDate *shipDate, NSNumber *totalOnShipDate) {
            [self.subtotalLines addObject:@[
                                            [NSString stringWithFormat:@"Shipping on %@", [dateFormatter stringFromDate:shipDate]],
                                            [NumberUtil formatDollarAmount:totalOnShipDate]
                                            ]];
        }];
        
        OrderTotals *totals = order.calculateTotals;
        if (self.totalDiscounts > 0) {
            [self.subtotalLines addObject:@[@"SUBTOTAL", [NumberUtil formatDollarAmount:totals.grossTotal]]];
            [self.subtotalLines addObject:@[@"DISCOUNT", [NumberUtil formatDollarAmount:totals.discountTotal]]];
        }
        [self.subtotalLines addObject:@[@"TOTAL", [NumberUtil formatDollarAmount:totals.total]]];
        
        [self.orderDetailTable reloadData];
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

#pragma mark - UITableView Datasource

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }

    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }

    if (tableView == self.orderDetailTable) {
        int rows = self.currentOrder && self.currentLineItems ? self.currentLineItems.count : 0;
        if (indexPath.row > rows) {
            cell.backgroundColor = [UIColor colorWithRed:0.976 green:0.976 blue:0.976 alpha:1];
        } else {
            cell.backgroundColor = [UIColor whiteColor];
        }
    } else {
        if(indexPath.row % 2 == 0) {
            cell.backgroundColor = [UIColor colorWithRed:0.976 green:0.976 blue:0.976 alpha:1];
        } else {
            cell.backgroundColor = [UIColor colorWithRed:1.000 green:1.000 blue:1.000 alpha:1];
        }
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.orderDetailTable) {
        int rows = self.currentOrder && self.currentLineItems ? self.currentLineItems.count : 0;
        if (rows) {
            rows += 1 + self.subtotalLines.count;
        }
        return rows;
    }

    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    int rows = self.currentOrder && self.currentOrder.lineItems ? self.currentOrder.lineItems.count : 0;

    if (indexPath.row >= rows) {
        static NSString *odcId = @"stlId";

        int index = indexPath.row - rows - 1;

        UILabel *cleftLabel = nil;
        UILabel *crightLabel = nil;

        UITableViewCell *cell = [self.orderDetailTable dequeueReusableCellWithIdentifier:odcId];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:odcId];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;

            cleftLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 5, 482 + 89, 40)];
            cleftLabel.tag = 1001;
            cleftLabel.backgroundColor = [UIColor clearColor];
            cleftLabel.font = [UIFont regularFontOfSize:14];
            cleftLabel.textColor = [UIColor colorWithWhite:0.3 alpha:1.0];
            cleftLabel.numberOfLines = 0;
            cleftLabel.textAlignment = NSTextAlignmentRight;
            [cell.contentView addSubview:cleftLabel];

            crightLabel = [[UILabel alloc] initWithFrame:CGRectMake(577, 5, 80, 40)];
            crightLabel.tag = 1002;
            crightLabel.backgroundColor = [UIColor clearColor];
            crightLabel.font = [UIFont semiboldFontOfSize:14];
            crightLabel.textColor = [UIColor colorWithWhite:0.3 alpha:1.0];
            crightLabel.numberOfLines = 0;
            crightLabel.textAlignment = NSTextAlignmentRight;
            crightLabel.numberOfLines = 1;
            crightLabel.adjustsFontSizeToFitWidth = YES;
            [cell.contentView addSubview:crightLabel];
        } else {
            cleftLabel = (UILabel*)[cell.contentView viewWithTag:1001];
            crightLabel = (UILabel*)[cell.contentView viewWithTag:1002];
        }

        if (index >= 0) {
            NSArray *subtotalLine = self.subtotalLines[index];
            cleftLabel.text = subtotalLine[0];
            crightLabel.text = subtotalLine[1];
        } else {
            cleftLabel.text = @"";
            crightLabel.text = @"";
        }

        return cell;
    } else {
        static NSString *odcId = @"odcId";

        UILabel *citemLabel = nil;
        UILabel *cdescriptionLabel = nil;
        UILabel *csdLabel = nil;
        UILabel *csqLabel = nil;
        UILabel *cpriceLabel = nil;
        UILabel *ctotalLabel = nil;

        UITableViewCell *cell = [self.orderDetailTable dequeueReusableCellWithIdentifier:odcId];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:odcId];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            float currentX = 15.0;
            float margin = 7.0;
            float maxWidth = 667.0;
            
            float itemLabelWidth = 90.0;
            float shipDateLabelWidth = 60.0;
            float shipQuantityLabelWidth = 60.0;
            float priceLabelWidth = 90.0;
            float totalLabelWidth = 90.0;
            float descriptionLabelWidth = maxWidth - currentX - margin -
                    itemLabelWidth - margin -
                    shipQuantityLabelWidth - margin -
                    priceLabelWidth - margin -
                    totalLabelWidth - margin;

            if ([ShowConfigurations instance].isOrderShipDatesType) {
                descriptionLabelWidth = descriptionLabelWidth - shipDateLabelWidth - margin;
            }

            citemLabel = [[UILabel alloc] initWithFrame:CGRectMake(currentX, 5, itemLabelWidth, 40)];
            citemLabel.tag = 1001;
            citemLabel.backgroundColor = [UIColor clearColor];
            citemLabel.font = [UIFont regularFontOfSize:14];
            citemLabel.textColor = [UIColor colorWithWhite:0.3 alpha:1.0];
            citemLabel.numberOfLines = 0;
            citemLabel.textAlignment = NSTextAlignmentLeft;
            [cell.contentView addSubview:citemLabel];
            self.orderDetailTableItemIdLabel.frame = CGRectMake(currentX, self.orderDetailTableItemIdLabel.frame.origin.y, itemLabelWidth, self.orderDetailTableItemIdLabel.frame.size.height);
            currentX = citemLabel.frame.origin.x + citemLabel.frame.size.width + margin;

            cdescriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(currentX, 5, descriptionLabelWidth, 40)];
            cdescriptionLabel.tag = 1002;
            cdescriptionLabel.backgroundColor = [UIColor clearColor];
            cdescriptionLabel.font = [UIFont regularFontOfSize:14];
            cdescriptionLabel.textColor = [UIColor colorWithWhite:0.3 alpha:1.0];
            cdescriptionLabel.numberOfLines = 0;
            cdescriptionLabel.textAlignment = NSTextAlignmentLeft;
            cdescriptionLabel.numberOfLines = 1;
            cdescriptionLabel.adjustsFontSizeToFitWidth = YES;
            [cell.contentView addSubview:cdescriptionLabel];
            self.orderDetailTableDescriptionLabel.frame = CGRectMake(currentX, self.orderDetailTableDescriptionLabel.frame.origin.y, descriptionLabelWidth, self.orderDetailTableDescriptionLabel.frame.size.height);
            currentX = cdescriptionLabel.frame.origin.x + cdescriptionLabel.frame.size.width + margin;

            if ([ShowConfigurations instance].isOrderShipDatesType) {
                csdLabel = [[UILabel alloc] initWithFrame:CGRectMake(currentX, 5, shipDateLabelWidth, 40)];
                csdLabel.tag = 1003;
                csdLabel.backgroundColor = [UIColor clearColor];
                csdLabel.font = [UIFont regularFontOfSize:14];
                csdLabel.textColor = [UIColor colorWithWhite:0.3 alpha:1.0];
                csdLabel.numberOfLines = 0;
                csdLabel.textAlignment = NSTextAlignmentLeft;
                [cell.contentView addSubview:csdLabel];
                self.orderDetailTableShipdatesLabel.frame = CGRectMake(currentX, self.orderDetailTableShipdatesLabel.frame.origin.y, shipDateLabelWidth, self.orderDetailTableShipdatesLabel.frame.size.height);
                currentX = csdLabel.frame.origin.x + csdLabel.frame.size.width + margin;
            }
            
            csqLabel = [[UILabel alloc] initWithFrame:CGRectMake(currentX, 5, shipQuantityLabelWidth, 40)];
            csqLabel.tag = 1004;
            csqLabel.backgroundColor = [UIColor clearColor];
            csqLabel.font = [UIFont regularFontOfSize:14];
            csqLabel.textColor = [UIColor colorWithWhite:0.3 alpha:1.0];
            csqLabel.numberOfLines = 0;
            csqLabel.textAlignment = NSTextAlignmentRight;
            csqLabel.numberOfLines = 1;
            csqLabel.adjustsFontSizeToFitWidth = YES;
            [cell.contentView addSubview:csqLabel];
            self.orderDetailTableQuantityLabel.frame = CGRectMake(currentX, self.orderDetailTableQuantityLabel.frame.origin.y, shipQuantityLabelWidth, self.orderDetailTableQuantityLabel.frame.size.height);
            currentX = csqLabel.frame.origin.x + csqLabel.frame.size.width + margin;

            cpriceLabel = [[UILabel alloc] initWithFrame:CGRectMake(currentX, 5, priceLabelWidth, 40)];
            cpriceLabel.tag = 1005;
            cpriceLabel.backgroundColor = [UIColor clearColor];
            cpriceLabel.font = [UIFont regularFontOfSize:14];
            cpriceLabel.textColor = [UIColor colorWithWhite:0.3 alpha:1.0];
            cpriceLabel.numberOfLines = 0;
            cpriceLabel.textAlignment = NSTextAlignmentRight;
            cpriceLabel.numberOfLines = 1;
            cpriceLabel.adjustsFontSizeToFitWidth = YES;
            [cell.contentView addSubview:cpriceLabel];
            self.orderDetailTablePriceLabel.frame = CGRectMake(currentX, self.orderDetailTablePriceLabel.frame.origin.y, priceLabelWidth, self.orderDetailTablePriceLabel.frame.size.height);
            currentX = cpriceLabel.frame.origin.x + cpriceLabel.frame.size.width + margin;

            ctotalLabel = [[UILabel alloc] initWithFrame:CGRectMake(currentX, 5, totalLabelWidth, 40)];
            ctotalLabel.tag = 1006;
            ctotalLabel.backgroundColor = [UIColor clearColor];
            ctotalLabel.font = [UIFont semiboldFontOfSize:14];
            ctotalLabel.textColor = [UIColor colorWithWhite:0.3 alpha:1.0];
            ctotalLabel.numberOfLines = 0;
            ctotalLabel.textAlignment = NSTextAlignmentRight;
            ctotalLabel.numberOfLines = 1;
            ctotalLabel.adjustsFontSizeToFitWidth = YES;
            [cell.contentView addSubview:ctotalLabel];
            self.orderDetailTableTotalLabel.frame = CGRectMake(currentX, self.orderDetailTableTotalLabel.frame.origin.y, totalLabelWidth, self.orderDetailTableTotalLabel.frame.size.height);
        } else {
            citemLabel = (UILabel*)[cell.contentView viewWithTag:1001];
            cdescriptionLabel = (UILabel*)[cell.contentView viewWithTag:1002];
            csdLabel = (UILabel*)[cell.contentView viewWithTag:1003];
            csqLabel = (UILabel*)[cell.contentView viewWithTag:1004];
            cpriceLabel = (UILabel*)[cell.contentView viewWithTag:1005];
            ctotalLabel = (UILabel*)[cell.contentView viewWithTag:1006];
        }

        LineItem *lineItem = self.currentLineItems[indexPath.row];
        citemLabel.text = [NSString stringWithFormat:@"#%@", lineItem.productId];
        cdescriptionLabel.text = [lineItem.description1 stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if ([ShowConfigurations instance].isOrderShipDatesType) {
            csdLabel.text = [NSString stringWithFormat:@"%d", lineItem.shipDates.count];
        }
        csqLabel.text = [NSString stringWithFormat:@"%d", [lineItem totalQuantity]];

        cpriceLabel.text = [NumberUtil formatDollarAmount:lineItem.price];
        ctotalLabel.text = [NumberUtil formatDollarAmount:[NSNumber numberWithDouble:lineItem.subtotal]];

        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.orderDetailTable) {
        return 50;
    } else {
        LineItem *data = [self.currentLineItems objectAtIndex:(NSUInteger) [indexPath row]];
        if (data.warnings.count > 0 || data.errors.count > 0)
            return 44 + ((data.warnings.count + data.errors.count) * 42);
        else
            return 44;
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
    ci.authToken = self.authToken;
    [self presentViewController:ci animated:YES completion:nil];
}

- (void)customerSelected:(NSDictionary *)info {
    [self startNewOrderForCustomer:info];
}

- (void)logout {
    void (^clearSettings)(void) = ^{
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kSettingsUsernameKey];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kSettingsPasswordKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    };

    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if (self.authToken) parameters[kAuthToken] = self.authToken;

    [[CinchJSONAPIClient sharedInstance] DELETE:kDBLOGOUT parameters:parameters success:^(NSURLSessionDataTask *task, id JSON) {
        clearSettings();
        [self dismissViewControllerAnimated:YES completion:nil];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        [[[UIAlertView alloc] initWithTitle:@"Error"
                                    message:[NSString stringWithFormat:@"There was an error logging out please try again! Error:%@", [error localizedDescription]]
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];

    }];
}

- (void)saveOrder {
    if (nil == self.currentOrder) {
        return;
    }
    __weak CIOrderViewController *weakSelf = self;
    [OrderCoreDataManager syncOrder:self.currentOrder attachHudTo:self.view onSuccess:^(Order *order) {
        [weakSelf persistentOrderUpdated:order];
    } onFailure:nil];
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
    [OrderCoreDataManager deleteOrder:order onSuccess:^{
        if (isSelectedOrder) {
            weakSelf.orderDetailView.hidden = YES;
            weakSelf.currentOrder = nil;
        }
        [deleteHUD hide:NO];
    } onFailure:^{
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

                [[CinchJSONAPIClient sharedInstance] GET:kDBGETCUSTOMER([customerId stringValue]) parameters:@{ kAuthToken: self.authToken } success:^(NSURLSessionDataTask *task, id JSON) {
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
    UIBarButtonItem *addItem = [CIBarButton buttonItemWithText:@"\uf067" style:CIBarButtonStyleRoundButton handler:^(id sender) {
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
