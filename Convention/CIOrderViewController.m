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
#import "Cart.h"
#import "ShowConfigurations.h"

@interface CIOrderViewController () {
    int currentOrderID;
    BOOL isLoadingOrders;
    UITextField *activeField;
    PullToRefreshView *pull;
    Order *orderToDelete;//SG: when a partial order in order list is swiped and the subsequently shown delete button is tapped, the handler method will set this property to the order entity from core data.
    NSIndexPath *rowToDelete;//SG: When an order in order list is swiped and the subsequently shown delete button is tapped, the handler method will set this property to the row to delete.
    CIProductViewController *productView;
    NSDictionary *availablePrinters;
    NSString *currentPrinter;
    NSIndexPath *selectedItemRowIndexPath;
    __weak IBOutlet UIImageView *homeBg;
    __weak IBOutlet UILabel *sdLabel;
    __weak IBOutlet UILabel *sqLabel;
    __weak IBOutlet UILabel *itemTotalLabel;
    __weak IBOutlet UILabel *voucherLabel;
    __weak IBOutlet UILabel *quantityLabel;
}
@end

@implementation CIOrderViewController


bool showHud = true;

#define kDeleteCompletedOrder 10
#define kDeletePartialOrder 11
#define kEditPartialOrder 12
#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    currentOrderID = 0;
    isLoadingOrders = NO;
    reachDelegation = [[ReachabilityDelegation alloc] initWithDelegate:self withUrl:kBASEURL];

    ShowConfigurations *showConfig = [ShowConfigurations instance];
    self.logoImage.image = [showConfig logo];
    if(showConfig.shipDates){
        quantityLabel.hidden = YES;
    }else{
        sdLabel.hidden = YES;
        sqLabel.hidden = YES;
    }
    if(showConfig.vouchers){
        self.voucherItemTotalLabel.text = @"VOUCHER";
    }else{
        self.voucherItemTotalLabel.text = @"ITEM TOTAL";
        self.voucherTotal.hidden = YES;
        self.voucherTotalLabel.hidden = YES;
    }
    if (showConfig.discounts){
        self.grossTotalLabel.text = @"Gross Total";
        self.total.hidden = YES;
        self.totalLabel.hidden = YES;
    }else{
        self.grossTotalLabel.text = @"Total";
        self.discountTotal.hidden = YES;
        self.discountTotalLabel.hidden = YES;
        self.totalLabel.hidden = YES;
        self.total.hidden = YES;
    }
    self.printButton.hidden = !showConfig.printing;
    [self adjustTotals];
    self.EditorView.hidden = YES;
    self.toolWithSave.hidden = YES;
    self.orderContainer.hidden = YES;
    self.OrderDetailScroll.hidden = YES;
    self.placeholderContainer.hidden = NO;
    [self.searchText addTarget:self action:@selector(searchTextUpdated:) forControlEvents:UIControlEventEditingChanged];
    if ([ShowConfigurations instance].printing) currentPrinter = [[SettingsManager sharedManager] lookupSettingByString:@"printer"];
    pull = [[PullToRefreshView alloc] initWithScrollView:(UIScrollView *) self.sideTable];
    [pull setDelegate:self];
    [self.sideTable addSubview:pull];
    [self Return];
}

- (void)viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow)
                                                 name:UIKeyboardWillShowNotification object:self.view.window];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide)
                                                 name:UIKeyboardDidHideNotification object:self.view.window];

    self.sideContainer.layer.cornerRadius = 5.f;
    self.sideContainer.layer.masksToBounds = YES;
    self.sideContainer.layer.borderWidth = 1.f;

    self.orderContainer.layer.cornerRadius = 5.f;
    self.orderContainer.layer.masksToBounds = YES;
    self.orderContainer.layer.borderWidth = 1.f;

    self.placeholderContainer.layer.cornerRadius = 5.f;
    self.placeholderContainer.layer.masksToBounds = YES;
    self.placeholderContainer.layer.borderWidth = 1.f;

    self.lblAuthBy.font = [UIFont fontWithName:kFontName size:15.f];
    self.lblCompany.font = [UIFont fontWithName:kFontName size:15.f];
    self.lblItems.font = [UIFont fontWithName:kFontName size:15.f];
    self.lblNotes.font = [UIFont fontWithName:kFontName size:15.f];
    self.NoOrdersLabel.font = [UIFont fontWithName:kFontName size:25.f];
    self.customer.font = [UIFont fontWithName:kFontName size:14.f];
    self.authorizer.font = [UIFont fontWithName:kFontName size:14.f];
    self.itemsAct.hidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidHideNotification object:nil];
    if ([ShowConfigurations instance].printing) [[NSNotificationCenter defaultCenter] removeObserver:self name:kPrintersLoaded object:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return UIInterfaceOrientationIsLandscape(interfaceOrientation); //we only support landscape orientation.
}

- (void) adjustTotals{
    NSMutableArray *visibleTotalFields = [[NSMutableArray alloc] init];
    if(!self.grossTotal.hidden) [visibleTotalFields addObject:@{@"field" : self.grossTotal, @"label": self.grossTotalLabel}];
    if(!self.discountTotal.hidden) [visibleTotalFields addObject:@{@"field" : self.discountTotal, @"label": self.discountTotalLabel}];
    if(!self.voucherTotal.hidden) [visibleTotalFields addObject:@{@"field" : self.voucherTotal, @"label": self.voucherTotalLabel}];
    if(!self.total.hidden) [visibleTotalFields addObject:@{@"field" : self.total, @"label": self.totalLabel}];
    int availableWidth = 400;
    int widthPerField = availableWidth / visibleTotalFields.count;
    int marginRightPerField = 2;
    widthPerField = widthPerField - marginRightPerField;
    int x = 10;
    for(NSDictionary *totalField in visibleTotalFields){
        UITextField *textField = ((UITextField *) [totalField objectForKey:@"field"]);
        textField.text = @"0";
        textField.frame = CGRectMake(x, 587, widthPerField, 34);
        ((UILabel *) [totalField objectForKey:@"labek"]).frame = CGRectMake(x, 613, widthPerField, 34);
        x=x+widthPerField+marginRightPerField;//2 is the right margin
    }
}

