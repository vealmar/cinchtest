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
#import "NilUtil.h"
#import "CoreDataManager.h"
#import "UIAlertViewDelegateWithBlock.h"

@interface CIOrderViewController () {
    AnOrder *currentOrder;
    BOOL isLoadingOrders;
    UITextField *activeField;
    PullToRefreshView *pull;
    CIProductViewController *productView;
    NSDictionary *availablePrinters;
    NSString *currentPrinter;
    NSIndexPath *selectedItemRowIndexPath;
    BOOL unsavedChangesPresent;
    __weak IBOutlet UILabel *sdLabel;
    __weak IBOutlet UILabel *sqLabel;
    __weak IBOutlet UILabel *quantityLabel;
}
@end

@implementation CIOrderViewController

#define kEditPartialOrder 12
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
        self.total.hidden = YES;
        self.totalLabel.hidden = YES;
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
    pull = [[PullToRefreshView alloc] initWithScrollView:(UIScrollView *) self.sideTable];
    [pull setDelegate:self];
    [self.sideTable addSubview:pull];
    [self loadOrders:YES highlightOrder:nil];
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
        ((UILabel *) [totalField objectForKey:@"labek"]).frame = CGRectMake(x, 613, widthPerField, 34);
        x = x + widthPerField + marginRightPerField;//2 is the right margin
    }
}

#pragma mark - Data access methods

- (void)loadOrders:(BOOL)showLoadingIndicator highlightOrder:(NSNumber *)orderId {
    if (!isLoadingOrders) {
        currentOrder = nil;
        isLoadingOrders = YES;
        self.OrderDetailScroll.hidden = YES;
        MBProgressHUD *hud;
        if (showLoadingIndicator) {  //if load orders is triggered because view is appearing, then the loading hud is shown. if it is triggered because of the pull action in orders list, there already will be a loading indicator so don't show the hud.
            hud = [MBProgressHUD showHUDAddedTo:self.sideTable animated:YES];
            hud.labelText = @"Getting Orders";
            [hud show:YES];
        }

        void (^cleanup)(void) = ^{
            if (![hud isHidden]) [hud hide:YES];
            [pull finishedLoading];
            isLoadingOrders = NO;
        };

        NSString *url = [NSString stringWithFormat:@"%@?%@=%@", kDBORDER, kAuthToken, self.authToken];
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
        AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                    self.filteredOrders = [[NSMutableArray alloc] init];
                    for (NSDictionary *order in JSON) {
                        [self.filteredOrders addObject:[[AnOrder alloc] initWithJSONFromServer:(NSDictionary *) order]];
                    }
                    [self loadPartialOrders];
                    self.allorders = [self.filteredOrders mutableCopy];
                    [self.sideTable reloadData];
                    self.NoOrdersLabel.hidden = [self.filteredOrders count] > 0;
                    cleanup();
                    [self highlightOrder:orderId];
                } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
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
        int i = 0;
        for (AnOrder *order in self.filteredOrders) {
            if ([order.status isEqualToString:@"complete"] && [orderId isEqualToNumber:order.orderId]) {
                currentOrderIndex = [NSIndexPath indexPathForRow:i inSection:0];
                break;
            }
            i++;
        }
        if (currentOrderIndex != nil) {
            [self.sideTable selectRowAtIndexPath:currentOrderIndex animated:YES scrollPosition:UITableViewScrollPositionBottom];
            [self didSelectOrderAtIndexPath:currentOrderIndex];
        }
    }
}

/*
SG: Loads partial orders from Core Data.
Partial orders get created when the app crashes while the user was in the middle of creating a new order. This order is not present on the server.
This method reads values for each order in core data are and creates an NSDictionary object conforming to the format of the orders in self.orders.
These partial orders then are put at the beginning of the self.orders array.
*/
- (void)loadPartialOrders {
    NSArray *partialOrders = [[CoreDataUtil sharedManager] fetchObjects:@"Order" sortField:@"created_at"];
    for (Order *order in partialOrders) {
        int orderId = order.orderId;
        if (orderId == 0 && [order.vendorGroup isEqualToString:[[self.vendorInfo objectForKey:kID] stringValue]]) {  //this is a partial order (orderId eq 0). Make sure the order is for logged in vendor. If vendors switch ipads we do not want to show them each other's orders.
            AnOrder *anOrder = [[AnOrder alloc] initWithCoreData:order];
            [self.filteredOrders insertObject:anOrder atIndex:0];
        }
    }
}

