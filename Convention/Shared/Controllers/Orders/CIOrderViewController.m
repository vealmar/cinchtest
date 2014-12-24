//
//  CIOrderViewController.m
//  Convention
//
//  Created by Matthew Clark on 12/8/11.
//  Copyright (c) 2011 MotionMobs. All rights reserved.
//

#import <Underscore.m/Underscore.h>
#import <JSONKit/JSONKit.h>
#import <QuartzCore/QuartzCore.h>
#import "CIOrderViewController.h"
#import "CIOrderCell.h"
#import "config.h"
#import "MBProgressHUD.h"

#import "CICalendarViewController.h"
#import "SettingsManager.h"
#import "StringManipulation.h"
#import "CoreDataUtil.h"
#import "Order.h"
#import "ShowConfigurations.h"
#import "AnOrder.h"
#import "ALineItem.h"
#import "CoreDataManager.h"
#import "UIAlertViewDelegateWithBlock.h"
#import "Customer.h"
#import "CIProductViewControllerHelper.h"
#import "Product.h"
#import "Product+Extensions.h"
#import "SegmentedControlHelper.h"
#import "NilUtil.h"
#import "CISlidingProductViewController.h"
#import "DateUtil.h"
#import "NotificationConstants.h"
#import "CinchJSONAPIClient.h"
#import "CIAppDelegate.h"
#import "VALabel.h"
#import "ThemeUtil.h"
#import "CIBarButton.h"


@interface CIOrderViewController () {
    AnOrder *currentOrder;
    BOOL isLoadingOrders;
    UITextField *activeField;
    PullToRefreshView *pull;

    NSDictionary *availablePrinters;
    NSString *currentPrinter;

    NSIndexPath *selectedItemRowIndexPath;

    NSMutableArray *partialOrders;
    NSMutableArray *persistentOrders;

    CIProductViewControllerHelper *helper;
    SegmentedControlHelper *cancelDaysHelper;
    ShowConfigurations *showConfig;
}

@property BOOL unsavedChangesPresent;

@property (weak, nonatomic) IBOutlet UIView *orderDetailView;
@property (weak, nonatomic) IBOutlet UILabel *orderDetailOrderNumberLabel;
@property (weak, nonatomic) IBOutlet UIView *orderDetailCustomerView;
@property (weak, nonatomic) IBOutlet UILabel *orderDetailCustomerLabel;
@property (weak, nonatomic) IBOutlet UIView *orderDetailAuthorizedView;
@property (weak, nonatomic) IBOutlet UILabel *orderDetailAuthorizedLabel;
@property (weak, nonatomic) IBOutlet UIView *orderDetailPaymentTermsView;
@property (weak, nonatomic) IBOutlet UILabel *orderDetailPaymentTermsLabel;
@property (weak, nonatomic) IBOutlet UIView *orderDetailNotesView;
@property (weak, nonatomic) IBOutlet VALabel *orderDetailNotesLabel;

@property (weak, nonatomic) IBOutlet UIView *orderDetailTableParentView;
@property (weak, nonatomic) IBOutlet UITableView *orderDetailTable;

@property (weak, nonatomic) IBOutlet UIButton *orderDetailSaveButton;
@property (weak, nonatomic) IBOutlet UIButton *orderDetailEditButton;
@property (weak, nonatomic) IBOutlet UIButton *orderDetailDeleteButton;

@property (assign) float totalGross;
@property (assign) float totalDiscounts;
@property (assign) float totalFinal;

@property (strong, nonatomic) NSMutableArray *subtotalLines;
@end

@implementation
CIOrderViewController

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    currentOrder = nil;
    isLoadingOrders = NO;

    self.NoOrdersLabel.font = [UIFont fontWithName:kFontName size:25.f];
    self.customer.font = [UIFont fontWithName:kFontName size:14.f];
    self.orderShipDatesTextView.font = [UIFont fontWithName:kFontName size:14.f];

    showConfig = [ShowConfigurations instance];
    self.logoImage.image = [showConfig logo];
    if (!showConfig.isOrderShipDatesType) self.orderShipDatesView.hidden = YES;
    if (showConfig.vouchers) {
        self.voucherItemTotalLabel.text = @"VOUCHER";
    } else {
        self.voucherItemTotalLabel.text = @"ITEM TOTAL";
        self.voucherTotal.hidden = YES;
        self.voucherTotalLabel.hidden = YES;
    }
    if (showConfig.discounts) {
        self.grossTotalLabel.text = @"Gross Total";
    } else {
        self.grossTotalLabel.text = @"Total";
        self.discountTotal.hidden = YES;
        self.discountTotalLabel.hidden = YES;
        self.totalLabel.hidden = YES;
        self.total.hidden = YES;
    }
    self.printButton.hidden = !showConfig.printing;
    self.cancelDaysView.hidden = !showConfig.cancelOrder;
    self.unsavedChangesPresent = NO;
    [self adjustTotals];
    self.orderDetailView.hidden = YES;
    if ([ShowConfigurations instance].printing) currentPrinter = [[SettingsManager sharedManager] lookupSettingByString:@"printer"];
    pull = [[PullToRefreshView alloc] initWithScrollView:self.sideTable];
    [pull setDelegate:self];
    [self.sideTable addSubview:pull];
    [self loadOrders:YES highlightOrder:nil];
    helper = [[CIProductViewControllerHelper alloc] init];
    cancelDaysHelper = [[SegmentedControlHelper alloc] initForCancelByDays];

    self.sideTable.separatorStyle = UITableViewCellSeparatorStyleSingleLine;

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

    CINavViewManager *navViewManager = [[CINavViewManager alloc] init:YES];
    navViewManager.delegate = self;
    navViewManager.title = [ThemeUtil titleTextWithFontSize:18 format:@"%s", @"Orders"];
    [navViewManager setupNavBar];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    if ([self.sideTable respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.sideTable setSeparatorInset:UIEdgeInsetsZero];
    }

    if ([self.sideTable respondsToSelector:@selector(setLayoutMargins:)]) {
        [self.sideTable setLayoutMargins:UIEdgeInsetsZero];
    }

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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow)
                                                 name:UIKeyboardWillShowNotification object:self.view.window];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide)
                                                 name:UIKeyboardDidHideNotification object:self.view.window];

    [self loadOrders:NO highlightOrder:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidHideNotification object:nil];
    if ([ShowConfigurations instance].printing) [[NSNotificationCenter defaultCenter] removeObserver:self name:PrintersLoadedNotification object:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return UIInterfaceOrientationIsLandscape(interfaceOrientation); //we only support landscape orientation.
}

- (void)setUnsavedChangesPresent:(BOOL)unsavedChangesPresent {
    _unsavedChangesPresent = unsavedChangesPresent;
    [self updateOrderActions];
}


- (void)adjustTotals {
    return;
    NSMutableArray *visibleTotalFields = [[NSMutableArray alloc] init];
    if (!self.grossTotal.hidden) [visibleTotalFields addObject:@{@"field" : self.grossTotal, @"label" : self.grossTotalLabel}];
    if (!self.discountTotal.hidden) [visibleTotalFields addObject:@{@"field" : self.discountTotal, @"label" : self.discountTotalLabel}];
    if (!self.voucherTotal.hidden) [visibleTotalFields addObject:@{@"field" : self.voucherTotal, @"label" : self.voucherTotalLabel}];
    if (!self.total.hidden) [visibleTotalFields addObject:@{@"field" : self.total, @"label" : self.totalLabel}];
    int availableWidth = 400;
    int widthPerField = availableWidth / visibleTotalFields.count;
    int marginRightPerField = 2;
    widthPerField = widthPerField - marginRightPerField;
    int x = 10;
    for (NSDictionary *totalField in visibleTotalFields) {
        UITextField *textField = ((UITextField *) [totalField objectForKey:@"field"]);
        textField.text = @"0";
        textField.frame = CGRectMake(x, 587, widthPerField, 34);
        ((UILabel *) [totalField objectForKey:@"label"]).frame = CGRectMake(x, 613, widthPerField, 34);
        x = x + widthPerField + marginRightPerField;//2 is the right margin
    }
}

#pragma mark - Data access methods