#pragma mark - Data access methods

- (void)loadOrders {
    isLoadingOrders = YES;
    self.OrderDetailScroll.hidden = YES;
    MBProgressHUD *hud;
    if (showHud) {
        hud = [MBProgressHUD showHUDAddedTo:self.sideTable animated:YES];
        hud.labelText = @"Getting Orders";
        [hud show:YES];
    }

    void (^cleanup)(void) = ^{
        if (showHud) [hud hide:YES];
        [pull finishedLoading];
        showHud = true;
        isLoadingOrders = NO;
    };

    NSString *url = [NSString stringWithFormat:@"%@?%@=%@", kDBORDER, kAuthToken, self.authToken];//SG: vendor/shows/4/orders.json
    DLog(@"Sending %@", url);
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
            success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                self.orders = [NSMutableArray arrayWithArray:JSON];
                DLog(@"order count: %i", self.orders.count);
                [self loadPartialOrders];
                self.orderData = [self.orders mutableCopy];
                [self.sideTable reloadData];
                self.NoOrdersLabel.hidden = [self.orders count] > 0;
                cleanup();
            } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                [[[UIAlertView alloc] initWithTitle:@"Error!" message:[NSString stringWithFormat:@"There was an error loading orders:%@", [error localizedDescription]] delegate:nil
                                  cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                cleanup();
            }];
    [operation start];
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
        if (orderId == 0) {  //SG: makes sure this is a partial order
            NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObject:@"" forKey:kAuthorizedBy];
            [dict setObject:[NSDate dateWithTimeIntervalSinceReferenceDate:order.created_at] forKey:kVendorCreatedAt];
            [dict setObject:kPartialOrder forKey:kOrderStatus];

            NSMutableDictionary *_customer = [[NSMutableDictionary alloc] init];
            [_customer setObject:order.billname forKey:kBillName];
            [_customer setObject:[NSString stringWithFormat:@"%@", order.custid] forKey:kCustID];
            [_customer setObject:[NSString stringWithFormat:@"%@", order.customer_id] forKey:@"id"];

            [dict setObject:_customer forKey:@"customer"];
            [dict setObject:[NSString stringWithFormat:@"%@", order.customer_id] forKey:kOrderCustID];
            [dict setObject:[NSString stringWithFormat:@"%d", [order.carts count]] forKey:kItemCount];

            // TODO: setup line items
            NSMutableDictionary *lineItems = [[NSMutableDictionary alloc] init];
            [dict setObject:lineItems forKey:kItems];

            double itemTotal = 0.f;
            for (int i = 0; i < order.carts.count; i++) {

                Cart *lineItem = (Cart *) [order.carts objectAtIndex:i];

                __autoreleasing NSError *err = nil;
                NSMutableDictionary *dict = [lineItem.editableQty objectFromJSONStringWithParseOptions:JKParseOptionNone error:&err];

                double itemQty = 0;
                if (err) { //SG: if the item quantity is not a json/hash like string.
                    itemQty = [lineItem.editableQty doubleValue];
                } else { //SG: if item quantity is a json/hash like string i.e. there is more than one quantity for this item. This will happen when the customer has multiple stores.
                    for (NSString *key in dict.allKeys) {
                        itemQty += [[dict objectForKey:key] doubleValue];
                    }
                }

                itemTotal += itemQty * lineItem.editablePrice;
            };

            [dict setObject:[NSNumber numberWithDouble:itemTotal] forKey:kTotal];
            [dict setObject:[NSNumber numberWithInt:0] forKey:kVoucherTotal];

            [self.orders insertObject:dict atIndex:0];
        }
    }
}

#pragma mark - Order detail display

