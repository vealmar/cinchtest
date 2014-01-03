//
//  CIOrderViewController.m
//  Convention
//
//  Created by Matthew Clark on 12/8/11.
//  Copyright (c) 2011 MotionMobs. All rights reserved.
//

#import "CIOrderViewController.h"
#import "CIOrderCell.h"
#import "config.h"
#import "MBProgressHUD.h"

#import "CICalendarViewController.h"
#import "SettingsManager.h"
#import "StringManipulation.h"
#import "AFHTTPClient.h"
#import "AFJSONRequestOperation.h"
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

@interface CIOrderViewController () {
    AnOrder *currentOrder;
    BOOL isLoadingOrders;
    UITextField *activeField;
    PullToRefreshView *pull;
    CIProductViewController *productView;
    NSDictionary *availablePrinters;
    NSString *currentPrinter;
    NSIndexPath *selectedItemRowIndexPath;
    NSMutableArray *partialOrders;
    NSMutableArray *persistentOrders;
    BOOL unsavedChangesPresent;
    CIProductViewControllerHelper *helper;
    __weak IBOutlet UILabel *sdLabel;
    __weak IBOutlet UILabel *sqLabel;
    __weak IBOutlet UILabel *quantityLabel;
}
@end

@implementation
CIOrderViewController

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    currentOrder = nil;
    isLoadingOrders = NO;
    reachDelegation = [[ReachabilityDelegation alloc] initWithDelegate:self withUrl:kBASEURL];

    self.NoOrdersLabel.font = [UIFont fontWithName:kFontName size:25.f];
    self.customer.font = [UIFont fontWithName:kFontName size:14.f];

    ShowConfigurations *showConfig = [ShowConfigurations instance];
    self.logoImage.image = [showConfig logo];
    if (showConfig.shipDates) {
        quantityLabel.hidden = YES;
    } else {
        sdLabel.hidden = YES;
        sqLabel.hidden = YES;
    }
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
    unsavedChangesPresent = NO;
    [self adjustTotals];
    self.OrderDetailScroll.hidden = YES;
    [self.searchText addTarget:self action:@selector(searchTextUpdated:) forControlEvents:UIControlEventEditingChanged];
    if ([ShowConfigurations instance].printing) currentPrinter = [[SettingsManager sharedManager] lookupSettingByString:@"printer"];
    pull = [[PullToRefreshView alloc] initWithScrollView:self.sideTable];
    [pull setDelegate:self];
    [self.sideTable addSubview:pull];
    [self loadOrders:YES highlightOrder:nil];
    helper = [[CIProductViewControllerHelper alloc] init];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}


- (void)viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow)
                                                 name:UIKeyboardWillShowNotification object:self.view.window];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide)
                                                 name:UIKeyboardDidHideNotification object:self.view.window];

}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidHideNotification object:nil];
    if ([ShowConfigurations instance].printing) [[NSNotificationCenter defaultCenter] removeObserver:self name:kPrintersLoaded object:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return UIInterfaceOrientationIsLandscape(interfaceOrientation); //we only support landscape orientation.
}

- (void)adjustTotals {
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
        self.searchText.text = @"";
        self.OrderDetailScroll.hidden = YES;
        MBProgressHUD *hud;
        if (showLoadingIndicator) {  //if load orders is triggered because view is appearing, then the loading hud is shown. if it is triggered because of the pull action in orders list, there already will be a loading indicator so don't show the hud.
            hud = [MBProgressHUD showHUDAddedTo:self.sideTable animated:YES];
            hud.labelText = @"Getting orders";
            [hud show:NO];
        }
        void (^cleanup)(void) = ^{
            if (![hud isHidden]) [hud hide:NO];
            [pull finishedLoading];
            isLoadingOrders = NO;
        };
        NSString *url = [NSString stringWithFormat:@"%@?%@=%@", kDBORDER, kAuthToken, self.authToken];
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
        AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                                                            success:^(NSURLRequest *req, NSHTTPURLResponse *response, id JSON) {
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
                                                                                            } failure:^(NSURLRequest *req, NSHTTPURLResponse *response, NSError *error, id JSON) {
                    [[[UIAlertView alloc] initWithTitle:@"Error!" message:[NSString stringWithFormat:@"There was an error loading orders:%@", [error localizedDescription]] delegate:nil
                                      cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                    cleanup();
                }];
        [operation start];
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
                self.OrderDetailScroll.hidden = YES;
            }
        } else {
            currentOrder = nil;
            self.OrderDetailScroll.hidden = YES;
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

/*
SG: The argument 'detail' is the selected order.
*/
- (void)displayOrderDetail:(AnOrder *)detail {
    self.OrderDetailScroll.hidden = NO;
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
                NSDateFormatter *df = [[NSDateFormatter alloc] init];
                [df setDateFormat:@"yyyy-MM-dd"];//@"yyyy-MM-dd'T'HH:mm:ss'Z'"
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
    }
}