- (void)loadOrders:(BOOL)showLoadingIndicator highlightOrder:(NSNumber *)orderId {
    if (!isLoadingOrders) {
        currentOrder = nil;
        isLoadingOrders = YES;
        self.orderDetailView.hidden = YES;
        MBProgressHUD *hud;
        if (showLoadingIndicator) {  //if load orders is triggered because view is appearing, then the loading hud is shown. if it is triggered because of the pull action in orders list, there already will be a loading indicator so don't show the hud.
            hud = [MBProgressHUD showHUDAddedTo:self.sideTable animated:YES];
            hud.removeFromSuperViewOnHide = YES;
            hud.labelText = @"Getting orders";
            [hud show:NO];
        }
        void (^cleanup)(void) = ^{
            if (![hud isHidden]) [hud hide:NO];
            [pull finishedLoading];
            isLoadingOrders = NO;
        };

        [[CinchJSONAPIClient sharedInstance] GET:kDBORDER parameters:@{ kAuthToken: self.authToken } success:^(NSURLSessionDataTask *task, id JSON) {
            persistentOrders = [[NSMutableArray alloc] init];
            for (NSDictionary *order in JSON) {
                [persistentOrders addObject:[[AnOrder alloc] initWithJSONFromServer:order]];
            }
            partialOrders = [self loadPartialOrders];
            self.allorders = [partialOrders mutableCopy];
            [self.allorders addObjectsFromArray:persistentOrders];
            self.filteredOrders = [self.allorders mutableCopy];
            [self.sideTable reloadData];
            self.NoOrdersLabel.hidden = [self.filteredOrders count] > 0;
            cleanup();
            [self highlightOrder:orderId];
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            [[[UIAlertView alloc] initWithTitle:@"Error!" message:[NSString stringWithFormat:@"There was an error loading orders:%@", [error localizedDescription]] delegate:nil
                              cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            cleanup();
        }];
    }
}

- (void)highlightOrder:(NSNumber *)orderId {
    if (orderId != nil && [orderId intValue] != 0) {
        NSIndexPath *currentOrderIndex;
        AnOrder *orderAtCurrentOrderIndex;
        int i = 0;
        for (AnOrder *order in self.filteredOrders) {
            if ([orderId isEqualToNumber:order.orderId]) {
                currentOrderIndex = [NSIndexPath indexPathForRow:i inSection:0];
                orderAtCurrentOrderIndex = order;
                break;
            }
            i++;
        }
        if (currentOrderIndex != nil) {
            if ([orderAtCurrentOrderIndex.status isEqualToString:@"complete"]) {
                [self.sideTable selectRowAtIndexPath:currentOrderIndex animated:YES scrollPosition:UITableViewScrollPositionBottom];
                [self didSelectOrderAtIndexPath:currentOrderIndex];
            } else {
                currentOrder = orderAtCurrentOrderIndex;
                self.orderDetailView.hidden = YES;
            }
        } else {
            currentOrder = nil;
            self.orderDetailView.hidden = YES;
        }
    } else {
        NSLog(@"asdsada");
        if (self.filteredOrders && self.filteredOrders.count) {
            NSLog(@"aaaaaaaaaa");
            NSIndexPath *path = [NSIndexPath indexPathForRow:0 inSection:0];
            [self.sideTable selectRowAtIndexPath:path animated:NO scrollPosition:UITableViewScrollPositionNone];
            currentOrder = self.filteredOrders[0];
            [self displayOrderDetail:currentOrder];
        }
    }
}

/*
SG: Loads partial orders from Core Data.
Partial orders get created when the app crashes while the user was in the middle of creating a new order. This order is not present on the server.
This method reads values for each order in core data are and creates an NSDictionary object conforming to the format of the orders in self.orders.
These partial orders then are put at the beginning of the self.orders array.
*/
- (NSMutableArray *)loadPartialOrders {
    NSArray *partialCoreDataOrders = [[CoreDataUtil sharedManager] fetchObjects:@"Order" sortField:@"created_at"];
    NSMutableArray *orders = [[NSMutableArray alloc] init];
    for (Order *order in partialCoreDataOrders) {
        int orderId = [order.orderId intValue];
        if (orderId == 0 && [order.vendorGroup isEqualToString:[[self.vendorInfo objectForKey:kID] stringValue]]) {  //this is a partial order (orderId eq 0). Make sure the order is for logged in vendor. If vendors switch ipads we do not want to show them each other's orders.
            AnOrder *anOrder = [[AnOrder alloc] initWithCoreData:order];
            [orders addObject:anOrder];
        }
    }
    return orders;
}

#pragma mark - Order detail display

- (IBAction)orderDetailSaveButtonTapped:(id)sender {
    [self saveOrder];
}

- (IBAction)orderDetailEditButtonTapped:(id)sender {
    [self getCustomerOfCurrentOrderAndLoadProductView];
}

- (IBAction)orderDetailDeleteButtonTapped:(id)sender {
    [self Delete:nil];
}

/*
SG: The argument 'detail' is the selected order.
*/
- (void)displayOrderDetail:(AnOrder *)detail {
    ShowConfigurations *config = [ShowConfigurations instance];
    
    self.orderDetailView.hidden = NO;

    self.orderDetailOrderNumberLabel.text = [NSString stringWithFormat:@"Order #%@", detail.orderId];
    self.orderDetailCustomerLabel.text = ([detail.customer objectForKey:kBillName] == nil? @"(Unknown)" : [detail.customer objectForKey:kBillName]);

    if (detail.authorized && detail.authorized.length) {
        self.orderDetailAuthorizedView.hidden = NO;
        self.orderDetailAuthorizedLabel.text = detail.authorized;
        self.orderDetailCustomerView.frame = CGRectMake(0, 44, 331, 96);
    } else {
        self.orderDetailAuthorizedView.hidden = YES;
        self.orderDetailCustomerView.frame = CGRectMake(0, 44, 670, 96);
    }

    if (detail.paymentTerms && detail.paymentTerms.length) {
        self.orderDetailPaymentTermsLabel.text = detail.paymentTerms;
    } else {
        self.orderDetailPaymentTermsLabel.text = @"-";
    }

    float orderDetailTableOriginY = self.orderDetailCustomerView.frame.origin.y + self.orderDetailCustomerView.frame.size.height + 8;
    if (config.enableOrderNotes) {
        self.orderDetailNotesLabel.text = detail.notes;
        self.orderDetailNotesView.hidden = NO;
        orderDetailTableOriginY += self.orderDetailNotesView.frame.size.height + 8;
    } else {
        self.orderDetailNotesView.hidden = YES;
    }

    if (config.paymentTerms) {
        self.orderDetailPaymentTermsView.hidden = NO;
        orderDetailTableOriginY += self.orderDetailPaymentTermsView.frame.size.height + 8;
    } else {
        self.orderDetailPaymentTermsView.hidden = YES;
    }

    self.orderDetailTableParentView.frame = CGRectMake(0, orderDetailTableOriginY, self.orderDetailTableParentView.frame.size.width, 630 - orderDetailTableOriginY);

    self.subtotalLines = [NSMutableArray array];

    CoreDataUtil *coreDataUtil = [CoreDataUtil sharedManager];
    NSMutableDictionary *dateProducts = [NSMutableDictionary dictionary];
    NSMutableArray *orderedDates = [NSMutableArray array];

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];

    [dateFormatter setLocale:enUSPOSIXLocale];
    [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'.000Z'"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];

    NSDate *earliestDate = nil;

    for (ALineItem *line in detail.lineItems) {
        Product *product = (Product *) [coreDataUtil fetchObject:@"Product" withPredicate:[NSPredicate predicateWithFormat:@"(productId == %@)", line.productId]];

        NSDictionary *quantities = [NSJSONSerialization JSONObjectWithData:[line.quantity dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
        if ([quantities isKindOfClass:[NSDictionary class]]) {
            for (NSString *d in quantities.allKeys) {
                NSDate *date = [dateFormatter dateFromString:d];
                int quantity = [quantities[d] intValue];

                if (earliestDate == nil) {
                    earliestDate = date;
                } else {
                    earliestDate = [earliestDate earlierDate:date];
                }

                if(quantity) {
                    NSMutableArray *products = [dateProducts objectForKey:date];
                    if (!products) {
                        products = [NSMutableArray array];
                        dateProducts[date] = products;
                        [orderedDates addObject:date];
                    }
                    [products addObject:@[product, @(quantity)]];
                }
            }
        }
    }

    if (showConfig.isOrderShipDatesType) {
//        self.orderDetailShippingLabel.text = @"Ship immediately.";
        if (detail.shipDates.count > 0) {
//            self.orderDetailShippingLabel.text = [Underscore.array(detail.shipDates)
//                    .map(^id(id obj) {
//                        return [DateUtil convertNSDateToApiDate:obj];
//                    }).unwrap componentsJoinedByString:@", "];
        }
    }

    self.customer.text = @"";
    self.authorizer.text = @"";
    self.notes.text = @"";
    currentOrder = nil;
    self.itemsPrice = nil;
    self.itemsQty = nil;
    self.itemsVouchers = nil;
    self.itemsShipDates = nil;
    [self.itemsTable reloadData];
    self.customer.text = [detail getCustomerDisplayName];
    self.authorizer.text = detail.authorized != nil? detail.authorized : @"";
    if (showConfig.cancelOrder) {
        [self.cancelDaysControl setSelectedSegmentIndex:[cancelDaysHelper indexForValue:detail.cancelByDays]];
    }
    if (showConfig.isOrderShipDatesType) {
        self.orderShipDatesTextView.text = @"Ship immediately.";
        if (detail.shipDates.count > 0) {
            self.orderShipDatesTextView.text = [Underscore.array(detail.shipDates)
                    .map(^id(id obj) {
                        return [DateUtil convertNSDateToApiDate:obj];
                    })
                    .unwrap componentsJoinedByString:@", "];

        }
    }
    currentOrder = detail;
    if (detail) {
        NSArray *arr = detail.lineItems;
        self.itemsPrice = [NSMutableArray array];
        self.itemsDiscounts = [NSMutableArray array];
        self.itemsQty = [NSMutableArray array];
        self.itemsVouchers = [NSMutableArray array];
        self.itemsShipDates = [NSMutableArray array];

        [arr enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            ALineItem *dict = (ALineItem *) obj;

            BOOL isDiscount = [dict.category isEqualToString:@"discount"];
            if (!isDiscount && dict.price && ![dict.price isKindOfClass:[NSNull class]]) {
                [self.itemsPrice insertObject:dict.price atIndex:idx];
                [self.itemsDiscounts insertObject:[NSNumber numberWithInt:0] atIndex:idx];
            } else if (isDiscount) {
                [self.itemsPrice insertObject:dict.price atIndex:idx];
                [self.itemsDiscounts insertObject:[NSNumber numberWithInt:1] atIndex:idx];
            }
            else {
                [self.itemsPrice insertObject:@"0.0" atIndex:idx];
                [self.itemsDiscounts insertObject:[NSNumber numberWithInt:0] atIndex:idx];
            }

            if (dict.quantity && ![dict.quantity isKindOfClass:[NSNull class]]) {
                [self.itemsQty insertObject:dict.quantity atIndex:idx];
            }
            else
                [self.itemsQty insertObject:@"0" atIndex:idx];

            if (dict.voucherPrice && ![dict.voucherPrice isKindOfClass:[NSNull class]]) {
                [self.itemsVouchers insertObject:dict.voucherPrice atIndex:idx];
            }
            else
                [self.itemsVouchers insertObject:@"0" atIndex:idx];

            if (dict.shipDates && ![dict.shipDates isKindOfClass:[NSNull class]]) {

                NSArray *raw = dict.shipDates;
                NSMutableArray *dates = [NSMutableArray array];
                NSDateFormatter *df = [DateUtil newApiDateFormatter];
                for (NSString *str in raw) {
                    NSDate *date = [df dateFromString:str];
                    [dates addObject:date];
                }

                NSArray *selectedDates = [[[NSOrderedSet orderedSetWithArray:dates] array] copy];
                [self.itemsShipDates insertObject:selectedDates atIndex:idx];
            }
            else
                [self.itemsShipDates insertObject:[NSArray array] atIndex:idx];
        }];
        [self.itemsTable reloadData];

        if (![detail.notes isKindOfClass:[NSNull class]]) {
            self.notes.text = detail.notes;
        }

        [self.itemsTable reloadData];
        [self UpdateTotal];

        [self.orderDetailTable reloadData];
    }

    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd/MM/yyyy"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];

    [orderedDates sortUsingSelector:@selector(compare:)];

    float grossTotal = 0;
    NSMutableArray *line = nil;
    for (int i = 0; i < orderedDates.count; i++) {
        NSDate *date = (NSDate*)[orderedDates objectAtIndex:i];

        line = [NSMutableArray array];
        [line addObject:[NSString stringWithFormat:@"Shipping on %@", [dateFormatter stringFromDate:date]]];

        float total = 0;
        for (NSArray *pair in dateProducts[date]) {
            Product *product = pair[0];
            int quantity = [pair[1] intValue];

            if (date == earliestDate) {
                total += quantity * [product.showprc intValue];
            } else {
                total += quantity * [product.regprc intValue];
            }
        }
        grossTotal += total;

        NSString *priceString = [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithDouble:total / 100.0] numberStyle:NSNumberFormatterCurrencyStyle];

        [line addObject:priceString];
        [self.subtotalLines addObject:line];
    }

    NSString *s = nil;
    float total = grossTotal / 100.0;

    if (self.totalDiscounts > 0) {
        s = [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithDouble:total] numberStyle:NSNumberFormatterCurrencyStyle];
        [self.subtotalLines addObject:@[@"SUBTOTAL", s]];

        s = [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithDouble:fabsf(self.totalDiscounts)] numberStyle:NSNumberFormatterCurrencyStyle];
        [self.subtotalLines addObject:@[@"DISCOUNT", s]];

        total -= self.totalDiscounts;
    }

    s = [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithDouble:total] numberStyle:NSNumberFormatterCurrencyStyle];
    [self.subtotalLines addObject:@[@"TOTAL", s]];

    [self.orderDetailTable reloadData];
    [self updateOrderActions];
}