/*
SG: The argument 'detail' is the selected order.
*/
- (void)displayOrderDetail:(NSDictionary *)detail {
    self.itemsDB = [NSDictionary dictionaryWithDictionary:detail];
    if (detail) {
        NSArray *arr = [detail objectForKey:kItems];
        self.itemsPrice = [NSMutableArray array];
        self.itemsDiscounts = [NSMutableArray array];
        self.itemsQty = [NSMutableArray array];
        self.itemsVouchers = [NSMutableArray array];
        self.itemsShipDates = [NSMutableArray array];

        [arr enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSDictionary *dict = (NSDictionary *) obj;

            BOOL isDiscount = [[dict objectForKey:@"category"] isEqualToString:@"discount"];
            if (!isDiscount && [dict objectForKey:@"price"] && ![[dict objectForKey:@"price"] isKindOfClass:[NSNull class]]) {
                [self.itemsPrice insertObject:[dict objectForKey:@"price"] atIndex:idx];
                [self.itemsDiscounts insertObject:[NSNumber numberWithInt:0] atIndex:idx];
                DLog(@"p(%i):%@", idx, [dict objectForKey:@"price"]);
            } else if (isDiscount) {
                [self.itemsPrice insertObject:[dict objectForKey:@"price"] atIndex:idx];
                [self.itemsDiscounts insertObject:[NSNumber numberWithInt:1] atIndex:idx];
            }
            else {
                [self.itemsPrice insertObject:@"0.0" atIndex:idx];
                [self.itemsDiscounts insertObject:[NSNumber numberWithInt:0] atIndex:idx];
            }

            if ([dict objectForKey:@"quantity"] && ![[dict objectForKey:@"quantity"] isKindOfClass:[NSNull class]]) {
                [self.itemsQty insertObject:[dict objectForKey:@"quantity"] atIndex:idx];
                DLog(@"q(%i):%@", idx, [dict objectForKey:@"quantity"]);
            }
            else
                [self.itemsQty insertObject:@"0" atIndex:idx];

            if ([dict objectForKey:kOrderItemVoucher] && ![[dict objectForKey:kOrderItemVoucher] isKindOfClass:[NSNull class]]) {
                [self.itemsVouchers insertObject:[dict objectForKey:kOrderItemVoucher] atIndex:idx];
                //                    DLog(@"%@",[dict objectForKey:kOrderItemVoucher]);
            }
            else
                [self.itemsVouchers insertObject:@"0" atIndex:idx];

            if ([dict objectForKey:kOrderItemShipDates] && ![[dict objectForKey:kOrderItemShipDates] isKindOfClass:[NSNull class]]) {

                NSArray *raw = [dict objectForKey:kOrderItemShipDates];
                NSMutableArray *dates = [NSMutableArray array];
                NSDateFormatter *df = [[NSDateFormatter alloc] init];
                [df setDateFormat:@"yyyy-MM-dd"];//@"yyyy-MM-dd'T'HH:mm:ss'Z'"
                for (NSString *str in raw) {
                    NSDate *date = [df dateFromString:str];
                    //DLog(@"str:%@ date:%@",str, date);
                    [dates addObject:date];
                }

                NSArray *selectedDates = [[[NSOrderedSet orderedSetWithArray:dates] array] copy];
                [self.itemsShipDates insertObject:selectedDates atIndex:idx];
                //                    DLog(@"%@",[dict objectForKey:kOrderItemVoucher]);
            }
            else
                [self.itemsShipDates insertObject:[NSArray array] atIndex:idx];
        }];
        //            DLog(@"items Json:%@",itemsDB);
        [self.itemsTable reloadData];

        NSMutableArray *SDs = [NSMutableArray array];
        [self.itemsShipDates enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSMutableArray *dates = (NSMutableArray *) obj;
            [dates enumerateObjectsUsingBlock:^(id obj1, NSUInteger idx1, BOOL *stop1) {
                NSDate *date = (NSDate *) obj1;
                if (![SDs containsObject:date]) {
                    [SDs addObject:date];    //SG: All the ship dates for all the items in the selected order are added to SDs?
                }
            }];
        }];

        NSString __block *sdtext = @"";
        [SDs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if (idx != 0) {
                sdtext = [sdtext stringByAppendingString:@", "];
            }
            NSDate *date = (NSDate *) obj;
            NSDateFormatter *df = [[NSDateFormatter alloc] init];
            [df setDateFormat:@"MM-dd-yyyy"];//@"yyyy-MM-dd'T'HH:mm:ss'Z'"
            sdtext = [sdtext stringByAppendingString:[df stringFromDate:date]];
        }];

        self.shipdates.text = sdtext; //SG: all the ship dates for all the items in the order? shipDates is the text box displayed next to the Shipping label in the editor view for PW.
        sdtext = nil;

        if (![[self.itemsDB objectForKey:kNotes] isKindOfClass:[NSNull class]]) {  //SG: these are order's notes. itemsDB has all the key-value pairs from the order itself.
            self.notes.text = [self.itemsDB objectForKey:kNotes];
        }

        //[self UpdateTotal];

        [self.itemsTable reloadData];
        [self UpdateTotal];

        self.itemsAct.hidden = YES;
        [self.itemsAct stopAnimating];
    }
}

#pragma mark - Load Product View Conroller

- (void)loadProductView:(BOOL)newOrder {
    productView = [[CIProductViewController alloc] initWithNibName:@"CIProductViewController" bundle:nil];
    productView.authToken = self.authToken;
    productView.vendorGroup = self.vendorGroup; //SG: This is the logged in vendor's id and not their vendorgroup_id.
    productView.vendorGroupId = [[self.vendorInfo objectForKey:kVendorGroupID] stringValue];//SG: This is the logged in vendor's vendorgroup_id.
    productView.delegate = self;
    productView.managedObjectContext = self.managedObjectContext;
    productView.showCustomers = newOrder;//SG: If this is a new order, the customer selection popup needs to be displayed.
    productView.allowPrinting = [ShowConfigurations instance].printing;
    productView.showShipDates = [ShowConfigurations instance].shipDates;
    if ([ShowConfigurations instance].printing) {
        productView.availablePrinters = [availablePrinters copy];
        if (![currentPrinter isEmpty])
            productView.printStationId = [[[availablePrinters objectForKey:currentPrinter] objectForKey:@"id"] intValue];
    }

    if (!newOrder) {
        NSUInteger index = [self.orders indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            int _id = [[obj objectForKey:kOrderId] intValue];
            *stop = _id == currentOrderID;
            return *stop;
        }];
        if (index != NSNotFound) {
            productView.customerId = [[[self.orders objectAtIndex:index] objectForKey:@"customer"] objectForKey:kCustID];
        }
    }
    [productView setTitle:@"Select Products"];//[vendorInfo objectForKey:kName]];
    if (self.vendorInfo && self.vendorInfo.count > 0) {

        //NSString *venderHidePrice = [[vendorInfo objectAtIndex:currentVender] objectForKey:kVenderHidePrice];
        NSString *vendorHidePrice = [self.vendorInfo objectForKey:kVenderHidePrice];
        if (vendorHidePrice != nil) {
            productView.showPrice = ![vendorHidePrice boolValue];
        }
    }

    [self presentViewController:productView animated:NO completion:nil];
}