#pragma mark - Load Product View Conroller

- (void)loadProductView:(BOOL)newOrder customer:(NSDictionary *)customer {
    productView = [[CIProductViewController alloc] initWithNibName:@"CIProductViewController" bundle:nil];
    productView.authToken = self.authToken;
    productView.loggedInVendorId = [[self.vendorInfo objectForKey:kID] stringValue];
    productView.loggedInVendorGroupId = [[self.vendorInfo objectForKey:kVendorGroupID] stringValue];
    productView.delegate = self;
    productView.managedObjectContext = self.managedObjectContext;
    productView.newOrder = newOrder;
    productView.customer = customer;

    if (!newOrder) {
        productView.orderId = (NSInteger) currentOrder.orderId;
        productView.selectedOrder = currentOrder;
    }
    if ([ShowConfigurations instance].printing) {
        productView.availablePrinters = [availablePrinters copy];
        if (![currentPrinter isEmpty])
            productView.selectedPrintStationId = [[[availablePrinters objectForKey:currentPrinter] objectForKey:@"id"] intValue];
    }
    [productView setTitle:@"Select Products"];
    [self presentViewController:productView animated:NO completion:nil];
}

#pragma mark - UITableView Datasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.sideTable) {
        return self.filteredOrders ? self.filteredOrders.count : 0;
    } else {
        return currentOrder && currentOrder.lineItems ? currentOrder.lineItems.count : 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.sideTable) {
        static NSString *CellIdentifier = @"CIOrderCell";

        CIOrderCell *cell = [self.sideTable dequeueReusableCellWithIdentifier:CellIdentifier];

        if (cell == nil) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"CIOrderCell" owner:nil options:nil];
            cell = [topLevelObjects objectAtIndex:0];
        }

        AnOrder *data = [self.filteredOrders objectAtIndex:(NSUInteger) [indexPath row]];

        cell.Customer.text = [data getCustomerDisplayName];
        if (data.authorized != nil) {
            cell.auth.text = data.authorized;
        }
        else
            cell.auth.text = @"";

        cell.numItems.text = [NSString stringWithFormat:@"%d Items", data.lineItems.count];

        if (data.total != nil) {
            cell.total.text = [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithDouble:[data.total doubleValue]] numberStyle:NSNumberFormatterCurrencyStyle];
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

        if (data.status != nil) {
            cell.orderStatus.text = [data.status capitalizedString];
            NSString *orderStatus = [cell.orderStatus.text lowercaseString];
            if ([orderStatus isEqualToString:kPartialOrder] || [orderStatus isEqualToString:@"pending"])
                cell.orderStatus.textColor = [UIColor redColor];
            else
                cell.orderStatus.textColor = [UIColor blackColor];
        } else {
            cell.orderStatus.text = @"Unknown";
            cell.orderStatus.textColor = [UIColor orangeColor];
        }

        if (data.orderId != nil)
            cell.orderId.text = [data.orderId stringValue];
        else
            cell.orderId.text = @"";

        if (![ShowConfigurations instance].vouchers) {
            cell.vouchersLabel.hidden = YES;
            cell.vouchers.hidden = YES;
        }

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
        [cell updateCellAtIndexPath:indexPath withLineItem:data quantities:self.itemsQty prices:self.itemsPrice vouchers:self.itemsVouchers shipDates:self.itemsShipDates];
        return cell;
    }
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSIndexPath *indexPathToReturn = indexPath;
    if (tableView == self.sideTable) {
        if (currentOrder != nil && currentOrder != [self.filteredOrders objectAtIndex:(NSUInteger) indexPath.row] && unsavedChangesPresent) {
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
    unsavedChangesPresent = NO;
    currentOrder = [self.filteredOrders objectAtIndex:(NSUInteger) indexPath.row];
    NSString *status = [currentOrder.status lowercaseString];
    //SG: if this is a completed order, display the order details in the editor view
    //which appears to the right of the sideTable.
    if (![status isEqualToString:kPartialOrder] && ![status isEqualToString:@"pending"]) {
        [self displayOrderDetail:[self.filteredOrders objectAtIndex:(NSUInteger) indexPath.row]];//SG: itemsDB is loaded inside of displayOrderDetail.
    } else {
        self.OrderDetailScroll.hidden = YES;
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Confirm" message:@"Do you want to edit this pending order?"
                                                       delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Edit", nil];
        [UIAlertViewDelegateWithBlock showAlertView:alert withCallBack:^(NSInteger buttonIndex) {
            if (buttonIndex == 1) {
                [self getCustomerOfCurrentOrderAndLoadProductView];
            } else {
                NSIndexPath *selection = [self.sideTable indexPathForSelectedRow];
                if (selection)
                    [self.sideTable deselectRowAtIndexPath:selection animated:YES];
            }
        }];
    }
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
    if (tableView == self.sideTable)
        return 114;
    else {
        ALineItem *data = [currentOrder.lineItems objectAtIndex:(NSUInteger) [indexPath row]];
        if (data.errors.count > 0)
            return 44 + data.errors.count * 42;
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
            double numShipDates = 1;
            if (((NSArray *) [self.itemsShipDates objectAtIndex:(NSUInteger) i]).count > 0)
                numShipDates = ((NSArray *) [self.itemsShipDates objectAtIndex:(NSUInteger) i]).count;

            if ([[self.itemsDiscounts objectAtIndex:(NSUInteger) i] intValue] == 0)
                ttotal += price * qty * numShipDates;
            else
                discountTotal += fabs(price * qty);
            sctotal += [[self.itemsVouchers objectAtIndex:(NSUInteger) i] doubleValue] * qty * numShipDates;
        }

        self.grossTotal.text = [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithDouble:ttotal] numberStyle:NSNumberFormatterCurrencyStyle];  //SG: displayed next to Total label
        self.discountTotal.text = [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithDouble:-discountTotal] numberStyle:NSNumberFormatterCurrencyStyle];
        self.total.text = [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithDouble:ttotal - discountTotal] numberStyle:NSNumberFormatterCurrencyStyle];
        self.voucherTotal.text = [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithDouble:sctotal] numberStyle:NSNumberFormatterCurrencyStyle];//SG: displayed next to Voucher label. This must be the voucher total.
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
    unsavedChangesPresent = YES;
}