- (void)updateOrderActions {
    BOOL orderAccessible = NO;
    if (currentOrder) {
        NSString *orderStatus = [currentOrder.status lowercaseString];
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

    if (orderAccessible && self.unsavedChangesPresent) {
        self.orderDetailSaveButton.userInteractionEnabled = YES;
        self.orderDetailSaveButton.layer.borderColor = [UIColor colorWithRed:0.902 green:0.494 blue:0.129 alpha:1.000].CGColor;
        self.orderDetailSaveButton.backgroundColor = [UIColor colorWithRed:0.922 green:0.647 blue:0.416 alpha:1.000];
    } else {
        self.orderDetailSaveButton.userInteractionEnabled = NO;
        self.orderDetailSaveButton.layer.borderColor = [UIColor colorWithRed:0.922 green:0.800 blue:0.682 alpha:1.000].CGColor;
        self.orderDetailSaveButton.backgroundColor = [UIColor colorWithRed:0.922 green:0.800 blue:0.682 alpha:1.000];
    }
}

#pragma mark - Load Product View Conroller



- (void)loadProductView:(BOOL)newOrder customer:(NSDictionary *)customer {
    CIProductViewController *productViewController = [self initializeCIProductViewController:newOrder customer:customer];

    static CISlidingProductViewController *slidingProductViewController;
    static dispatch_once_t loadSlidingViewControllerOnce;
    dispatch_once(&loadSlidingViewControllerOnce, ^{
        slidingProductViewController = [[CISlidingProductViewController alloc] initWithTopViewController:productViewController];
    });

    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:slidingProductViewController];
    navController.navigationBarHidden = NO;
    [self presentViewController:navController animated:YES completion:nil];
}