#pragma mark - UITableView Datasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.sideTable && self.orders) {
        return [self.orders count];
    }
    else if (tableView == self.itemsTable && self.itemsDB) {
        if ([self.itemsDB objectForKey:kItemCount]) {
            return [[self.itemsDB objectForKey:kItemCount] intValue];
        }
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.sideTable) {
        if (!self.orders) {
            return nil;
        }

        static NSString *CellIdentifier = @"CIOrderCell";

        CIOrderCell *cell = [self.sideTable dequeueReusableCellWithIdentifier:CellIdentifier];

        if (cell == nil) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"CIOrderCell" owner:nil options:nil];
            cell = [topLevelObjects objectAtIndex:0];
        }

        NSDictionary *data = [self.orders objectAtIndex:[indexPath row]];
        //DLog(@"data:%@",data);

        cell.Customer.text = [NSString stringWithFormat:@"%@ - %@", ([[data objectForKey:@"customer"] objectForKey:kBillName] == nil? @"(Unknown)" : [[data objectForKey:@"customer"] objectForKey:kBillName]), ([[data objectForKey:@"customer"] objectForKey:kCustID] == nil? @"(Unknown)" : [[data objectForKey:@"customer"] objectForKey:kCustID])];
        if ([data objectForKey:kAuthorizedBy] != nil&& ![[data objectForKey:kAuthorizedBy] isKindOfClass:[NSNull class]]) {
            cell.auth.text = [data objectForKey:kAuthorizedBy];
        }
        else
            cell.auth.text = @"";
        if ([data objectForKey:kItemCount] != nil) {
            cell.numItems.text = [NSString stringWithFormat:@"%d Items", [[data objectForKey:kItemCount] intValue]];
        }
        else
            cell.numItems.text = @"? Items";
        if ([data objectForKey:kTotal] != nil) {
            cell.total.text = [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithDouble:[[data objectForKey:kTotal] doubleValue]] numberStyle:NSNumberFormatterCurrencyStyle];
            //DLog(@"Price:%@",[NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithDouble:[[data objectForKey:kTotal] doubleValue]] numberStyle:NSNumberFormatterCurrencyStyle]);
        }
        else
            cell.total.text = @"$?";
        if ([data objectForKey:kVoucherTotal] != nil) {
            cell.vouchers.text = [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithDouble:[[data objectForKey:kVoucherTotal] doubleValue]] numberStyle:NSNumberFormatterCurrencyStyle];
            //DLog(@"Price:%@",[NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithDouble:[[data objectForKey:kTotal] doubleValue]] numberStyle:NSNumberFormatterCurrencyStyle]);
        }
        else
            cell.vouchers.text = @"$?";

        if ([[data objectForKey:kItems] count] > 0) {
            cell.tag = [[[[data objectForKey:kItems] objectAtIndex:0] objectForKey:@"order_id"] intValue];
        }
        else
            cell.tag = [[data objectForKey:kOrderId] intValue];

        if ([data objectForKey:kOrderStatus] != nil) {
            cell.orderStatus.text = [[data objectForKey:kOrderStatus] capitalizedString];
            NSString *orderStatus = [cell.orderStatus.text lowercaseString];
            if ([orderStatus isEqualToString:kPartialOrder] || [orderStatus isEqualToString:@"pending"])
                cell.orderStatus.textColor = [UIColor redColor];
            else
                cell.orderStatus.textColor = [UIColor blackColor];
        } else {
            cell.orderStatus.text = @"Unknown";
            cell.orderStatus.textColor = [UIColor orangeColor];
        }

        if ([data objectForKey:kOrderId] != nil)
            cell.orderId.text = [[data objectForKey:kOrderId] stringValue];
        else
            cell.orderId.text = @"";

        if (![ShowConfigurations instance].vouchers) {
            cell.vouchersLabel.hidden = YES;
            cell.vouchers.hidden = YES;
        }

        return cell;
    }
    else if (tableView == self.itemsTable) {
        if (!self.itemsDB) {
            return nil;
        }

        static NSString *cellIdentifier = @"CIItemEditCell";

        CIItemEditCell *cell = [self.itemsTable dequeueReusableCellWithIdentifier:cellIdentifier];

        if (cell == nil) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"CIItemEditCell" owner:nil options:nil];
            cell = [topLevelObjects objectAtIndex:0];
        }

        cell.delegate = self;
        if ([ShowConfigurations  instance].vouchers){
         cell.total.hidden = YES;
        }

        if ([[self.itemsDB objectForKey:kItemCount] intValue] > [indexPath row]) {

            NSDictionary *data = [[self.itemsDB objectForKey:kItems] objectAtIndex:[indexPath row]];

            BOOL isDiscount = [[data objectForKey:@"category"] isEqualToString:@"discount"];
            if ([data objectForKey:@"product"]) {
                NSString *invtid = isDiscount?@"Discount":[[data objectForKey:@"product"] objectForKey:@"invtid"];
                cell.invtid.text = invtid;
            }
            [cell setDescription:[data objectForKey:@"desc"] withSubtext:[data objectForKey:@"desc2"]];

            if ([ShowConfigurations  instance].vouchers) {
                if ([self.itemsVouchers objectAtIndex:indexPath.row]) {
                    cell.voucher.text = [self.itemsVouchers objectAtIndex:indexPath.row];
                }
                else
                    cell.voucher.text = @"0";
            } else {
                cell.voucher.hidden = YES;
            }

            BOOL isJSON = NO;
            double q = 0;
            if ([self.itemsQty objectAtIndex:indexPath.row]) {
                cell.qty.text = [self.itemsQty objectAtIndex:indexPath.row];
                cell.qtyLbl.text = [self.itemsQty objectAtIndex:indexPath.row];
                DLog(@"setting qty:(%@)%@", [self.itemsQty objectAtIndex:indexPath.row], cell.qty.text);
                q = [cell.qty.text doubleValue];
            }
            else
                cell.qty.text = @"0";

            __autoreleasing NSError *err = nil;
            NSMutableDictionary *dict = [cell.qty.text objectFromJSONStringWithParseOptions:JKParseOptionNone error:&err];

            if (!err && dict && ![dict isKindOfClass:[NSNull class]] && dict.allKeys.count > 0) {
                DLog(@"Cell JSon got:%@", dict);
                isJSON = YES;
            }

            if (isJSON) {
                [cell.qtyBtn setHidden:NO];
                for (NSString *key in dict.allKeys) {
                    q += [[dict objectForKey:key] doubleValue];
                }
            } else {
                [cell.qtyBtn setHidden:YES];
            }

            if (isDiscount) {
                cell.qty.hidden = YES;
                cell.qtyLbl.hidden = NO;
            } else {
                cell.qty.hidden = NO;
                cell.qtyLbl.hidden = YES;
            }

            int nd = 1;
            if (self.showShipDates) {
                int lblsd = 0;
                if (((NSArray *) [self.itemsShipDates objectAtIndex:indexPath.row]).count > 0) {
                    nd = ((NSArray *) [self.itemsShipDates objectAtIndex:indexPath.row]).count;
                    lblsd = nd;
                }

                DLog(@"Shipdate count:%d nd:%d array:%@", ((NSArray *) [self.itemsShipDates objectAtIndex:indexPath.row]).count, nd, ((NSArray *) [self.itemsShipDates objectAtIndex:indexPath.row]));

                [cell.btnShipdates setTitle:[NSString stringWithFormat:@"SD:%d", lblsd] forState:UIControlStateNormal];
            } else {
                cell.btnShipdates.hidden = YES;
            }

            DLog(@"price:%@", [self.itemsPrice objectAtIndex:indexPath.row]);
            if ([self.itemsPrice objectAtIndex:indexPath.row] && ![[self.itemsPrice objectAtIndex:indexPath.row] isKindOfClass:[NSNull class]]) {
                NSNumberFormatter *nf = [[NSNumberFormatter alloc] init];
                nf.formatterBehavior = NSNumberFormatterBehavior10_4;
                nf.maximumFractionDigits = 2;
                nf.minimumFractionDigits = 2;
                nf.minimumIntegerDigits = 1;

                double price = [[self.itemsPrice objectAtIndex:indexPath.row] doubleValue];

                cell.price.text = [nf stringFromNumber:[NSNumber numberWithDouble:price]];
                cell.priceLbl.text = cell.price.text;
                [cell.price setHidden:YES];
                cell.total.text = [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithDouble:(price * q * nd)] numberStyle:NSNumberFormatterCurrencyStyle];
            }
            else {
                cell.price.text = @"0.00";
                cell.priceLbl.text = cell.price.text;
                [cell.price setHidden:YES];
                cell.total.text = @"$0.00";
            }
            cell.tag = indexPath.row;
            return cell;
        } else {
            return nil;
        }
    }
    else
        return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"asdfa"];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.sideTable) {
        NSDictionary *selectedOrder = [self.orders objectAtIndex:(NSUInteger) indexPath.row];
        NSString *status = [[selectedOrder objectForKey:kOrderStatus] lowercaseString];
        CIOrderCell *cell = (CIOrderCell *) [self.sideTable cellForRowAtIndexPath:indexPath];
        //SG: if this is a completed order, display the order details in the editor view
        //which appears to the right of the sideTable.
        if (![status isEqualToString:kPartialOrder] && ![status isEqualToString:@"pending"]) {
            self.EditorView.hidden = NO;
            self.toolWithSave.hidden = NO;
            self.orderContainer.hidden = NO;
            self.OrderDetailScroll.hidden = NO;

            self.itemsAct.hidden = NO;//SG: activity indicator
            [self.itemsAct startAnimating];

            self.customer.text = @"";
            self.authorizer.text = @"";
            self.notes.text = @"";
            self.itemsDB = nil;
            self.itemsPrice = nil;
            self.itemsQty = nil;
            self.itemsVouchers = nil;
            self.itemsShipDates = nil;
            [self.itemsTable reloadData];

            self.customer.text = cell.Customer.text;
            self.authorizer.text = cell.auth.text;

            self.EditorView.tag = cell.tag;
            currentOrderID = cell.tag;
            rowToDelete = indexPath;

            if (![ShowConfigurations instance].vouchers) {
                self.headerVoucherLbl.hidden = YES;
                self.lblVoucher.hidden = YES;
                self.SCtotal.hidden = YES;
            }

            [self displayOrderDetail:[self.orders objectAtIndex:indexPath.row]];//SG: itemsDB is loaded inside of displayOrderDetail.
        } else {

            self.EditorView.hidden = YES;
            self.toolWithSave.hidden = YES;
            self.orderContainer.hidden = YES;
            self.OrderDetailScroll.hidden = YES;
            currentOrderID = cell.tag;

            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Confirm" message:@"Do you want to edit this pending order?"
                                                           delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Edit", nil];
            [alert setTag:kEditPartialOrder];
            [alert show];
        }
    }
    else if (tableView == self.itemsTable) {
        selectedItemRowIndexPath = indexPath;
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
            NSDictionary *selectedOrder = [self.orders objectAtIndex:indexPath.row];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"DELETE" message:@"Are you sure you want to delete this order?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Delete", nil];
            //SG:If it is a partial order, it must be present in core data (and will not be present at the server.) Partial orders don't have an order id.
            //SG:So the order is fetched using customer id. There is logic that prevents users from creating more than one partial order for the same customer.
            if ([[[selectedOrder objectForKey:kOrderStatus] lowercaseString] isEqualToString:kPartialOrder]) {
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(customer_id = %@) AND (custid = %@)",
                                                                          [selectedOrder objectForKey:@"customer_id"], [[selectedOrder objectForKey:@"customer"] objectForKey:@"custid"]];

                orderToDelete = (Order *) [[CoreDataUtil sharedManager] fetchObject:@"Order" withPredicate:predicate];
                if (orderToDelete) {
                    rowToDelete = indexPath;//SG: I think this should be set irrespective of whether the order is found in core data. Although it should never happen that a partial order is not present in core data.
//                    NSString *msg = [NSString stringWithFormat:@"Are you sure you want to delete the order for customer: %@?", cell.Customer.text];
//                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Pending Order Deletion" message:msg delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Delete", nil];
                    [alert setTag:kDeletePartialOrder];//SG: These tags are used by the alert's handler method to determine if the order is partial. If it is partial it only needs to be deleted from core data.
                    [alert show];
                }//SG: Should add an else with an appropriate alert even though I don't see how it is possible that the else condition will ever happen.
            } else {
                self.itemsDB = [NSDictionary dictionaryWithDictionary:[self.orders objectAtIndex:indexPath.row]];
                rowToDelete = indexPath;
                [alert setTag:kDeleteCompletedOrder];//SG: These tags are used by the alert's handler method to determine if the order is partial. If it is partial it only needs to be deleted from core data. Otherwise it needs to be deleted from the server.
                [alert show];
            }
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.sideTable)
        return 114; // was 101
    else
        return 44;
}