- (void)setPrice:(NSString *)prc atIndex:(int)idx {
    [self.itemsPrice removeObjectAtIndex:(NSUInteger) idx];
    [self.itemsPrice insertObject:prc atIndex:(NSUInteger) idx];
    unsavedChangesPresent = YES;
}

- (void)setQuantity:(NSString *)qty atIndex:(int)idx {
    [self.itemsQty removeObjectAtIndex:(NSUInteger) idx];
    [self.itemsQty insertObject:qty atIndex:(NSUInteger) idx];
    unsavedChangesPresent = YES;
}

- (void)QtyTouchForIndex:(int)idx {
    if ([self.poController isPopoverVisible]) {
        [self.poController dismissPopoverAnimated:YES];
    } else {
        if (!self.storeQtysPO) {
            self.storeQtysPO = [[CIStoreQtyTableViewController alloc] initWithNibName:@"CIStoreQtyTableViewController" bundle:nil];
        }

        NSMutableDictionary *dict = [[[self.itemsQty objectAtIndex:(NSUInteger) idx] objectFromJSONString] mutableCopy];
        self.storeQtysPO.stores = dict;
        self.storeQtysPO.tag = idx;
        self.storeQtysPO.delegate = self;
        CGRect frame = [self.itemsTable rectForRowAtIndexPath:[NSIndexPath indexPathForRow:idx inSection:0]];
        frame = CGRectOffset(frame, 0, 0);
        self.poController = [[UIPopoverController alloc] initWithContentViewController:self.storeQtysPO];
        [self.poController presentPopoverFromRect:frame inView:self.itemsTable permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
}

- (void)ShipDatesTouchForIndex:(int)idx {
    CICalendarViewController *calView = [[CICalendarViewController alloc] initWithNibName:@"CICalendarViewController" bundle:nil];
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];

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
        unsavedChangesPresent = YES;
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
    self.searchText.text = @"";
    self.filteredOrders = [self.allorders mutableCopy];
    [self.sideTable reloadData];
    self.NoOrdersLabel.hidden = [self.filteredOrders count] > 0;
}
#pragma mark - CIStoreQtyDelegate

- (void)QtyChange:(double)qty forIndex:(int)idx {

    //Not Imlemented
}

#pragma mark - Events

- (IBAction)AddNewOrder:(id)sender {
    CICustomerInfoViewController *ci = [[CICustomerInfoViewController alloc] initWithNibName:@"CICustomerInfoViewController" bundle:nil];
    ci.modalPresentationStyle = UIModalPresentationFormSheet;
    ci.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    ci.delegate = self;
    ci.authToken = self.authToken;
    ci.managedObjectContext = self.managedObjectContext;
    [self presentViewController:ci animated:NO completion:nil];
}

- (void)customerSelected:(NSDictionary *)info {
    [self loadProductView:YES customer:info];
}

- (void)logout {
    void (^clearSettings)(void) = ^{
        [[SettingsManager sharedManager] saveSetting:@"username" value:@""];
        [[SettingsManager sharedManager] saveSetting:@"password" value:@""];
    };

    NSString *logoutPath;

    if (self.authToken) {
        logoutPath = [NSString stringWithFormat:@"%@?%@=%@", kDBLOGOUT, kAuthToken, self.authToken];
    } else {
        logoutPath = kDBLOGOUT;
    }


    NSURL *url = [NSURL URLWithString:logoutPath];
    AFHTTPClient *client = [[AFHTTPClient alloc] initWithBaseURL:url];
    NSMutableURLRequest *request = [client requestWithMethod:@"DELETE" path:@"" parameters:nil];
    AFHTTPRequestOperation *operation = [client HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *op, id responseObject) {

        clearSettings();
        [self dismissViewControllerAnimated:YES completion:nil];

    }                                                                   failure:^(AFHTTPRequestOperation *op, NSError *error) {

        [[[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"There was an error logging out please try again! Error:%@",
                                                                                        [error localizedDescription]] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }];

    [operation start];
}

- (IBAction)logout:(id)sender {
    [self logout];
}

- (IBAction)Save:(id)sender {
    [sender setSelected:YES];
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
            NSDateFormatter *df = [[NSDateFormatter alloc] init];
            [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
            for (NSDate *date in dates) {
                NSString *str = [df stringFromDate:date];
                [strs addObject:str];
            }
            Product *product = [Product findProduct:lineItem.productId];
            [[ShowConfigurations instance] shipDates] ? strs.count > 0 : YES;
            if (![helper itemHasQuantity:qty]) {
                [[[UIAlertView alloc] initWithTitle:@"Missing Data" message:[NSString stringWithFormat:@"Item %@ has no quantity. Please specify a quantity and then save.", product.invtid] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
                return;
            }
            if (![helper isProductAVoucher:lineItem.productId] && [[ShowConfigurations instance] shipDates] && strs.count == 0) {
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

    NSDictionary *order = [NSDictionary dictionaryWithObjectsAndKeys:custid, kOrderCustomerID, authorizedBy, kAuthorizedBy, notesText, kNotes, arr, kOrderItems, nil];
    NSDictionary *final = [NSDictionary dictionaryWithObjectsAndKeys:order, kOrder, nil];
    NSString *url = [NSString stringWithFormat:@"%@?%@=%@", kDBORDEREDITS([currentOrder.orderId intValue]), kAuthToken, self.authToken];
    void (^successBlock)(NSURLRequest *, NSHTTPURLResponse *, id) = ^(NSURLRequest *req, NSHTTPURLResponse *response, id JSON) {
        unsavedChangesPresent = NO;
        AnOrder *savedOrder = [[AnOrder alloc] initWithJSONFromServer:JSON];
        [self persistentOrderUpdated:savedOrder];
        [sender setSelected:NO];
    };
    void (^failureBlock)(NSURLRequest *, NSHTTPURLResponse *, NSError *, id) = ^(NSURLRequest *req, NSHTTPURLResponse *response, NSError *error, id JSON) {
        if (JSON) {
            AnOrder *savedOrder = [[AnOrder alloc] initWithJSONFromServer:JSON];
            [self persistentOrderUpdated:savedOrder];
            [sender setSelected:NO];
        }
    };
    [helper sendRequest:@"PUT" url:url parameters:final successBlock:successBlock failureBlock:failureBlock view:self.view loadingText:@"Saving order"];
}

- (IBAction)Refresh:(id)sender {
    NSNumber *orderId = currentOrder == nil? nil : currentOrder.orderId;
    [self loadOrders:YES highlightOrder:orderId];
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
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:kDBGETPRINTERS]];
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *req, NSHTTPURLResponse *response, id JSON) {
        if (JSON && [JSON isKindOfClass:[NSArray class]] && [JSON count] > 0) {
            NSMutableDictionary *printStations = [[NSMutableDictionary alloc] initWithCapacity:[JSON count]];
            for (NSDictionary *printer in JSON) {
                [printStations setObject:printer forKey:[printer objectForKey:@"name"]];
            }

            availablePrinters = [NSDictionary dictionaryWithDictionary:printStations];
            if (![currentPrinter isEmpty] && [self printerIsOnline:currentPrinter]) {
                [[NSNotificationCenter defaultCenter] postNotificationName:kPrintersLoaded object:nil];
            } else {
                [[NSNotificationCenter defaultCenter] removeObserver:self name:kPrintersLoaded object:nil];
                [self selectPrintStation];
            }
        }

    }                                                                                   failure:^(NSURLRequest *req, NSHTTPURLResponse *response, NSError *error, id JSON) {

        [[NSNotificationCenter defaultCenter] removeObserver:self name:kPrintersLoaded object:nil];
        NSString *msg = [NSString stringWithFormat:@"Unable to load available printers. %@", [error localizedDescription]];
        [[[UIAlertView alloc] initWithTitle:@"No Printers" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
    }];

    [operation start];
}

- (void)printOrder {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kPrintersLoaded object:nil];
    if (availablePrinters && [availablePrinters count] > 0 && ![currentPrinter isEmpty]) {

        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.labelText = @"Printing";
        [hud show:NO];

        NSString *orderID = [NSString stringWithFormat:@"%@", currentOrder.orderId];
        NSNumber *printStationId = [NSNumber numberWithInt:[[[availablePrinters objectForKey:currentPrinter] objectForKey:@"id"] intValue]];
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:orderID, kReportPrintOrderId, printStationId, @"printer_id", nil];

        AFHTTPClient *client = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:kDBREPORTPRINTS]];
        [client setParameterEncoding:AFJSONParameterEncoding];
        NSMutableURLRequest *request = [client requestWithMethod:@"POST" path:nil parameters:params];

        AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *req, NSHTTPURLResponse *response, id JSON) {
            [hud hide:NO];
            NSString *msg = [NSString stringWithFormat:@"Your order has printed successfully to station: %@", printStationId];
            [[[UIAlertView alloc] initWithTitle:@"Success" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];

        }                                                                                   failure:^(NSURLRequest *req, NSHTTPURLResponse *response, NSError *error, id JSON) {
            [hud hide:NO];
            NSString *errorMsg = [NSString stringWithFormat:@"There was an error printing the order. %@", error.localizedDescription];
            [[[UIAlertView alloc] initWithTitle:@"Error!" message:errorMsg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        }];

        [operation start];
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
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(printOrder) name:kPrintersLoaded object:nil];
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

    CGRect rect = self.OrderDetailScroll.frame;
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
    self.OrderDetailScroll.contentOffset = CGPointMake(0, rect.origin.y);

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

- (void)QtyTableChange:(NSMutableDictionary *)qty forIndex:(int)idx {
    NSString *JSON = [qty JSONString];
    CIItemEditCell *cell = (CIItemEditCell *) [self.itemsTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:idx inSection:1]];
    cell.qty.text = JSON;
    [self.itemsQty removeObjectAtIndex:(NSUInteger) idx];
    [self.itemsQty insertObject:JSON atIndex:(NSUInteger) idx];
    [self.itemsTable reloadData];
    unsavedChangesPresent = YES;
    [self UpdateTotal];
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
        hud.labelText = @"Loading customer";
        [hud show:NO];
        NSString *url = [NSString stringWithFormat:@"%@?%@=%@", kDBGETCUSTOMER([customerId stringValue]), kAuthToken, self.authToken];
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
        AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                                                            success:^(NSURLRequest *req, NSHTTPURLResponse *response, id JSON) {
                                                                                                [self loadProductView:NO customer:(NSDictionary *) JSON];
                                                                                                [hud hide:NO];
                                                                                            }
                                                                                            failure:^(NSURLRequest *req, NSHTTPURLResponse *response, NSError *error, id JSON) {
                                                                                                [hud hide:NO];
                                                                                                [[[UIAlertView alloc] initWithTitle:@"Error!" message:[NSString stringWithFormat:@"There was an error loading customers%@", [error localizedDescription]] delegate:nil
                                                                                                                  cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                                                                                                NSLog(@"%@", [error localizedDescription]);
                                                                                            }];
        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        [queue addOperation:operation];
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
            deleteHUD.labelText = @"Deleting order";
            [deleteHUD show:NO];
            NSURL *url = [NSURL URLWithString:kDBORDEREDITS([orderToDelete.orderId integerValue])];
            AFHTTPClient *client = [[AFHTTPClient alloc] initWithBaseURL:url];
            NSMutableURLRequest *request = [client requestWithMethod:@"DELETE" path:nil parameters:nil];
            AFHTTPRequestOperation *operation = [client HTTPRequestOperationWithRequest:request
                                                                                success:^(AFHTTPRequestOperation *op, id responseObject) {
                                                                                    if (coreDataOrder != nil)[[CoreDataUtil sharedManager] deleteObject:coreDataOrder];
                                                                                    [self deleteRowFromOrderListAtIndex:rowToDelete];
                                                                                    if (currentOrder && currentOrder.orderId == orderToDelete.orderId) {
                                                                                        self.OrderDetailScroll.hidden = YES;
                                                                                        currentOrder = nil;
                                                                                    }
                                                                                    [deleteHUD hide:NO];
                                                                                } failure:^(AFHTTPRequestOperation *op, NSError *error) {
                        NSString *errorMsg = [NSString stringWithFormat:@"Error deleting order. %@", error.localizedDescription];
                        [[[UIAlertView alloc] initWithTitle:@"Error" message:errorMsg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
                        [deleteHUD hide:NO];
                    }];
            [operation start];
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

#pragma mark - Search orders

- (void)searchTextUpdated:(UITextField *)textField {
    [self searchOrders:textField];
}

- (IBAction)searchOrders:(id)sender {
    if (![sender isKindOfClass:[UITextField class]])
        [self.searchText resignFirstResponder];

    if (self.filteredOrders == nil|| [self.filteredOrders isKindOfClass:[NSNull class]]) {
        return;
    }

    if ([self.searchText.text isEqualToString:@""]) {
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
            NSString *test = [self.searchText.text uppercaseString];
            return [[storeName uppercaseString] contains:test]
                    || [[custId uppercaseString] hasPrefix:test]
                    || [[authorized uppercaseString] hasPrefix:test]
                    || [orderId hasPrefix:test];
        }];

        self.filteredOrders = [[self.allorders filteredArrayUsingPredicate:pred] mutableCopy];
    }
    [self.sideTable reloadData];
}

#pragma mark - UITextFieldDelegate
- (void)textViewDidChange:(UITextView *)sender {
    unsavedChangesPresent = YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if ([textField.restorationIdentifier isEqualToString:@"SearchField"]) {
        [self.view endEditing:YES];
    }

    return NO;
}

@end