- (CIProductViewController *)initializeCIProductViewController:(bool)newOrder customer:(NSDictionary *)customer {
    static CIProductViewController *productViewController;
    static dispatch_once_t loadProductViewControllerOnce;
    dispatch_once(&loadProductViewControllerOnce, ^{
        productViewController = [[CIProductViewController alloc] initWithNibName:@"CIProductViewController" bundle:nil];
    });

    [productViewController reinit];
    productViewController.authToken = self.authToken;
    productViewController.loggedInVendorId = [[self.vendorInfo objectForKey:kID] stringValue];
    productViewController.loggedInVendorGroupId = [[self.vendorInfo objectForKey:kVendorGroupID] stringValue];
    productViewController.delegate = self;
    productViewController.managedObjectContext = self.managedObjectContext;
    productViewController.newOrder = newOrder;
    productViewController.customer = customer;

    if (!newOrder) {
        productViewController.orderId = (NSInteger) currentOrder.orderId;
        productViewController.selectedOrder = currentOrder;
    }
    if ([ShowConfigurations instance].printing) {
        productViewController.availablePrinters = [availablePrinters copy];
        if (![currentPrinter isEmpty])
            productViewController.selectedPrintStationId = [[[availablePrinters objectForKey:currentPrinter] objectForKey:@"id"] intValue];
    }
    [productViewController setTitle:@"Select Products"];
    return productViewController;
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
        int rows = currentOrder && currentOrder.lineItems ? currentOrder.lineItems.count : 0;
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
        int rows = currentOrder && currentOrder.lineItems ? currentOrder.lineItems.count : 0;
        if (rows) {
            rows += 1 + self.subtotalLines.count;
        }
        return rows;
    }

    if (tableView == self.sideTable) {
        return self.filteredOrders ? self.filteredOrders.count : 0;
    }

    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.orderDetailTable) {
        int rows = currentOrder && currentOrder.lineItems ? currentOrder.lineItems.count : 0;

        if (indexPath.row >= rows) {
            static NSString *odcId = @"stlId";

            int index = indexPath.row - rows - 1;

            UILabel *cleftLabel = nil;
            UILabel *crightLabel = nil;

            UITableViewCell *cell = [self.orderDetailTable dequeueReusableCellWithIdentifier:odcId];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:odcId];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;

                cleftLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, 500, 44)];
                cleftLabel.tag = 1001;
                cleftLabel.backgroundColor = [UIColor clearColor];
                cleftLabel.font = [UIFont regularFontOfSize:14];
                cleftLabel.textColor = [UIColor colorWithWhite:0.3 alpha:1.0];
                cleftLabel.numberOfLines = 0;
                cleftLabel.textAlignment = NSTextAlignmentRight;
                [cell.contentView addSubview:cleftLabel];

                crightLabel = [[UILabel alloc] initWithFrame:CGRectMake(582, 5, 80, 40)];
                crightLabel.tag = 1002;
                crightLabel.backgroundColor = [UIColor clearColor];
                crightLabel.font = [UIFont semiboldFontOfSize:14];
                crightLabel.textColor = [UIColor colorWithWhite:0.3 alpha:1.0];
                crightLabel.numberOfLines = 0;
                crightLabel.textAlignment = NSTextAlignmentLeft;
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

                citemLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 5, 112, 40)];
                citemLabel.tag = 1001;
                citemLabel.backgroundColor = [UIColor clearColor];
                citemLabel.font = [UIFont regularFontOfSize:14];
                citemLabel.textColor = [UIColor colorWithWhite:0.3 alpha:1.0];
                citemLabel.numberOfLines = 0;
                citemLabel.textAlignment = NSTextAlignmentLeft;
                [cell.contentView addSubview:citemLabel];

                cdescriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(135, 5, 197, 40)];
                cdescriptionLabel.tag = 1002;
                cdescriptionLabel.backgroundColor = [UIColor clearColor];
                cdescriptionLabel.font = [UIFont regularFontOfSize:14];
                cdescriptionLabel.textColor = [UIColor colorWithWhite:0.3 alpha:1.0];
                cdescriptionLabel.numberOfLines = 0;
                cdescriptionLabel.textAlignment = NSTextAlignmentLeft;
                [cell.contentView addSubview:cdescriptionLabel];

                csdLabel = [[UILabel alloc] initWithFrame:CGRectMake(340, 5, 64, 40)];
                csdLabel.tag = 1003;
                csdLabel.backgroundColor = [UIColor clearColor];
                csdLabel.font = [UIFont regularFontOfSize:14];
                csdLabel.textColor = [UIColor colorWithWhite:0.3 alpha:1.0];
                csdLabel.numberOfLines = 0;
                csdLabel.textAlignment = NSTextAlignmentLeft;
                [cell.contentView addSubview:csdLabel];

                csqLabel = [[UILabel alloc] initWithFrame:CGRectMake(412, 5, 67, 40)];
                csqLabel.tag = 1004;
                csqLabel.backgroundColor = [UIColor clearColor];
                csqLabel.font = [UIFont regularFontOfSize:14];
                csqLabel.textColor = [UIColor colorWithWhite:0.3 alpha:1.0];
                csqLabel.numberOfLines = 0;
                csqLabel.textAlignment = NSTextAlignmentLeft;
                [cell.contentView addSubview:csqLabel];

                cpriceLabel = [[UILabel alloc] initWithFrame:CGRectMake(487, 5, 89, 40)];
                cpriceLabel.tag = 1005;
                cpriceLabel.backgroundColor = [UIColor clearColor];
                cpriceLabel.font = [UIFont regularFontOfSize:14];
                cpriceLabel.textColor = [UIColor colorWithWhite:0.3 alpha:1.0];
                cpriceLabel.numberOfLines = 0;
                cpriceLabel.textAlignment = NSTextAlignmentLeft;
                [cell.contentView addSubview:cpriceLabel];

                ctotalLabel = [[UILabel alloc] initWithFrame:CGRectMake(582, 5, 80, 40)];
                ctotalLabel.tag = 1006;
                ctotalLabel.backgroundColor = [UIColor clearColor];
                ctotalLabel.font = [UIFont semiboldFontOfSize:14];
                ctotalLabel.textColor = [UIColor colorWithWhite:0.3 alpha:1.0];
                ctotalLabel.numberOfLines = 0;
                ctotalLabel.textAlignment = NSTextAlignmentLeft;
                [cell.contentView addSubview:ctotalLabel];
            } else {
                citemLabel = (UILabel*)[cell.contentView viewWithTag:1001];
                cdescriptionLabel = (UILabel*)[cell.contentView viewWithTag:1002];
                csdLabel = (UILabel*)[cell.contentView viewWithTag:1003];
                csqLabel = (UILabel*)[cell.contentView viewWithTag:1004];
                cpriceLabel = (UILabel*)[cell.contentView viewWithTag:1005];
                ctotalLabel = (UILabel*)[cell.contentView viewWithTag:1006];
            }

            ALineItem *lineItem = currentOrder.lineItems[indexPath.row];
            citemLabel.text = [NSString stringWithFormat:@"#%@", lineItem.itemId];
            cdescriptionLabel.text = [NSString stringWithFormat:@"%@", lineItem.desc];
            csdLabel.text = @"";//[NSString stringWithFormat:@"%d", lineItem.shipDates.count];
            csqLabel.text = [NSString stringWithFormat:@"%d", [lineItem totalQuantity]];
            cpriceLabel.text = [NSString stringWithFormat:@"$%@", lineItem.price];
            ctotalLabel.text = [NSString stringWithFormat:@"$%.02f", lineItem.totalQuantity * [lineItem.price floatValue]];
            
            return cell;
        }
    }

    if (tableView == self.sideTable) {
        static NSString *CellIdentifier = @"CIOrderCell";

        CIOrderCell *cell = [self.sideTable dequeueReusableCellWithIdentifier:CellIdentifier];

        if (cell == nil) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"CIOrderCell" owner:nil options:nil];
            cell = [topLevelObjects objectAtIndex:0];
        }

        AnOrder *data = [self.filteredOrders objectAtIndex:(NSUInteger) [indexPath row]];

        NSString *billName = [data.customer objectForKey:kBillName];
        cell.Customer.text = billName == nil ? @"(Unknown)" : billName;

        if (data.authorized != nil) {
            cell.auth.text = data.authorized;
        }
        else {
            cell.Customer.center = CGPointMake(cell.Customer.center.x, cell.contentView.center.y);
            cell.auth.text = @"";
        }

        cell.numItems.text = [NSString stringWithFormat:@"%d Items", data.lineItems.count];

        if (data.total != nil) {
            cell.total.text = [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithDouble:[data adjustedTotal]] numberStyle:NSNumberFormatterCurrencyStyle];
        }
        else
            cell.total.text = @"$?";
        if (data.voucherTotal != nil) {
            cell.vouchers.text = [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithDouble:[data.voucherTotal doubleValue]] numberStyle:NSNumberFormatterCurrencyStyle];
        }
        else
            cell.vouchers.text = @"$?";

        if (data.lineItems.count > 0) {
            cell.tag = [((ALineItem *) [data.lineItems objectAtIndex:0]).orderId intValue];
        }
        else
            cell.tag = [data.orderId intValue];

        cell.orderStatus.textColor = [UIColor whiteColor];
        cell.orderStatus.font = [UIFont semiboldFontOfSize:12.0];
        if (data.status != nil) {
            cell.orderStatus.text = [data.status capitalizedString];
            NSString *orderStatus = [cell.orderStatus.text lowercaseString];

            if ([orderStatus isEqualToString:@"partial"] || [orderStatus isEqualToString:@"pending"]) {
                cell.orderStatus.backgroundColor = [ThemeUtil darkBlueColor];
            } else if ([orderStatus isEqualToString:@"locked"]) {
                cell.orderStatus.backgroundColor = [ThemeUtil orangeColor];
            } else if ([orderStatus rangeOfString:@"complete"].length > 0 || [orderStatus rangeOfString:@"submit"].length > 0) {
                cell.orderStatus.backgroundColor = [ThemeUtil greenColor];
            }
        } else {
            cell.orderStatus.text = @"Unknown";
            cell.orderStatus.backgroundColor = [UIColor colorWithRed:0.749 green:0.239 blue:0.173 alpha:1];
        }

        cell.orderStatus.attributedText = [[NSAttributedString alloc] initWithString:cell.orderStatus.text attributes: @{ NSKernAttributeName : @(-0.5f) }];
        cell.orderStatus.layer.cornerRadius = 3.0f;

        if (data.orderId != nil)
            cell.orderId.text = [data.orderId stringValue];
        else
            cell.orderId.text = @"";

        if (![ShowConfigurations instance].vouchers) {
            cell.vouchersLabel.hidden = YES;
            cell.vouchers.hidden = YES;
        }

        UIView *bgColorView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
        bgColorView.backgroundColor = [UIColor colorWithRed:0.235 green:0.247 blue:0.251 alpha:1];

        UIView *bar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 50)];
        bar.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        bar.backgroundColor = [ThemeUtil orangeColor];
        [bgColorView addSubview:bar];

        [cell setSelectedBackgroundView:bgColorView];

        return cell;
    }
    else {

        static NSString *cellIdentifier = @"CIItemEditCell";

        CIItemEditCell *cell = [self.itemsTable dequeueReusableCellWithIdentifier:cellIdentifier];

        if (cell == nil) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"CIItemEditCell" owner:nil options:nil];
            cell = [topLevelObjects objectAtIndex:0];
        }

        cell.delegate = self;
        if ([ShowConfigurations instance].vouchers) {
            cell.total.hidden = YES;
        }
        ALineItem *data = [currentOrder.lineItems objectAtIndex:(NSUInteger) [indexPath row]];
        [cell showLineItem:data withTag:indexPath.row];
        return cell;
    }
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSIndexPath *indexPathToReturn = indexPath;
    if (tableView == self.orderDetailTable) return indexPath;

    if (tableView == self.sideTable) {
        if (currentOrder != nil && currentOrder != [self.filteredOrders objectAtIndex:(NSUInteger) indexPath.row] && self.unsavedChangesPresent) {
            indexPathToReturn = nil;
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Exit Without Saving?" message:@"Do you want to exit without saving your changes?"
                                                               delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
            [UIAlertViewDelegateWithBlock showAlertView:alertView withCallBack:^(NSInteger buttonIndex) {
                if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Yes"]) {
                    [self.sideTable selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionBottom];
                    [self didSelectOrderAtIndexPath:indexPath];
                }
            }];
        }
    }
    return indexPathToReturn;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.orderDetailTable) return;

    if (tableView == self.sideTable) {
//        if (currentOrder != [self.filteredOrders objectAtIndex:(NSUInteger) indexPath.row]) {
        [self didSelectOrderAtIndexPath:indexPath];
//        }
    }
    else if (tableView == self.itemsTable) {
        selectedItemRowIndexPath = indexPath;
    }
}