#pragma mark - CIItemEditDelegate
//SG: CIItemEditDelegate methods are called when the Shipping Date, Quantity, Price or Voucher Price of the line_items in the Editor view are modified by the user.

- (void)UpdateTotal {
    if (self.itemsDB) {
        double ttotal = 0.0;
        double sctotal = 0.0;
        double discountTotal = 0.0;

        NSNumberFormatter *nf = [[NSNumberFormatter alloc] init];
        [nf setNumberStyle:NSNumberFormatterCurrencyStyle];

        NSInteger itemCount = [[self.itemsDB objectForKey:kItemCount] intValue];
        DLog(@"itemCount:%i, itemQty:%i", itemCount, [self.itemsQty count]);

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
        self.SCtotal.text = [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithDouble:sctotal] numberStyle:NSNumberFormatterCurrencyStyle];//SG: displayed next to Voucher label. This must be the voucher total.
        self.voucherTotal.text = [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithDouble:sctotal] numberStyle:NSNumberFormatterCurrencyStyle];//SG: displayed next to Voucher label. This must be the voucher total.
    }
}

- (void)setVoucher:(NSString *)voucher atIndex:(int)idx {
    //DLog(@"%@",self.itemsPrice);
    [self.itemsVouchers removeObjectAtIndex:idx];
    [self.itemsVouchers insertObject:voucher atIndex:idx];
}