#pragma mark - Order detail display

/*
SG: The argument 'detail' is the selected order.
*/
- (void)displayOrderDetail:(AnOrder *)detail {
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
            productView.printStationId = [[[availablePrinters objectForKey:currentPrinter] objectForKey:@"id"] intValue];
    }


    [productView setTitle:@"Select Products"];
    if (self.vendorInfo && self.vendorInfo.count > 0) {
        NSString *vendorHidePrice = [self.vendorInfo objectForKey:kVenderHidePrice];
        if (vendorHidePrice != nil) {
            productView.showPrice = ![vendorHidePrice boolValue];
        }
    }
    [self presentViewController:productView animated:NO completion:nil];
}

#pragma mark - UITableView Datasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.sideTable && self.filteredOrders) {
        return [self.filteredOrders count];
    }
    else if (tableView == self.itemsTable && currentOrder) {
        if (currentOrder.lineItems.count) {
            return currentOrder.lineItems.count;
        }
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.sideTable) {
        if (!self.filteredOrders) {
            return nil;
        }

        static NSString *CellIdentifier = @"CIOrderCell";

        CIOrderCell *cell = [self.sideTable dequeueReusableCellWithIdentifier:CellIdentifier];

        if (cell == nil) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"CIOrderCell" owner:nil options:nil];
            cell = [topLevelObjects objectAtIndex:0];
        }

        AnOrder *data = [self.filteredOrders objectAtIndex:[indexPath row]];

        cell.Customer.text = [NSString stringWithFormat:@"%@ - %@", ([data.customer objectForKey:kBillName] == nil? @"(Unknown)" : [data.customer objectForKey:kBillName]), ([data.customer objectForKey:kCustID] == nil? @"(Unknown)" : [data.customer objectForKey:kCustID])];
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
    else if (tableView == self.itemsTable) {
        if (!currentOrder) {
            return nil;
        }

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

        if (currentOrder.lineItems.count > [indexPath row]) {
            ALineItem *data = [currentOrder.lineItems objectAtIndex:[indexPath row]];
            [cell updateCellAtIndexPath:indexPath withLineItem:data quantities:self.itemsQty prices:self.itemsPrice vouchers:self.itemsVouchers shipDates:self.itemsShipDates];
            return cell;
        } else {
            return nil;
        }
    }
    else
        return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"asdfa"];
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
        if (currentOrder != [self.filteredOrders objectAtIndex:(NSUInteger) indexPath.row]) {
            [self didSelectOrderAtIndexPath:indexPath];
        }
    }
    else if (tableView == self.itemsTable) {
        selectedItemRowIndexPath = indexPath;
    }
}