- (void)didSelectOrderAtIndexPath:(NSIndexPath *)indexPath {
    self.unsavedChangesPresent = NO;
    currentOrder = [self.filteredOrders objectAtIndex:(NSUInteger) indexPath.row];
    NSString *status = [currentOrder.status lowercaseString];
    //SG: if this is a completed order, display the order details in the editor view
    //which appears to the right of the sideTable.
//    if (![status isEqualToString:kPartialOrder] && ![status isEqualToString:@"pending"]) {
        [self displayOrderDetail:[self.filteredOrders objectAtIndex:(NSUInteger) indexPath.row]];//SG: itemsDB is loaded inside of displayOrderDetail.
//    } else {
//        self.orderDetailView.hidden = YES;
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Confirm" message:@"Do you want to edit this pending order?"
//                                                       delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Edit", nil];
//        [UIAlertViewDelegateWithBlock showAlertView:alert withCallBack:^(NSInteger buttonIndex) {
//            if (buttonIndex == 1) {
//                [self getCustomerOfCurrentOrderAndLoadProductView];
//            } else {
//                NSIndexPath *selection = [self.sideTable indexPathForSelectedRow];
//                if (selection)
//                    [self.sideTable deselectRowAtIndexPath:selection animated:YES];
//            }
//        }];
//    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.sideTable) {
        return UITableViewCellEditingStyleDelete;
    }
    else
        return UITableViewCellEditingStyleNone;
}

/*
SG: This method gets called when you swipe on an order in the order list and tap the delete button that appears.
* */
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.sideTable) {
        if (editingStyle == UITableViewCellEditingStyleDelete) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"DELETE" message:@"Are you sure you want to delete this order?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Delete", nil];
            AnOrder *selectedOrder = [self.filteredOrders objectAtIndex:(NSUInteger) indexPath.row];
            [UIAlertViewDelegateWithBlock showAlertView:alert withCallBack:^(NSInteger buttonIndex) {
                if (buttonIndex == 1) {
                    [self deleteOrder:selectedOrder row:indexPath];
                }
            }];
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.orderDetailTable) {
        return 50;
    }

    if (tableView == self.sideTable)
        return 114;
    else {
        ALineItem *data = [currentOrder.lineItems objectAtIndex:(NSUInteger) [indexPath row]];
        if (data.warnings.count > 0 || data.errors.count > 0)
            return 44 + ((data.warnings.count + data.errors.count) * 42);
        else
            return 44;
    }
}

#pragma mark - CIItemEditDelegate
//SG: CIItemEditDelegate methods are called when the Shipping Date, Quantity, Price or Voucher Price of the line_items in the Editor view are modified by the user.

- (void)UpdateTotal {
    if (currentOrder) {
        double ttotal = 0.0;
        double sctotal = 0.0;
        double discountTotal = 0.0;

        NSNumberFormatter *nf = [[NSNumberFormatter alloc] init];
        [nf setNumberStyle:NSNumberFormatterCurrencyStyle];

        NSInteger itemCount = currentOrder.lineItems.count;

        for (int i = 0; i < itemCount; i++) {
            double price = [[self.itemsPrice objectAtIndex:(NSUInteger) i] doubleValue];
            double qty = 0;

            __autoreleasing NSError *err = nil;
            NSMutableDictionary *dict = [[self.itemsQty objectAtIndex:(NSUInteger) i] objectFromJSONStringWithParseOptions:JKParseOptionNone error:&err];
            if (err)
                qty = [[self.itemsQty objectAtIndex:(NSUInteger) i] doubleValue];
            else if (dict && ![dict isKindOfClass:[NSNull class]]) {
                for (NSString *key in dict.allKeys)
                    qty += [[dict objectForKey:key] doubleValue];
            }

            // SG: I think one is default for numOfShipDates rather than 0, because if an item does not have a ship date, it is because it is a voucher
            // (we don't let users specify ship dates for vouchers). Voucher items need to be counted towards the total once.
            //If we used 0 for numShipDates, sctotal = [[self.itemsVouchers objectAtIndex:i] doubleValue] * qty * numShipDates
            // and ttotal += price * qty * numShipDates will evaluate to 0 which would not be right.
            int numShipDates = 0;
            ShowConfigurations *config = [ShowConfigurations instance];
            if (config.shipDates) {
                if ([config isLineItemShipDatesType]) {
                    numShipDates = ((NSArray *) [self.itemsShipDates objectAtIndex:(NSUInteger) i]).count;
                } else if ([config isOrderShipDatesType]) {
                    numShipDates = currentOrder.shipDates.count;
                }
            }
            if (0 == numShipDates) numShipDates = 1;

            if ([[self.itemsDiscounts objectAtIndex:(NSUInteger) i] intValue] == 0) {
                if (config.isLineItemShipDatesType) {
                    ttotal += price * qty;
                } else {
                    ttotal += price * qty * numShipDates;
                }
            }
            else {
                discountTotal += fabs(price * qty);
            }
            sctotal += [[self.itemsVouchers objectAtIndex:(NSUInteger) i] doubleValue] * qty * numShipDates;
        }

        self.totalGross = ttotal;
        self.totalDiscounts = -discountTotal;
        self.totalFinal = ttotal - discountTotal;
    }
}