- (void)setPrice:(NSString *)prc atIndex:(int)idx {
    //DLog(@"%@",self.itemsPrice);
    [self.itemsPrice removeObjectAtIndex:idx];
    [self.itemsPrice insertObject:prc atIndex:idx];
}

- (void)setQuantity:(NSString *)qty atIndex:(int)idx {
    //DLog(@"%@",self.itemsQty);
    [self.itemsQty removeObjectAtIndex:idx];
    [self.itemsQty insertObject:qty atIndex:idx];
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
        DLog(@"pop from frame:%@", NSStringFromCGRect(frame));
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

    if ([self.itemsDB objectForKey:kItems] == nil) {
        DLog(@"no items");
        return;
    }
    if ([[self.itemsDB objectForKey:kItems] objectAtIndex:idx] == nil) {
        DLog(@"not for idx:%d", idx);
        return;
    }
    if ([[[self.itemsDB objectForKey:kItems] objectAtIndex:idx] objectForKey:@"product"] == nil) {
        DLog(@"no product");
        return;
    }
    NSString *start = [[[[self.itemsDB objectForKey:kItems] objectAtIndex:idx] objectForKey:@"product"] objectForKey:kProductShipDate1];
    NSString *end = [[[[self.itemsDB objectForKey:kItems] objectAtIndex:idx] objectForKey:@"product"] objectForKey:kProductShipDate2];

// FIXME: Setup calendar to show starting at current date

    //NSDate *now = [NSDate date];
    if (start && end && ![start isKindOfClass:[NSNull class]] && ![end isKindOfClass:[NSNull class]] && start.length > 0 && end.length > 0) {
        startDate = [df dateFromString:start];
//        if (startDate < now)
//            startDate = now;
        endDate = [df dateFromString:end];
//        if (endDate < startDate)
//            endDate = startDate;
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
        DLog(@"calender canceled");
        [calViewW dismissViewControllerAnimated:YES completion:nil];
        [self.itemsTable reloadData];

    };

    calView.doneTouched = ^(NSArray *dates) {
        [self.itemsShipDates removeObjectAtIndex:idx];
        [self.itemsShipDates insertObject:[dates copy] atIndex:idx];
        [calViewW dismissViewControllerAnimated:YES completion:nil];

        [self.itemsTable reloadData];
        [self UpdateTotal];
    };

    CICalendarViewController __weak *weakCalView = calView;
    calView.afterLoad = ^{
        NSArray *dates = [self.itemsShipDates objectAtIndex:idx];
        weakCalView.calendarView.selectedDates = [dates mutableCopy];
        weakCalView.calendarView.avalibleDates = dateList;
        DLog(@"dates:%@ what it got:%@", dates, weakCalView.calendarView.selectedDates);
    };

    [self presentViewController:calView animated:YES completion:nil];
}