- (void)didSelectOrderAtIndexPath:(NSIndexPath *)indexPath {
    unsavedChangesPresent = NO;
    currentOrder = [self.filteredOrders objectAtIndex:(NSUInteger) indexPath.row];
    NSString *status = [currentOrder.status lowercaseString];
    CIOrderCell *cell = (CIOrderCell *) [self.sideTable cellForRowAtIndexPath:indexPath];
    //SG: if this is a completed order, display the order details in the editor view
    //which appears to the right of the sideTable.
    if (![status isEqualToString:kPartialOrder] && ![status isEqualToString:@"pending"]) {
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
        self.customer.text = cell.Customer.text;
        self.authorizer.text = cell.auth.text;
        [self displayOrderDetail:[self.filteredOrders objectAtIndex:(NSUInteger) indexPath.row]];//SG: itemsDB is loaded inside of displayOrderDetail.
    } else {
        self.OrderDetailScroll.hidden = YES;
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Confirm" message:@"Do you want to edit this pending order?"
                                                       delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Edit", nil];
        [alert setTag:kEditPartialOrder];
        [alert show];
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
            AnOrder *selectedOrder = [self.filteredOrders objectAtIndex:indexPath.row];
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
    else
        return 44;
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
            double price = [[self.itemsPrice objectAtIndex:i] doubleValue];
            double qty = 0;

            __autoreleasing NSError *err = nil;
            NSMutableDictionary *dict = [[self.itemsQty objectAtIndex:i] objectFromJSONStringWithParseOptions:JKParseOptionNone error:&err];
            if (err)
                qty = [[self.itemsQty objectAtIndex:i] doubleValue];
            else if (dict && ![dict isKindOfClass:[NSNull class]]) {
                for (NSString *key in dict.allKeys)
                    qty += [[dict objectForKey:key] doubleValue];
            }

            // SG: I think one is default for numOfShipDates rather than 0, because if an item does not have a ship date, it is because it is a voucher
            // (we don't let users specify ship dates for vouchers). Voucher items need to be counted towards the total once.
            //If we used 0 for numShipDates, sctotal = [[self.itemsVouchers objectAtIndex:i] doubleValue] * qty * numShipDates
            // and ttotal += price * qty * numShipDates will evaluate to 0 which would not be right.
            double numShipDates = 1;
            if (((NSArray *) [self.itemsShipDates objectAtIndex:i]).count > 0)
                numShipDates = ((NSArray *) [self.itemsShipDates objectAtIndex:i]).count;

            if ([[self.itemsDiscounts objectAtIndex:i] intValue] == 0)
                ttotal += price * qty * numShipDates;
            else
                discountTotal += fabs(price * qty);
            sctotal += [[self.itemsVouchers objectAtIndex:i] doubleValue] * qty * numShipDates;
        }

        self.grossTotal.text = [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithDouble:ttotal] numberStyle:NSNumberFormatterCurrencyStyle];  //SG: displayed next to Total label
        self.discountTotal.text = [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithDouble:-discountTotal] numberStyle:NSNumberFormatterCurrencyStyle];
        self.total.text = [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithDouble:ttotal - discountTotal] numberStyle:NSNumberFormatterCurrencyStyle];
        self.voucherTotal.text = [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithDouble:sctotal] numberStyle:NSNumberFormatterCurrencyStyle];//SG: displayed next to Voucher label. This must be the voucher total.
    }
}

- (void)setVoucher:(NSString *)voucher atIndex:(int)idx {
    [self.itemsVouchers removeObjectAtIndex:idx];
    [self.itemsVouchers insertObject:voucher atIndex:idx];
    unsavedChangesPresent = YES;
}

- (void)setPrice:(NSString *)prc atIndex:(int)idx {
    [self.itemsPrice removeObjectAtIndex:idx];
    [self.itemsPrice insertObject:prc atIndex:idx];
    unsavedChangesPresent = YES;
}

- (void)setQuantity:(NSString *)qty atIndex:(int)idx {
    [self.itemsQty removeObjectAtIndex:idx];
    [self.itemsQty insertObject:qty atIndex:idx];
    unsavedChangesPresent = YES;
}