- (IBAction)editOrder:(UIButton *)sender {
    [sender setSelected:YES];
    [self getCustomerOfCurrentOrderAndLoadProductView];
    [sender setSelected:NO];
}

- (void)setVoucher:(NSString *)voucher atIndex:(int)idx {
    [self.itemsVouchers removeObjectAtIndex:(NSUInteger) idx];
    [self.itemsVouchers insertObject:voucher atIndex:(NSUInteger) idx];
    self.unsavedChangesPresent = YES;
}

- (void)setPrice:(NSString *)prc atIndex:(int)idx {
    [self.itemsPrice removeObjectAtIndex:(NSUInteger) idx];
    [self.itemsPrice insertObject:prc atIndex:(NSUInteger) idx];
    self.unsavedChangesPresent = YES;
}

- (void)setQuantity:(NSString *)qty atIndex:(int)idx {
    [self.itemsQty removeObjectAtIndex:(NSUInteger) idx];
    [self.itemsQty insertObject:qty atIndex:(NSUInteger) idx];
    self.unsavedChangesPresent = YES;
}

- (void)QtyTouchForIndex:(int)idx {
    
}

- (void)ShipDatesTouchForIndex:(int)idx {
    CICalendarViewController *calView = [[CICalendarViewController alloc] initWithNibName:@"CICalendarViewController" bundle:nil];

    NSDate *startDate;
    NSDate *endDate;

    if (currentOrder.lineItems == nil || currentOrder.lineItems.count == 0) {
        return;
    }
    if ([currentOrder.lineItems objectAtIndex:(NSUInteger) idx] == nil) {
        return;
    }
    ALineItem *lineItem = ((ALineItem *) [currentOrder.lineItems objectAtIndex:(NSUInteger) idx]);
    Product *product = [Product findProduct:lineItem.productId];
    if (product == nil) {
        return;
    }
    if (product.shipdate1 && product.shipdate2) {
        startDate = product.shipdate1;
        endDate = product.shipdate2;
    } else {
        return;
    }

    NSCalendar *currentCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setDay:1];

    NSMutableArray *dateList = [NSMutableArray array];
    [dateList addObject:startDate];
    NSDate *currentDate = startDate;
    // add one the first time through, so that we can use NSOrderedAscending (prevents millisecond infinite loop)
    currentDate = [currentCalendar dateByAddingComponents:comps toDate:currentDate options:0];
    while ([endDate compare:currentDate] != NSOrderedAscending) {
        [dateList addObject:currentDate];
        currentDate = [currentCalendar dateByAddingComponents:comps toDate:currentDate options:0];
    }

    calView.startDate = startDate;
    __weak CICalendarViewController *calViewW = calView;
    calView.cancelTouched = ^{
        [calViewW dismissViewControllerAnimated:YES completion:nil];
        [self.itemsTable reloadData];

    };

    calView.doneTouched = ^(NSArray *dates) {
        [self.itemsShipDates removeObjectAtIndex:(NSUInteger) idx];
        [self.itemsShipDates insertObject:[dates copy] atIndex:(NSUInteger) idx];
        [calViewW dismissViewControllerAnimated:YES completion:nil];

        [self.itemsTable reloadData];
        self.unsavedChangesPresent = YES;
        [self UpdateTotal];
    };

    CICalendarViewController __weak *weakCalView = calView;
    calView.afterLoad = ^{
        NSArray *dates = [self.itemsShipDates objectAtIndex:(NSUInteger) idx];
        weakCalView.calendarView.selectedDates = [dates mutableCopy];
        weakCalView.calendarView.avalibleDates = dateList;
    };

    [self presentViewController:calView animated:YES completion:nil];
}

- (void)setViewMovedUpDouble:(BOOL)movedUp {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.5];
    self.itemsTable.contentOffset = movedUp && selectedItemRowIndexPath ? CGPointMake(0, [self.itemsTable rowHeight] * selectedItemRowIndexPath.row) : CGPointMake(0, 0);
    [UIView commitAnimations];
}

- (void)setActiveField:(UITextField *)textField {
    activeField = textField;
}

- (void)setSelectedRow:(NSUInteger)index {
    selectedItemRowIndexPath = [NSIndexPath indexPathForRow:index inSection:0];
}

#pragma mark - CIProductViewDelegate

- (void)Return:(NSNumber *)orderId order:(AnOrder *)savedOrder updateStatus:(OrderUpdateStatus)updateStatus {
    if (updateStatus == NewOrderCreated) {//new order created
        [persistentOrders insertObject:savedOrder atIndex:0];
        [self reloadSideTable];
        if ([savedOrder.status isEqualToString:@"complete"])
            [self highlightOrder:savedOrder.orderId];
    } else if (updateStatus == PartialOrderCancelled) {//partial order cancelled
        partialOrders = [self loadPartialOrders];
        [self reloadSideTable];
    } else if (updateStatus == PartialOrderSaved) {//partial order saved
        partialOrders = [self loadPartialOrders];
        [persistentOrders insertObject:savedOrder atIndex:0];
        [self reloadSideTable];
        if ([savedOrder.status isEqualToString:@"complete"])
            [self highlightOrder:savedOrder.orderId];
    } else if (updateStatus == PersistentOrderUpdated) {//persistent order updated
        [self persistentOrderUpdated:savedOrder];
    }
}

- (void)persistentOrderUpdated:(AnOrder *)updatedOrder {
    int index = -1;
    for (unsigned int i = 0; i < persistentOrders.count; i++) {
        AnOrder *order = persistentOrders[i];
        if ([order.orderId isEqualToNumber:updatedOrder.orderId]) {
            index = i;
            break;
        }
    }
    if (index != -1) {
        [persistentOrders removeObjectAtIndex:(NSUInteger) index];
        [persistentOrders insertObject:updatedOrder atIndex:(NSUInteger) index];
    }
    [self reloadSideTable];
    if ([updatedOrder.status isEqualToString:@"complete"])
        [self highlightOrder:updatedOrder.orderId];
}

- (void)reloadSideTable {
    self.allorders = [partialOrders mutableCopy];
    [self.allorders addObjectsFromArray:persistentOrders];
    self.filteredOrders = [self.allorders mutableCopy];
    [self.sideTable reloadData];
    self.NoOrdersLabel.hidden = [self.filteredOrders count] > 0;
}
#pragma mark - CIStoreQtyDelegate

- (void)QtyChange:(double)qty forIndex:(int)idx {

    //Not Imlemented
}

#pragma mark - Events

- (void)addNewOrder {
    CICustomerInfoViewController *ci = [[CICustomerInfoViewController alloc] initWithNibName:@"CICustomerInfoViewController" bundle:nil];
    ci.modalPresentationStyle = UIModalPresentationFormSheet;
    ci.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    ci.delegate = self;
    ci.authToken = self.authToken;
    ci.managedObjectContext = self.managedObjectContext;
    [self presentViewController:ci animated:YES completion:nil];
}