- (void)setViewMovedUpDouble:(BOOL)movedUp {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.5];
    self.itemsTable.contentOffset = movedUp && selectedItemRowIndexPath ?CGPointMake(0, [self.itemsTable rowHeight] * selectedItemRowIndexPath.row):CGPointMake(0,0);
    [UIView commitAnimations];
}

- (void)setActiveField:(UITextField *)textField {
    activeField = textField;
}

-(void) setSelectedRow:(NSUInteger)index{
    selectedItemRowIndexPath = [NSIndexPath indexPathForRow:index inSection:0];
}

#pragma mark - CIProductViewDelegate

- (void)Return {
    if (!isLoadingOrders) {
        self.itemsDB = nil;
        [self loadOrders];
    }
}

#pragma mark - CIStoreQtyDelegate

- (void)QtyChange:(double)qty forIndex:(int)idx {

    //Not Imlemented
}

#pragma mark - Events

- (IBAction)AddNewOrder:(id)sender {
    [self loadProductView:YES];
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
    DLog(@"Signout url:%@", url);

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

    if (currentOrderID == 0) {
        return;
    }

    NSMutableArray *arr = [[NSMutableArray alloc] init];
    NSArray *data = [self.itemsDB objectForKey:kItems];

    for (NSInteger i = 0; i < [[self.itemsDB objectForKey:kItemCount] intValue]; i++) {
        NSString *productID = [[[data objectAtIndex:i] objectForKey:kOrderItemID] stringValue];

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

        NSString *myId = [[[data objectAtIndex:i] objectForKey:kOrderId] stringValue];

        NSDictionary *proDict = @{
                kOrderItemID : productID,
                kOrderId : myId,
                kOrderItemNum : qty,
                kOrderItemPRICE : price,
                kOrderItemVoucher : voucher,
                kOrderItemShipDates : strs
        };

        [arr addObject:(id) proDict];
    }

    [arr removeObjectIdenticalTo:nil];
    DLog(@"array:%@", arr);
    NSString *custid = [self.itemsDB objectForKey:kOrderCustID];
    NSString *authorizedBy = [self.itemsDB objectForKey:kAuthorizedBy];
    NSString *notesText = self.notes.text == nil || [self.notes.text isKindOfClass:[NSNull class]]?@"":self.notes.text;

    NSDictionary *order = [NSDictionary dictionaryWithObjectsAndKeys:custid, kOrderCustID, authorizedBy, kAuthorizedBy, notesText, kNotes, arr, kOrderItems, nil];
    NSDictionary *final = [NSDictionary dictionaryWithObjectsAndKeys:order, kOrder, nil];
    NSString *url = [NSString stringWithFormat:@"%@?%@=%@", kDBORDEREDITS(currentOrderID), kAuthToken, self.authToken];

    AFHTTPClient *client = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:url]];
    [client setParameterEncoding:AFJSONParameterEncoding];
    NSMutableURLRequest *request = [client requestWithMethod:@"PUT" path:nil parameters:final];

    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {

        DLog(@"status = %@", [JSON valueForKey:@"status"]);
        [self Return];

    }                                                                                   failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSString *errorMsg = [NSString stringWithFormat:@"There was an error submitting the order. %@", error.localizedDescription];
        [[[UIAlertView alloc] initWithTitle:@"Error!" message:errorMsg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }];

    [operation start];
}

- (IBAction)Refresh:(id)sender {
    [self Return];
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

        DLog(@"printers: %@", JSON);
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

        NSString *orderID = [NSString stringWithFormat:@"%@", [self.itemsDB objectForKey:kOrderId]];
        NSNumber *printStationId = [NSNumber numberWithInt:[[[availablePrinters objectForKey:currentPrinter] objectForKey:@"id"] intValue]];
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:orderID, kReportPrintOrderId, printStationId, @"printer_id", nil];

        AFHTTPClient *client = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:kDBREPORTPRINTS]];
        [client setParameterEncoding:AFJSONParameterEncoding];
        NSMutableURLRequest *request = [client requestWithMethod:@"POST" path:nil parameters:params];

        AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {

            DLog(@"JSON: %@", JSON);
            DLog(@"status = %@", [JSON valueForKey:@"created_at"]);
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
    if (self.itemsDB && self.itemsDB.allKeys.count > 0 && [self.itemsDB objectForKey:kOrderId]) {

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
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"DELETE" message:@"Are you sure you want to delete this order?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Delete", nil];
    alert.tag = kDeleteCompletedOrder;
    [alert show];
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
    //keyboard will be shown now. depending for which textfield is active, move up or move down the view appropriately

    if (activeField) {
        [self setViewMovedUpDouble:YES];

    } else if ([self.shipdates isFirstResponder] && self.view.frame.origin.y >= 0) {
        [self setViewMovedUp:YES];
    }
    else if (![self.shipdates isFirstResponder] && self.view.frame.origin.y < 0) {
        [self setViewMovedUp:NO];
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
    DLog(@"setting qtys on index(%d) to %@", idx, JSON);

    CIItemEditCell *cell = (CIItemEditCell *) [self.itemsTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:idx inSection:1]];

    cell.qty.text = JSON;

    [self.itemsQty removeObjectAtIndex:idx];
    [self.itemsQty insertObject:JSON atIndex:idx];
    [self.itemsTable reloadData];
    [self UpdateTotal];
}

#pragma mark - PullToRefreshViewDelegate