- (void)QtyTouchForIndex:(int)idx {
    if ([self.poController isPopoverVisible]) {
        [self.poController dismissPopoverAnimated:YES];
    } else {
        if (!self.storeQtysPO) {
            self.storeQtysPO = [[CIStoreQtyTableViewController alloc] initWithNibName:@"CIStoreQtyTableViewController" bundle:nil];
        }

        NSMutableDictionary *dict = [[[self.itemsQty objectAtIndex:idx] objectFromJSONString] mutableCopy];
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

    NSDate *startDate = [[NSDate alloc] init];
    NSDate *endDate = [[NSDate alloc] init];

    if (currentOrder.lineItems == nil || currentOrder.lineItems.count == 0) {
        return;
    }
    if ([currentOrder.lineItems objectAtIndex:idx] == nil) {
        return;
    }
    if (((ALineItem *) [currentOrder.lineItems objectAtIndex:idx]).product == nil) {
        return;
    }
    NSString *start = [((ALineItem *) [currentOrder.lineItems objectAtIndex:idx]).product objectForKey:kProductShipDate1];
    NSString *end = [((ALineItem *) [currentOrder.lineItems objectAtIndex:idx]).product objectForKey:kProductShipDate2];

    if (start && end && ![start isKindOfClass:[NSNull class]] && ![end isKindOfClass:[NSNull class]] && start.length > 0 && end.length > 0) {
        startDate = [df dateFromString:start];
        endDate = [df dateFromString:end];
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
        [self.itemsShipDates removeObjectAtIndex:idx];
        [self.itemsShipDates insertObject:[dates copy] atIndex:idx];
        [calViewW dismissViewControllerAnimated:YES completion:nil];

        [self.itemsTable reloadData];
        unsavedChangesPresent = YES;
        [self UpdateTotal];
    };

    CICalendarViewController __weak *weakCalView = calView;
    calView.afterLoad = ^{
        NSArray *dates = [self.itemsShipDates objectAtIndex:idx];
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

- (void)Return:(NSNumber *)orderId {
    [self loadOrders:YES highlightOrder:orderId];
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
    AFHTTPRequestOperation *operation = [client HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {

        clearSettings();
        [self dismissViewControllerAnimated:YES completion:nil];

    }                                                                   failure:^(AFHTTPRequestOperation *operation, NSError *error) {

        [[[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"There was an error logging out please try again! Error:%@",
                                                                                        [error localizedDescription]] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }];

    [operation start];
}

- (IBAction)logout:(id)sender {
    [self logout];
}

- (IBAction)Save:(id)sender {

    if (currentOrder == nil) {
        return;
    }

    NSMutableArray *arr = [[NSMutableArray alloc] init];
    NSArray *data = currentOrder.lineItems;

    for (NSInteger i = 0; i < data.count; i++) {
        ALineItem *lineItem = [data objectAtIndex:i];
        NSString *productID = [lineItem.productId stringValue];

        NSString *qty = [self.itemsQty objectAtIndex:i];
        NSString *price = [self.itemsPrice objectAtIndex:i];
        NSString *voucher = [self.itemsVouchers objectAtIndex:i];

        if (self.itemsQty.count > i) {
            qty = [self.itemsQty objectAtIndex:i];
        }

        NSArray *dates = [self.itemsShipDates objectAtIndex:i];
        NSMutableArray *strs = [NSMutableArray array];
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
        for (NSDate *date in dates) {
            NSString *str = [df stringFromDate:date];
            [strs addObject:str];
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

    [arr removeObjectIdenticalTo:nil];
    NSString *custid = [currentOrder.customerId stringValue];
    NSString *authorizedBy = self.authorizer.text == nil? @"" : self.authorizer.text;
    NSString *notesText = self.notes.text == nil || [self.notes.text isKindOfClass:[NSNull class]] ? @"" : self.notes.text;

    NSDictionary *order = [NSDictionary dictionaryWithObjectsAndKeys:custid, kOrderCustID, authorizedBy, kAuthorizedBy, notesText, kNotes, arr, kOrderItems, nil];
    NSDictionary *final = [NSDictionary dictionaryWithObjectsAndKeys:order, kOrder, nil];
    NSString *url = [NSString stringWithFormat:@"%@?%@=%@", kDBORDEREDITS([currentOrder.orderId intValue]), kAuthToken, self.authToken];

    AFHTTPClient *client = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:url]];
    [client setParameterEncoding:AFJSONParameterEncoding];
    NSMutableURLRequest *request = [client requestWithMethod:@"PUT" path:nil parameters:final];

    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        NSNumber *orderId = JSON != nil? (NSNumber *) [NilUtil nilOrObject:[(NSDictionary *) JSON objectForKey:kID]] : nil;
        unsavedChangesPresent = NO;
        [self loadOrders:YES highlightOrder:orderId];
    }                                                                                   failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSString *errorMsg = [NSString stringWithFormat:@"There was an error submitting the order. %@", error.localizedDescription];
        [[[UIAlertView alloc] initWithTitle:@"Error!" message:errorMsg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }];

    [operation start];
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
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
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

    }                                                                                   failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {

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
        hud.labelText = @"Printing ...";
        [hud show:YES];

        NSString *orderID = [NSString stringWithFormat:@"%@", currentOrder.orderId];
        NSNumber *printStationId = [NSNumber numberWithInt:[[[availablePrinters objectForKey:currentPrinter] objectForKey:@"id"] intValue]];
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:orderID, kReportPrintOrderId, printStationId, @"printer_id", nil];

        AFHTTPClient *client = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:kDBREPORTPRINTS]];
        [client setParameterEncoding:AFJSONParameterEncoding];
        NSMutableURLRequest *request = [client requestWithMethod:@"POST" path:nil parameters:params];

        AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
            [hud hide:YES];
            NSString *msg = [NSString stringWithFormat:@"Your order has printed successfully to station: %@", printStationId];
            [[[UIAlertView alloc] initWithTitle:@"Success" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];

        }                                                                                   failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
            [hud hide:YES];
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
    [self.itemsQty removeObjectAtIndex:idx];
    [self.itemsQty insertObject:JSON atIndex:idx];
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

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView.tag == kEditPartialOrder) {
        if (buttonIndex == 1) {
            [self getCustomerOfCurrentOrderAndLoadProductView];
        } else {
            NSIndexPath *selection = [self.sideTable indexPathForSelectedRow];
            if (selection)
                [self.sideTable deselectRowAtIndexPath:selection animated:YES];
        }
    }
}