- (void)customerSelected:(NSDictionary *)info {
    [self loadProductView:YES customer:info];
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
    if (currentOrder == nil) {
        return;
    }
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    NSArray *data = currentOrder.lineItems;

    for (NSInteger i = 0; i < data.count; i++) {
        ALineItem *lineItem = [data objectAtIndex:(NSUInteger) i];
        if ([lineItem isStandard]) {
            NSString *productID = [lineItem.productId stringValue];

            NSString *qty = [self.itemsQty objectAtIndex:(NSUInteger) i];
            NSString *price = [self.itemsPrice objectAtIndex:(NSUInteger) i];
            NSString *voucher = [self.itemsVouchers objectAtIndex:(NSUInteger) i];

            if (self.itemsQty.count > i) {
                qty = [self.itemsQty objectAtIndex:(NSUInteger) i];
            }

            NSArray *dates = [self.itemsShipDates objectAtIndex:(NSUInteger) i];
            NSMutableArray *strs = [NSMutableArray array];
            NSDateFormatter *df = [DateUtil newApiDateFormatter];
            for (NSDate *date in dates) {
                NSString *str = [df stringFromDate:date];
                [strs addObject:str];
            }
            Product *product = [Product findProduct:lineItem.productId];
            if (!(qty && [qty intValue] > 0)) {
                [[[UIAlertView alloc] initWithTitle:@"Missing Data" message:[NSString stringWithFormat:@"Item %@ has no quantity. Please specify a quantity and then save.", product.invtid] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
                return;
            }
            if (![helper isProductAVoucher:lineItem.productId] && [[ShowConfigurations instance] shipDatesRequired] && strs.count == 0) {
                [[[UIAlertView alloc] initWithTitle:@"Missing Data" message:[NSString stringWithFormat:@"Item %@ has no ship date. Please specify ship date(s) and then save.", product.invtid] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
                return;
            }

            NSString *myId = [lineItem.itemId stringValue];

            NSDictionary *proDict = @{
                    kLineItemProductID : productID,
                    kLineItemId : myId,
                    kLineItemQuantity : qty,
                    kLineItemPRICE : price,
                    kLineItemVoucher : voucher,
                    kLineItemShipDates : strs
            };

            [arr addObject:(id) proDict];
        }
    }

    [arr removeObjectIdenticalTo:nil];
    NSString *custid = [currentOrder.customerId stringValue];
    NSString *authorizedBy = self.authorizer.text == nil? @"" : self.authorizer.text;
    NSString *notesText = self.notes.text == nil || [self.notes.text isKindOfClass:[NSNull class]] ? @"" : self.notes.text;
    NSMutableDictionary *order = [NSMutableDictionary dictionaryWithObjectsAndKeys:custid, kOrderCustomerID, authorizedBy, kAuthorizedBy, notesText, kNotes, arr, kOrderItems, nil];
    if (showConfig.cancelOrder) {
        NSNumber *cancelByDays = [cancelDaysHelper valueAtIndex:[self.cancelDaysControl selectedSegmentIndex]];
        [order setObject:[NilUtil objectOrNSNull:cancelByDays] forKey:kCancelByDays];
    }
    NSDictionary *parameters = @{ kOrder: order, kAuthToken: self.authToken };
    NSString *url = kDBORDEREDITS([currentOrder.orderId intValue]);
    void (^successBlock)(NSURLRequest *, NSHTTPURLResponse *, id) = ^(NSURLRequest *req, NSHTTPURLResponse *response, id JSON) {
        self.unsavedChangesPresent = NO;
        AnOrder *savedOrder = [[AnOrder alloc] initWithJSONFromServer:JSON];
        [self persistentOrderUpdated:savedOrder];
    };
    void (^failureBlock)(NSURLRequest *, NSHTTPURLResponse *, NSError *, id) = ^(NSURLRequest *req, NSHTTPURLResponse *response, NSError *error, id JSON) {
        if (JSON) {
            AnOrder *savedOrder = [[AnOrder alloc] initWithJSONFromServer:JSON];
            [self persistentOrderUpdated:savedOrder];
        }
    };
    [helper sendRequest:@"PUT" url:url parameters:parameters successBlock:successBlock failureBlock:failureBlock view:self.view loadingText:@"Saving order"];
}

- (void)selectPrintStation {
    if ([self.poController isPopoverVisible]) {
        [self.poController dismissPopoverAnimated:YES];
    }
    PrinterSelectionViewController *psvc = [[PrinterSelectionViewController alloc] initWithNibName:@"PrinterSelectionViewController" bundle:nil];
    psvc.title = @"Available Printers";
    NSArray *keys = [[[availablePrinters allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] copy];
    psvc.availablePrinters = [NSArray arrayWithArray:keys];
    psvc.delegate = self;

    CGRect frame = self.printButton.frame;
    frame = CGRectOffset(frame, 0, 0);

    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:psvc];
    self.poController = [[UIPopoverController alloc] initWithContentViewController:nav];
    [self.poController presentPopoverFromRect:frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (void)loadPrinters {
    [[CinchJSONAPIClient sharedInstance] GET:kDBGETPRINTERS parameters:@{ } success:^(NSURLSessionDataTask *task, id JSON) {
        if (JSON && [JSON isKindOfClass:[NSArray class]] && [JSON count] > 0) {
            NSMutableDictionary *printStations = [[NSMutableDictionary alloc] initWithCapacity:[JSON count]];
            for (NSDictionary *printer in JSON) {
                [printStations setObject:printer forKey:[printer objectForKey:@"name"]];
            }

            availablePrinters = [NSDictionary dictionaryWithDictionary:printStations];
            if (![currentPrinter isEmpty] && [self printerIsOnline:currentPrinter]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    @autoreleasepool {
                        [[NSNotificationCenter defaultCenter] postNotificationName:PrintersLoadedNotification object:nil];
                    }
                });
            } else {
                [[NSNotificationCenter defaultCenter] removeObserver:self name:PrintersLoadedNotification object:nil];
                [self selectPrintStation];
            }
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:PrintersLoadedNotification object:nil];
        NSString *msg = [NSString stringWithFormat:@"Unable to load available printers. %@", [error localizedDescription]];
        [[[UIAlertView alloc] initWithTitle:@"No Printers" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
    }];
}

- (void)printOrder {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PrintersLoadedNotification object:nil];
    if (availablePrinters && [availablePrinters count] > 0 && ![currentPrinter isEmpty]) {

        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.removeFromSuperViewOnHide = YES;
        hud.labelText = @"Printing";
        [hud show:NO];

        NSString *orderID = [NSString stringWithFormat:@"%@", currentOrder.orderId];
        NSNumber *printStationId = [NSNumber numberWithInt:[[[availablePrinters objectForKey:currentPrinter] objectForKey:@"id"] intValue]];

        [[CinchJSONAPIClient sharedInstance] POST:kDBREPORTPRINTS parameters:@{ kAuthToken: self.authToken, kReportPrintOrderId: orderID, @"printer_id": printStationId } success:^(NSURLSessionDataTask *task, id JSON) {
            [hud hide:NO];
            NSString *msg = [NSString stringWithFormat:@"Your order has printed successfully to station: %@", printStationId];
            [[[UIAlertView alloc] initWithTitle:@"Success" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            [hud hide:NO];
            NSString *errorMsg = [NSString stringWithFormat:@"There was an error printing the order. %@", error.localizedDescription];
            [[[UIAlertView alloc] initWithTitle:@"Error!" message:errorMsg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        }];
    }
}

- (BOOL)printerIsOnline:(NSString *)printer {
    NSUInteger index = [[availablePrinters allKeys] indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        *stop = [obj isEqualToString:printer] && [[[availablePrinters objectForKey:obj] objectForKey:@"online"] boolValue];
        return *stop;
    }];

    return index != NSNotFound;
}

- (IBAction)Print:(id)sender {
    if (currentOrder && currentOrder.orderId) {

        if (!availablePrinters || ![self printerIsOnline:[[SettingsManager sharedManager] lookupSettingByString:@"printer"]]) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(printOrder) name:PrintersLoadedNotification object:nil];
            [self loadPrinters];
        } else {
            [self printOrder];
        }

    } else {
        [[[UIAlertView alloc] initWithTitle:@"Oops!" message:@"Please select an order to print!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }
}

- (IBAction)Delete:(id)sender {
    NSIndexPath *__indexPath;
    int i = 0;
    for (AnOrder *order in self.filteredOrders) {
        if (order.orderId != nil && order.orderId == currentOrder.orderId) {
            __indexPath = [NSIndexPath indexPathForRow:i inSection:0];
            break;
        }
        i++;
    }
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"DELETE" message:@"Are you sure you want to delete this order?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Delete", nil];
    [UIAlertViewDelegateWithBlock showAlertView:alert withCallBack:^(NSInteger buttonIndex) {
        if (buttonIndex == 1) {
            [self deleteOrder:currentOrder row:__indexPath];
        }
    }];
}

//method to move the view up/down whenever the keyboard is shown/dismissed
- (void)setViewMovedUp:(BOOL)movedUp {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.5]; // if you want to slide up the view

    CGRect rect = self.orderDetailView.frame;
    if (movedUp) {
        // 1. move the view's origin up so that the text field that will be hidden come above the keyboard 
        // 2. increase the size of the view so that the area behind the keyboard is covered up.
        rect.origin.y += kOFFSET_FOR_KEYBOARD;//was -
        //rect.size.height += kOFFSET_FOR_KEYBOARD;
    }
    else {
        // revert back to the normal state.
        rect.origin.y = 0;
    }
//    self.orderDetailView.contentOffset = CGPointMake(0, rect.origin.y);

    [UIView commitAnimations];
}

- (void)keyboardWillShow {
    if (activeField) {
        [self setViewMovedUpDouble:YES];
    }
}

- (void)keyboardDidHide {
    if (activeField) {
        [self setViewMovedUpDouble:NO];
        [self setActiveField:nil];
    } else {
        [self setViewMovedUp:NO];
    }
}

#pragma mark - PullToRefreshViewDelegate

- (void)pullToRefreshViewShouldRefresh:(PullToRefreshView *)view; {
    NSNumber *orderId = currentOrder == nil? nil : currentOrder.orderId;
    [self loadOrders:NO highlightOrder:orderId];
}

#pragma mark - ReachabilityDelegate

- (void)networkLost {
}

- (void)networkRestored {
}


#pragma mark - UIAlertViewDelegate

- (void)getCustomerOfCurrentOrderAndLoadProductView {
    NSNumber *customerId = currentOrder.customerId;
    Customer *customer = [CoreDataManager getCustomer:customerId managedObjectContext:self.managedObjectContext];
    if (customer) {
        [self loadProductView:NO customer:[customer asDictionary]];
    } else {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:NO];
        hud.removeFromSuperViewOnHide = YES;
        hud.labelText = @"Loading customer";
        [hud show:NO];

        [[CinchJSONAPIClient sharedInstance] GET:kDBGETCUSTOMER([customerId stringValue]) parameters:@{ kAuthToken: self.authToken } success:^(NSURLSessionDataTask *task, id JSON) {
            [self loadProductView:NO customer:(NSDictionary *) JSON];
            [hud hide:NO];
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            [hud hide:NO];
            [[[UIAlertView alloc] initWithTitle:@"Error!" message:[NSString stringWithFormat:@"There was an error loading customers%@", [error localizedDescription]] delegate:nil
                              cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            NSLog(@"%@", [error localizedDescription]);
        }];
    }
}

- (void)deleteOrder:(AnOrder *)orderToDelete row:(NSIndexPath *)rowToDelete {
    if (orderToDelete) {
        Order *coreDataOrder = orderToDelete.coreDataOrder;//for partial orders we keep pointer to the core data instance inside the Order. //todo we may want to consider always loading core data instance inside the order instance
        if (coreDataOrder == nil && orderToDelete.orderId != nil && [orderToDelete.orderId intValue] != 0) {//for pending orders it is possible, there will be an entry in core data even though we did not load a copy of it inside the order.
            coreDataOrder = [CoreDataManager getOrder:orderToDelete.orderId managedObjectContext:self.managedObjectContext];
        }
        if (orderToDelete.orderId != nil && [orderToDelete.orderId intValue] != 0) {
            MBProgressHUD *deleteHUD = [MBProgressHUD showHUDAddedTo:self.view animated:NO];
            deleteHUD.removeFromSuperViewOnHide = YES;
            deleteHUD.labelText = @"Deleting order";
            [deleteHUD show:NO];

            [[CinchJSONAPIClient sharedInstance] DELETE:kDBORDEREDITS([orderToDelete.orderId integerValue]) parameters:@{ kAuthToken: self.authToken } success:^(NSURLSessionDataTask *task, id JSON) {
                if (coreDataOrder != nil)[[CoreDataUtil sharedManager] deleteObject:coreDataOrder];
                [self deleteRowFromOrderListAtIndex:rowToDelete];
                if (currentOrder && currentOrder.orderId == orderToDelete.orderId) {
                    self.orderDetailView.hidden = YES;
                    currentOrder = nil;
                }
                [deleteHUD hide:NO];
            } failure:^(NSURLSessionDataTask *task, NSError *error) {
                NSString *errorMsg = [NSString stringWithFormat:@"Error deleting order. %@", error.localizedDescription];
                [[[UIAlertView alloc] initWithTitle:@"Error" message:errorMsg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
                [deleteHUD hide:NO];
            }];
        } else {
            if (coreDataOrder != nil)[[CoreDataUtil sharedManager] deleteObject:coreDataOrder];
            [self deleteRowFromOrderListAtIndex:rowToDelete];
        }
    }
}


- (void)deleteRowFromOrderListAtIndex:(NSIndexPath *)index {
    AnOrder *anOrder = [self.filteredOrders objectAtIndex:(NSUInteger) index.row];
    [self.allorders removeObjectIdenticalTo:anOrder];
    [self.filteredOrders removeObjectAtIndex:(NSUInteger) index.row];
    [partialOrders removeObjectIdenticalTo:anOrder];
    [persistentOrders removeObjectIdenticalTo:anOrder];
    NSArray *indices = [NSArray arrayWithObject:index];
    [self.sideTable deleteRowsAtIndexPaths:indices withRowAnimation:UITableViewRowAnimationAutomatic];
    self.NoOrdersLabel.hidden = [self.filteredOrders count] > 0;
}

#pragma mark - UIPrinterSelectedDelegate

- (void)setSelectedPrinter:(NSString *)printer {
    currentPrinter = printer;
    [[SettingsManager sharedManager] saveSetting:@"printer" value:printer];
    [self.poController dismissPopoverAnimated:YES];
    [self printOrder];
}

- (IBAction)cancelByDaysChanged:(UISegmentedControl *)sender {
    self.unsavedChangesPresent = YES;
}

#pragma mark - UITextFieldDelegate
- (void)textViewDidChange:(UITextView *)sender {
    self.unsavedChangesPresent = YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if ([textField.restorationIdentifier isEqualToString:@"SearchField"]) {
        [self.view endEditing:YES];
    }

    return NO;
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
    [self searchWithString:searchTerm];
}

- (void)searchWithString:(NSString*)s {
    if (self.filteredOrders == nil|| [self.filteredOrders isKindOfClass:[NSNull class]]) {
        return;
    }

    if ([s isEqualToString:@""]) {
        self.filteredOrders = [self.allorders mutableCopy];
    } else {
        NSPredicate *pred = [NSPredicate predicateWithBlock:^BOOL(id obj, NSDictionary *bindings) {
            AnOrder *anOrder = (AnOrder *) obj;
            NSString *storeName = [anOrder.customer objectForKey:kBillName];
            NSString *custId = [anOrder.customer objectForKey:kCustID];
            NSString *authorized = anOrder.authorized;
            if ([authorized isKindOfClass:[NSNull class]])
                authorized = @"";
            NSString *orderId = [anOrder.orderId stringValue];
            NSString *test = [s uppercaseString];
            return [[storeName uppercaseString] contains:test]
                    || [[custId uppercaseString] hasPrefix:test]
                    || [[authorized uppercaseString] hasPrefix:test]
                    || [orderId hasPrefix:test];
        }];

        self.filteredOrders = [[self.allorders filteredArrayUsingPredicate:pred] mutableCopy];
    }
    [self.sideTable reloadData];
}


@end