- (void)pullToRefreshViewShouldRefresh:(PullToRefreshView *)view; {
    //[self performSelectorInBackground:@selector(loadOrders) withObject:nil];
    showHud = false;
    [self Return];
}

#pragma mark - ReachabilityDelegate

- (void)networkLost {

    //[ciLogo setImage:[UIImage imageNamed:@"ci_red.png"]];
}

- (void)networkRestored {

    //[ciLogo setImage:[UIImage imageNamed:@"ci_green.png"]];
}


#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView.tag == kDeleteCompletedOrder && buttonIndex == 1) {
        MBProgressHUD *deleteHUD = [MBProgressHUD showHUDAddedTo:self.view animated:NO];
        deleteHUD.labelText = @"Deleting Order";
        [deleteHUD show:NO];

        NSURL *url = [NSURL URLWithString:kDBORDEREDITS([[self.itemsDB objectForKey:kOrderId] integerValue])];
        AFHTTPClient *client = [[AFHTTPClient alloc] initWithBaseURL:url];
        NSMutableURLRequest *request = [client requestWithMethod:@"DELETE" path:nil parameters:nil];
        AFHTTPRequestOperation *operation = [client HTTPRequestOperationWithRequest:request
                success:^(AFHTTPRequestOperation *operation, id responseObject) {

                    DLog(@"DELETE success");
                    //                    [self Return];
                    [self deleteRowFromOrderListAtIndex:rowToDelete];
                    self.itemsDB = nil;
                    self.EditorView.hidden = YES;
                    self.toolWithSave.hidden = YES;
                    self.orderContainer.hidden = YES;
                    self.OrderDetailScroll.hidden = YES;
                    [deleteHUD hide:NO];

                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {

                    DLog(@"DELETE failed");
                    NSString *errorMsg = [NSString stringWithFormat:@"Error deleting order. %@", error.localizedDescription];
                    [[[UIAlertView alloc] initWithTitle:@"Error" message:errorMsg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
                    [deleteHUD hide:NO];
                }];

        [operation start];
    } else if (alertView.tag == kDeletePartialOrder && buttonIndex == 1) {
        if (orderToDelete) {
            MBProgressHUD *deleteHUD = [MBProgressHUD showHUDAddedTo:self.view animated:NO];
            deleteHUD.labelText = @"Deleting Order";
            [deleteHUD show:NO];

            if ([[CoreDataUtil sharedManager] deleteObject:orderToDelete]) {
                [self deleteRowFromOrderListAtIndex:rowToDelete];
            } else {
                [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Error deleting order from data store." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
            }

            orderToDelete = nil;
            [deleteHUD hide:NO];
        }
    } else if (alertView.tag == kEditPartialOrder) {
        if (buttonIndex == 1) {
            [self loadProductView:NO];
        } else {
            NSIndexPath *selection = [self.sideTable indexPathForSelectedRow];
            if (selection)
                [self.sideTable deselectRowAtIndexPath:selection animated:YES];
        }
    }
}

- (void)deleteRowFromOrderListAtIndex:(NSIndexPath *)index {
    NSDictionary *anOrder = [self.orders objectAtIndex:index.row];
    [self.orderData removeObjectIdenticalTo:anOrder];
    [self.orders removeObjectAtIndex:index.row];

    NSArray *indices = [NSArray arrayWithObject:index];
    [self.sideTable deleteRowsAtIndexPaths:indices withRowAnimation:UITableViewRowAnimationAutomatic];

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(customer_id = %@) AND (custid = %@)",
                                                              [anOrder objectForKey:@"customer_id"], [[anOrder objectForKey:@"customer"] objectForKey:@"custid"]];

    orderToDelete = (Order *) [[CoreDataUtil sharedManager] fetchObject:@"Order" withPredicate:predicate];
    if (orderToDelete) {
        [[CoreDataUtil sharedManager] deleteObject:orderToDelete];
    }

    //[self.sideTable reloadData];
}

#pragma mark - UIPrinterSelectedDelegate

- (void)setSelectedPrinter:(NSString *)printer {
    currentPrinter = printer;
    [[SettingsManager sharedManager] saveSetting:@"printer" value:printer];
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"PrintersLoaded" object:nil];
    [self printOrder];
}

#pragma mark - Search orders

- (void)searchTextUpdated:(UITextField *)textField {
    [self searchOrders:textField];
}

- (IBAction)searchOrders:(id)sender {
    if (![sender isKindOfClass:[UITextField class]])
        [self.searchText resignFirstResponder];

    if (self.orders == nil|| [self.orders isKindOfClass:[NSNull class]]) {
        return;
    }

    if ([self.searchText.text isEqualToString:@""]) {
        self.orders = [self.orderData mutableCopy];
        DLog(@"string is empty");
    } else {
        DLog(@"Search Text %@", self.searchText.text);
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

        self.orders = [[self.orderData filteredArrayUsingPredicate:pred] mutableCopy];
        DLog(@"results count:%d", self.orders.count);
    }
    [self.sideTable reloadData];
}

#pragma mark - UITextFieldDelegate

- (void)textViewDidBeginEditing:(UITextView *)sender {
    if ([sender isEqual:self.shipdates]) {
        //move the main view, so that the keyboard does not hide it.
        if (self.view.frame.origin.y >= 0) {
            [self setViewMovedUp:YES];
        }
    }
}

- (void)textViewDidEndEditing:(UITextView *)sender {
    if ([sender isEqual:self.shipdates]) {
        //move the main view, so that the keyboard does not hide it.
        if (self.view.frame.origin.y >= 0) {
            [self setViewMovedUp:NO];
        }
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if ([textField.restorationIdentifier isEqualToString:@"SearchField"]) {
        [self.view endEditing:YES];
    }

    return NO;
}

@end