- (void)getCustomerOfCurrentOrderAndLoadProductView {
//    AnOrder *currentOrder = [self getCurrentOrder];
    NSString *custId = [currentOrder.customerId stringValue];
    NSString *url = [NSString stringWithFormat:@"%@?%@=%@", kDBGETCUSTOMER(custId), kAuthToken, self.authToken];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                                                        success:^(NSURLRequest *req, NSHTTPURLResponse *response, id JSON) {
                                                                                            [self loadProductView:NO customer:(NSDictionary *) JSON];
                                                                                        }
                                                                                        failure:^(NSURLRequest *req, NSHTTPURLResponse *response, NSError *error, id JSON) {
                                                                                            [[[UIAlertView alloc] initWithTitle:@"Error!" message:[NSString stringWithFormat:@"There was an error loading customers%@", [error localizedDescription]] delegate:nil
                                                                                                              cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                                                                                            DLog(@"%@", [error localizedDescription]);
                                                                                        }];
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperation:operation];
}

- (void)deleteOrder:(AnOrder *)orderToDelete row:(NSIndexPath *)rowToDelete {
    if (orderToDelete) {
        Order *coreDataOrder = orderToDelete.coreDataOrder;//for partial orders we keep pointer to the core data instance inside the Order. //todo we may want to consider always loading core data instance inside the order instance
        if (coreDataOrder == nil && orderToDelete.orderId != nil && [orderToDelete.orderId intValue] != 0) {//for pending orders it is possible, there will be an entry in core data even though we did not load a copy of it inside the order.
            coreDataOrder = [CoreDataManager getOrder:orderToDelete.orderId managedObjectContext:self.managedObjectContext];
        }
        if (orderToDelete.orderId != nil && [orderToDelete.orderId intValue] != 0) {
            MBProgressHUD *deleteHUD = [MBProgressHUD showHUDAddedTo:self.view animated:NO];
            deleteHUD.labelText = @"Deleting Order";
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
    AnOrder *anOrder = [self.filteredOrders objectAtIndex:index.row];
    [self.allorders removeObjectIdenticalTo:anOrder];
    [self.filteredOrders removeObjectAtIndex:index.row];
    NSArray *indices = [NSArray arrayWithObject:index];
    [self.sideTable deleteRowsAtIndexPaths:indices withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - UIPrinterSelectedDelegate

- (void)setSelectedPrinter:(NSString *)printer {
    currentPrinter = printer;
    [[SettingsManager sharedManager] saveSetting:@"printer" value:printer];
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
            NSMutableDictionary *dict = (NSMutableDictionary *) obj;

            NSString *storeName = [[dict objectForKey:@"customer"] objectForKey:kBillName];
            NSString *custId = [[dict objectForKey:@"customer"] objectForKey:kCustID];

            NSString *authorized = [dict objectForKey:@"authorized"];
            if ([authorized isKindOfClass:[NSNull class]])
                authorized = @"";
            NSString *orderId = [[dict objectForKey:kOrderId] stringValue];

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
