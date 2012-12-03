//
//  CIOrderViewController.m
//  Convention
//
//  Created by Matthew Clark on 12/8/11.
//  Copyright (c) 2011 MotionMobs. All rights reserved.
//

#import "CIOrderViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "CIViewController.h"
#import "CIOrderCell.h"
#import "config.h"
#import "CIProductViewController.h"
#import "MBProgressHUD.h"
#import "JSONKit.h"

#import "CIPrintViewController.h"
#import "CICalendarViewController.h"
#import "SettingsManager.h"

#import "vender.h"
#import "product.h"
#import "lineItem.h"
#import "StringManipulation.h"
#import "AFHTTPClient.h"
#import "AFJSONRequestOperation.h"
#import "CoreDataUtil.h"
#import "Order.h"
#import "Cart.h"

@interface CIOrderViewController (){
    int currentOrderID;
    BOOL isLoadingOrders;
    UITextField *activeField;
    PullToRefreshView *pull;
    Order *orderToDelete;
    NSInteger rowToDelete;
    CIProductViewController* productView;
}
@end

@implementation CIOrderViewController
@synthesize sBar;
@synthesize ciLogo;
@synthesize orders;
@synthesize orderData;
@synthesize authToken;
@synthesize showPrice;
@synthesize venderInfo;
@synthesize sideTable;
@synthesize saveBtn;
@synthesize EditorView;
@synthesize toolWithSave;
@synthesize toolPlain;
@synthesize itemsDB;
@synthesize customer;
@synthesize authorizer;
@synthesize itemsTable;
@synthesize shipNotes;
@synthesize notes;
@synthesize SCtotal;
@synthesize total;
@synthesize NoOrders;
@synthesize NoOrdersLabel;
@synthesize ordersAct;
@synthesize itemsAct;
@synthesize OrderDetailScroll;
@synthesize sideContainer;
@synthesize placeholderContainer;
@synthesize orderContainer;
@synthesize lblCompany;
@synthesize lblAuthBy;
@synthesize lblNotes;
@synthesize lblShipNotes;
@synthesize lblItems;
@synthesize lblTotalPrice;
@synthesize lblVoucher;
@synthesize itemsQty;
@synthesize itemsPrice;
@synthesize masterVender;
@synthesize currentVender;
@synthesize shipdates;
@synthesize vendorGroup;
@synthesize itemsVouchers;
@synthesize popoverController;
@synthesize storeQtysPO;
@synthesize itemsShipDates;
@synthesize managedObjectContext;

bool showHud = true;

#define kDeleteCompletedOrder 10
#define kDeletePartialOrder 11
#define kEditPartialOrder 12

#pragma mark - initializer

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        masterVender = NO;
        currentVender = 0;
        currentOrderID = 0;
        isLoadingOrders = NO;
        reachDelegation = [[ReachabilityDelegation alloc] initWithDelegate:self withUrl:kBASEURL];
    }
	
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    //self.saveBtn.hidden = YES;
    self.EditorView.hidden = YES;
    self.toolWithSave.hidden = YES;
    self.orderContainer.hidden = YES;
    self.OrderDetailScroll.hidden = YES;
    
    self.placeholderContainer.hidden = NO;
    
    pull = [[PullToRefreshView alloc] initWithScrollView:(UIScrollView *) self.sideTable];
    [pull setDelegate:self];
    [self.sideTable addSubview:pull];
	
	self.sideTable.contentOffset = CGPointMake(0, self.sBar.frame.size.height);
	
	[self Return];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [self setSaveBtn:nil];
    [self setEditorView:nil];
    [self setToolWithSave:nil];
    [self setToolPlain:nil];
    [self setCustomer:nil];
    [self setAuthorizer:nil];
    [self setShipNotes:nil];
    [self setNotes:nil];
    [self setTotal:nil];
    [self setItemsAct:nil];
    [self setOrdersAct:nil];
    [self setNoOrders:nil];
    //[self setOrderDetailScroll:nil]; //Don't do this
    [self setSideContainer:nil];
    [self setPlaceholderContainer:nil];
    [self setOrderContainer:nil];
    [self setNoOrdersLabel:nil];
    [self setLblCompany:nil];
    [self setLblAuthBy:nil];
    [self setLblNotes:nil];
    [self setLblShipNotes:nil];
    [self setLblItems:nil];
    [self setLblTotalPrice:nil];
    [self setSCtotal:nil];
    [self setShipdates:nil];
    [super viewDidDisappear:animated];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    // register for keyboard notifications
	
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
    self.lblShipNotes.font = [UIFont fontWithName:kFontName size:15.f];
    self.lblTotalPrice.font = [UIFont fontWithName:kFontName size:25.f];
    self.total.font = [UIFont fontWithName:kFontName size:25.5];
    self.lblVoucher.font = [UIFont fontWithName:kFontName size:25.f];
    self.SCtotal.font = [UIFont fontWithName:kFontName size:25.f];
    self.NoOrdersLabel.font = [UIFont fontWithName:kFontName size:25.f];
    
    self.customer.font = [UIFont fontWithName:kFontName size:14.f];
    self.authorizer.font = [UIFont fontWithName:kFontName size:14.f];
    self.notes.font = [UIFont fontWithName:kFontName size:14.f];
    self.shipNotes.font = [UIFont fontWithName:kFontName size:14.f];
    
    self.itemsAct.hidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    // unregister for keyboard notifications while not visible.
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidHideNotification object:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

#pragma mark - Data access methods

-(void)loadOrders {
    isLoadingOrders = YES;
	self.OrderDetailScroll.hidden = YES;
	
	MBProgressHUD* hud;
	
	if (showHud) {
        hud = [MBProgressHUD showHUDAddedTo:self.sideTable animated:YES];
        hud.labelText = @"Getting Orders";
        [hud show:YES];
	}
    
    void (^cleanup)(void) = ^{
        if (showHud)
            [hud hide:YES];
        [pull finishedLoading];
        self.sideTable.contentOffset = CGPointMake(0, self.sBar.frame.size.height);
        showHud = true;
        isLoadingOrders = NO;
    };
    
    NSString* url;
    if (masterVender) {
        url = [NSString stringWithFormat:@"%@?%@=%@",kDBMasterORDER,kAuthToken,self.authToken];
    } else {
        url = [NSString stringWithFormat:@"%@?%@=%@",kDBORDER,kAuthToken,self.authToken];
    }
    DLog(@"Sending %@",url);
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
            success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                
                self.orders = [NSMutableArray arrayWithArray:JSON];
                DLog(@"order count: %i", self.orders.count);
                
                [self loadPartialOrders];
                self.orderData = [self.orders mutableCopy];
                
//                [JSON enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
//                    [self.orderData replaceObjectAtIndex:idx withObject:[obj mutableCopy]];
//                }];
                
                [self.sideTable reloadData];
                if ([self.orders count] > 0) {
                    self.NoOrders.hidden = YES;
                }
                
                cleanup();
                
            } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                
                [[[UIAlertView alloc] initWithTitle:@"Error!" message:[NSString stringWithFormat:@"There was an error loading orders:%@",[error localizedDescription]] delegate:nil
                                  cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
                
                cleanup();
            }];
    [operation start];
}

-(void) loadPartialOrders {
    NSArray *partialOrders = [[CoreDataUtil sharedManager] fetchObjects:@"Order" sortField:@"created_at"];
    for (Order *order in partialOrders) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObject:@"" forKey:kAuthorizedBy];
        [dict setObject:order.created_at forKey:kVendorCreatedAt];
        [dict setObject:kPartialOrder forKey:kOrderStatus];
        
        NSMutableDictionary *_customer = [[NSMutableDictionary alloc] init];
        [_customer setObject:order.billname forKey:kBillName];
        [_customer setObject:[order.custid stringValue] forKey:kCustID];
        [_customer setObject:[order.customer_id stringValue] forKey:@"id"];
        
        [dict setObject:_customer forKey:@"customer"];
        [dict setObject:[order.customer_id stringValue] forKey:kOrderCustID];
        [dict setObject:[NSString stringWithFormat:@"%d", [order.carts count]] forKey:kItemCount];
        
// TODO: setup line items
        NSMutableDictionary *lineItems = [[NSMutableDictionary alloc] init];
        [dict setObject:lineItems forKey:kItems];
        
        double itemTotal = 0.f;
        for (int i=0; i < order.carts.count; i++) {
            
            Cart *lineItem = (Cart *)[order.carts objectAtIndex:i];
            
//            __autoreleasing NSError* err = nil;
//            NSMutableDictionary* dict = [self.qty.text objectFromJSONStringWithParseOptions:JKParseOptionNone error:&err];
//            
//            double q = 0;
//            if (err) {
//                DLog(@"UT JSON error:%@",err);
//                q = [self.qty.text doubleValue];
//            }else{
//                DLog(@"UT JSon got:%@", dict);
//                for (NSString* key in dict.allKeys) {
//                    q += [[dict objectForKey:key] doubleValue];
//                }
//            }
            
            itemTotal += [lineItem.editableQty doubleValue] * [lineItem.editablePrice doubleValue];
        };
        
        [dict setObject:[NSNumber numberWithDouble:itemTotal] forKey:kTotal];
        [dict setObject:[NSNumber numberWithInt:0] forKey:kVoucherTotal];
        
        [self.orders insertObject:dict atIndex:0];
    }
}

#pragma mark - Order detail display

-(void) displayOrderDetail:(NSDictionary *)detail {
    self.itemsDB = [NSDictionary dictionaryWithDictionary:detail];
    if (detail)
    {
        NSArray* arr = [detail objectForKey:kItems];
        self.itemsPrice = [NSMutableArray array];
        self.itemsQty = [NSMutableArray array];
        self.itemsVouchers = [NSMutableArray array];
        self.itemsShipDates = [NSMutableArray array];
        
        [arr enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop){
            NSDictionary* dict = (NSDictionary*)obj;
            if ([dict objectForKey:@"price"] && ![[dict objectForKey:@"price"] isKindOfClass:[NSNull class]]) {
                [self.itemsPrice insertObject:[dict objectForKey:@"price"] atIndex:idx];
                DLog(@"p(%i):%@",idx,[dict objectForKey:@"price"]);
            }
            else
                [self.itemsPrice insertObject:@"0.0" atIndex:idx];
            
            if ([dict objectForKey:@"quantity"]&&![[dict objectForKey:@"quantity"] isKindOfClass:[NSNull class]]) {
                [self.itemsQty insertObject:[dict objectForKey:@"quantity"] atIndex:idx];
                DLog(@"q(%i):%@",idx,[dict objectForKey:@"quantity"]);
            }
            else
                [self.itemsQty insertObject:@"0" atIndex:idx];
            
            if ([dict objectForKey:kOrderItemVoucher]&&![[dict objectForKey:kOrderItemVoucher] isKindOfClass:[NSNull class]]) {
                [self.itemsVouchers insertObject:[dict objectForKey:kOrderItemVoucher] atIndex:idx];
                //                    DLog(@"%@",[dict objectForKey:kOrderItemVoucher]);
            }
            else
                [self.itemsVouchers insertObject:@"0" atIndex:idx];
            
            if ([dict objectForKey:kOrderItemShipDates]&&![[dict objectForKey:kOrderItemShipDates] isKindOfClass:[NSNull class]]) {
                
                NSArray* raw = [dict objectForKey:kOrderItemShipDates];
                NSMutableArray* dates = [NSMutableArray array];
                NSDateFormatter* df = [[NSDateFormatter alloc] init];
                [df setDateFormat:@"yyyy-MM-dd"];//@"yyyy-MM-dd'T'HH:mm:ss'Z'"
                for(NSString* str in raw){
                    NSDate* date = [df dateFromString:str];
                    //DLog(@"str:%@ date:%@",str, date);
                    [dates addObject:date];
                }
                
                [self.itemsShipDates insertObject:dates atIndex:idx];
                //                    DLog(@"%@",[dict objectForKey:kOrderItemVoucher]);
            }
            else
                [self.itemsShipDates insertObject:[NSArray array] atIndex:idx];
        }];
        //            DLog(@"items Json:%@",itemsDB);
        [self.itemsTable reloadData];
        
        NSMutableArray* SDs = [NSMutableArray array];
        [self.itemsShipDates enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSMutableArray* dates = (NSMutableArray*)obj;
            [dates enumerateObjectsUsingBlock:^(id obj1, NSUInteger idx1, BOOL *stop1) {
                NSDate* date = (NSDate*)obj1;
                if (![SDs containsObject:date]) {
                    [SDs addObject:date];
                }
            }];
        }];
        
        NSString __block *sdtext = @"";
        [SDs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if (idx!=0) {
                sdtext = [sdtext stringByAppendingString:@", "];
            }
            NSDate* date = (NSDate*)obj;
            NSDateFormatter* df = [[NSDateFormatter alloc] init];
            [df setDateFormat:@"yyyy-MM-dd"];//@"yyyy-MM-dd'T'HH:mm:ss'Z'"
            sdtext = [sdtext stringByAppendingString:[df stringFromDate:date]];
        }];
        
        self.shipdates.text = sdtext;
        sdtext = nil;
        
        if (![[self.itemsDB objectForKey:kShipNotes] isKindOfClass:[NSNull class]]) {
            self.shipNotes.text = [self.itemsDB objectForKey:kShipNotes];
        }
        //            DLog(@"notes:%@",[self.itemsDB objectForKey:kNotes]);
        if (![[self.itemsDB objectForKey:kNotes] isKindOfClass:[NSNull class]]) {
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

-(void) loadProductView:(BOOL)newOrder {
    productView = [[CIProductViewController alloc] initWithNibName:@"CIProductViewController" bundle:nil];
    productView.authToken = self.authToken;
    productView.vendorGroup = self.vendorGroup;
    productView.delegate = self;
    productView.managedObjectContext = self.managedObjectContext;
    productView.showCustomers = newOrder;
    if (!newOrder) {
        NSUInteger index = [self.orders indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            return [[obj objectForKey:kID] intValue] == currentOrderID;
        }];
        if (index != NSNotFound) {
            productView.customerId = [[[[self.orders objectAtIndex:index] objectForKey:@"customer"] objectForKey:kID] intValue];
        }
    }
    [productView setTitle:@"Select Products"];//[venderInfo objectForKey:kName]];
    if (venderInfo && venderInfo.count > 0) {
        
        NSString *venderHidePrice = [[venderInfo objectAtIndex:currentVender] objectForKey:kVenderHidePrice];
        if(venderHidePrice != nil){
            productView.showPrice = ![venderHidePrice boolValue];
        }
        
        DLog(@"Vendor Name:%@, navTitle:%@",[[venderInfo objectAtIndex:currentVender] objectForKey:kName],productView.navBar.topItem.title);
    }
    
    [self presentViewController:productView animated:NO completion:nil];
}

#pragma mark - UITableView Datasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.sideTable && self.orders) {
        return [self.orders count];
    }
    else if (tableView==self.itemsTable&&self.itemsDB) {
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
        
        CIOrderCell *cell = [sideTable dequeueReusableCellWithIdentifier:CellIdentifier];
        
        if (cell == nil){
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"CIOrderCell" owner:nil options:nil]; 
            cell = [topLevelObjects objectAtIndex:0];
        }
        
        NSDictionary* data = [self.orders objectAtIndex:[indexPath row]];
        //DLog(@"data:%@",data);
        
        cell.Customer.text = [NSString stringWithFormat:@"%@ - %@",([[data objectForKey:@"customer"] objectForKey:kBillName]==nil?@"(Unknown)":[[data objectForKey:@"customer"] objectForKey:kBillName]),([[data objectForKey:@"customer"] objectForKey:kCustID]==nil?@"(Unknown)":[[data objectForKey:@"customer"] objectForKey:kCustID])];
        if ([data objectForKey:kAuthorizedBy] != nil&&![[data objectForKey:kAuthorizedBy] isKindOfClass:[NSNull class]]) {
            cell.auth.text = [data objectForKey:kAuthorizedBy];    
        }
        else
            cell.auth.text = @"";
        if ([data objectForKey:kItemCount] != nil) {
            cell.numItems.text = [NSString stringWithFormat:@"%d Items",[[data objectForKey:kItemCount] intValue]];    
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
        
        if ([[data objectForKey:kItems] count]>0) {
            cell.tag = [[[[data objectForKey:kItems] objectAtIndex:0] objectForKey:@"order_id"] intValue];
        }
        else
            cell.tag = [[data objectForKey:kID] intValue];
        
        if ([data objectForKey:kOrderStatus] != nil) {
            cell.orderStatus.text = [[data objectForKey:kOrderStatus] capitalizedString];
            if ([[cell.orderStatus.text lowercaseString] isEqualToString:kPartialOrder])
                cell.orderStatus.textColor = [UIColor redColor];
            else
                cell.orderStatus.textColor = [UIColor blackColor];
        } else {
            cell.orderStatus.text = @"Unknown";
            cell.orderStatus.textColor = [UIColor orangeColor];
        }
        
        return cell;
    }
    else if(tableView == self.itemsTable){
        if (!self.itemsDB) {
            return nil;
        }
        static NSString *cellIdentifier = @"CIItemEditCell";
        
        CIItemEditCell *cell = [self.itemsTable dequeueReusableCellWithIdentifier:cellIdentifier];
        
        if (cell == nil){
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"CIItemEditCell" owner:nil options:nil];
            cell = [topLevelObjects objectAtIndex:0];
        }
        
        cell.delegate = self;
        
        if ([[self.itemsDB objectForKey:kItemCount] intValue] > [indexPath row]) {

            NSDictionary* data = [[self.itemsDB objectForKey:kItems] objectAtIndex:[indexPath row]];
            if ([data objectForKey:@"desc"]) {
                cell.desc.text = [NSString stringWithFormat:@"%@",[data objectForKey:@"desc"]];
            }
            
            if ([self.itemsVouchers objectAtIndex:indexPath.row]) {
                cell.voucher.text = [self.itemsVouchers objectAtIndex:indexPath.row];            }
            else
                cell.voucher.text = @"0";
            
            BOOL isJSON = NO;
            double q = 0;
            if ([self.itemsQty objectAtIndex:indexPath.row]) {
                cell.qty.text = [self.itemsQty objectAtIndex:indexPath.row];//[[data objectForKey:@"quantity"] stringValue];
                DLog(@"setting qty:(%@)%@",[self.itemsQty objectAtIndex:indexPath.row],cell.qty.text);
                q = [cell.qty.text doubleValue];
            }
            else
                cell.qty.text = @"0";
            
            __autoreleasing NSError* err = nil;
            NSMutableDictionary* dict = [cell.qty.text objectFromJSONStringWithParseOptions:JKParseOptionNone error:&err];
            
            if(!err&&dict&&![dict isKindOfClass:[NSNull class]]&&dict.allKeys.count>0){
                DLog(@"Cell JSon got:%@", dict);
                isJSON = YES;
            }
            
            if (isJSON) {
                [cell.qtyBtn setHidden:NO];
                for (NSString* key in dict.allKeys) {
                    q += [[dict objectForKey:key] doubleValue];
                }
            } else {
                [cell.qtyBtn setHidden:YES];
            }
            
            int lblsd = 0;
            int nd = 1;
            if (((NSArray*)[self.itemsShipDates objectAtIndex:indexPath.row]).count>0) {
                nd = ((NSArray*)[self.itemsShipDates objectAtIndex:indexPath.row]).count;
                lblsd = nd;
            }
            
            DLog(@"Shipdate count:%d nd:%d array:%@",((NSArray*)[self.itemsShipDates objectAtIndex:indexPath.row]).count,nd,((NSArray*)[self.itemsShipDates objectAtIndex:indexPath.row]));
            
            [cell.btnShipdates setTitle:[NSString stringWithFormat:@"SD:%d",lblsd] forState:UIControlStateNormal];
            
            DLog(@"price:%@", [self.itemsPrice objectAtIndex:indexPath.row]);
            if ([self.itemsPrice objectAtIndex:indexPath.row]&&![[self.itemsPrice objectAtIndex:indexPath.row] isKindOfClass:[NSNull class]]) {
                NSNumberFormatter* nf = [[NSNumberFormatter alloc] init];
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
        }
        else
            return nil;

        return cell;
    }
    else
        return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"asdfa"];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.sideTable) {
        
        if ([self.sBar isFirstResponder]) {
            [self.sBar resignFirstResponder];
        }
        
        NSDictionary *selectedOrder = [self.orders objectAtIndex:indexPath.row];
        NSString *status = [[selectedOrder objectForKey:kOrderStatus] lowercaseString];
        if (![status isEqualToString:kPartialOrder])
        {
            self.EditorView.hidden = NO;
            self.toolWithSave.hidden = NO;
            self.orderContainer.hidden = NO;
            self.OrderDetailScroll.hidden = NO;
            
            self.itemsAct.hidden = NO;
            [self.itemsAct startAnimating];
            
            self.customer.text = @"";
            self.authorizer.text = @"";
            self.shipNotes.text = @"";
            self.notes.text = @"";
            self.itemsDB = nil;
            self.itemsPrice = nil;
            self.itemsQty = nil;
            self.itemsVouchers = nil;
            self.itemsShipDates = nil;
            [self.itemsTable reloadData];
            
            CIOrderCell* cell = (CIOrderCell*)[self.sideTable cellForRowAtIndexPath:indexPath];
            
            self.customer.text = cell.Customer.text;
            self.authorizer.text = cell.auth.text;
            
            self.EditorView.tag = cell.tag;
            currentOrderID = cell.tag;
            
            [self displayOrderDetail:[self.orders objectAtIndex:indexPath.row]];
        } else {
            
            self.EditorView.hidden = YES;
            self.toolWithSave.hidden = YES;
            self.orderContainer.hidden = YES;
            self.OrderDetailScroll.hidden = YES;
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Confirm" message:@"Do you want to edit this pending order?"
                                       delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Edit", nil];
            [alert setTag:kEditPartialOrder];
            [alert show];
        }
    }
    else if(tableView == self.itemsTable){
        
    }
}

-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.sideTable) {
        return UITableViewCellEditingStyleDelete;
    }
    else
        return UITableViewCellEditingStyleNone;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.sideTable) {
        if (editingStyle == UITableViewCellEditingStyleDelete) {
            NSDictionary *selectedOrder = [self.orders objectAtIndex:indexPath.row];
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"DELETE" message:@"Are you sure you want to delete this order?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Delete", nil];

            if ([[[selectedOrder objectForKey:kOrderStatus] lowercaseString] isEqualToString:kPartialOrder]) {
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(customer_id = %@) AND (custid = %@)",
                                          [selectedOrder objectForKey:@"customer_id"], [[selectedOrder objectForKey:@"customer"] objectForKey:@"custid"]];
                
                orderToDelete = (Order *)[[CoreDataUtil sharedManager] fetchObject:@"Order" withPredicate:predicate];
                if (orderToDelete)
                {
                    rowToDelete = indexPath.row;
//                    NSString *msg = [NSString stringWithFormat:@"Are you sure you want to delete the order for customer: %@?", cell.Customer.text];
//                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Pending Order Deletion" message:msg delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Delete", nil];
                    [alert setTag:kDeletePartialOrder];
                    [alert show];
                }
            } else {
                self.itemsDB = [NSDictionary dictionaryWithDictionary:[self.orders objectAtIndex:indexPath.row]];
                rowToDelete = indexPath.row;
                [alert setTag:kDeleteCompletedOrder];
                [alert show];
            }
        }
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(tableView==self.sideTable)
        return 114; // was 101
    else
        return 44;
}

#pragma mark - CIItemEditDelegate

-(void) UpdateTotal{
    if(self.itemsDB)
    {
        double ttotal = 0;
        double sctotal = 0;
        
        NSNumberFormatter* nf = [[NSNumberFormatter alloc] init];
        [nf setNumberStyle:NSNumberFormatterCurrencyStyle];
        
        NSInteger itemCount = [[self.itemsDB objectForKey:kItemCount] intValue];
        DLog(@"itemCount:%i, itemQty:%i", itemCount, [self.itemsQty count]);
        
        for (int i = 0; i < itemCount; i++) {
            double price = [[self.itemsPrice objectAtIndex:i] doubleValue];
            double qty = 0;
            
            __autoreleasing NSError* err = nil;
            NSMutableDictionary *dict = [[self.itemsQty objectAtIndex:i] objectFromJSONStringWithParseOptions:JKParseOptionNone error:&err];
            if (err)
                qty = [[self.itemsQty objectAtIndex:i] doubleValue];
            else if (dict && ![dict isKindOfClass:[NSNull class]]) {
                for (NSString* key in dict.allKeys)
                    qty += [[dict objectForKey:key] doubleValue];
            }
            
            double numShipDates = 1;
            if (((NSArray*)[self.itemsShipDates objectAtIndex:i]).count > 0)
                numShipDates = ((NSArray*)[self.itemsShipDates objectAtIndex:i]).count;
            
            ttotal += price * qty * numShipDates;
            sctotal += [[self.itemsVouchers objectAtIndex:i] doubleValue] * qty * numShipDates;
        }
        
        self.total.text = [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithDouble:ttotal] numberStyle:NSNumberFormatterCurrencyStyle];
        self.SCtotal.text = [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithDouble:sctotal] numberStyle:NSNumberFormatterCurrencyStyle];
    }
}

-(void)setVoucher:(NSString *)voucher atIndex:(int)idx{
    //DLog(@"%@",self.itemsPrice);
    [self.itemsVouchers removeObjectAtIndex:idx];
    [self.itemsVouchers insertObject:voucher atIndex:idx];
}

-(void)setPrice:(NSString*)prc atIndex:(int)idx{
    //DLog(@"%@",self.itemsPrice);
    [self.itemsPrice removeObjectAtIndex:idx];
    [self.itemsPrice insertObject:prc atIndex:idx];
}

-(void)setQuantity:(NSString*)qty atIndex:(int)idx{
    //DLog(@"%@",self.itemsQty);
    [self.itemsQty removeObjectAtIndex:idx];
    [self.itemsQty insertObject:qty atIndex:idx];
}

-(void)QtyTouchForIndex:(int)idx{
    if ([popoverController isPopoverVisible]) {
        [popoverController dismissPopoverAnimated:YES];
    }else{
        if (!storeQtysPO) {
            storeQtysPO = [[CIStoreQtyTableViewController alloc] initWithNibName:@"CIStoreQtyTableViewController" bundle:nil];
        }
        
        NSMutableDictionary* dict = [[[self.itemsQty objectAtIndex:idx] objectFromJSONString] mutableCopy];
        storeQtysPO.stores = dict;
        storeQtysPO.tag = idx;
        storeQtysPO.delegate = self;
        CGRect frame = [self.itemsTable rectForRowAtIndexPath:[NSIndexPath indexPathForRow:idx inSection:0]];
        frame = CGRectOffset(frame, 0, 0);
        DLog(@"pop from frame:%@",NSStringFromCGRect(frame));
        popoverController = [[UIPopoverController alloc] initWithContentViewController:storeQtysPO];
        [popoverController presentPopoverFromRect:frame inView:self.itemsTable permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
}

-(void)ShipDatesTouchForIndex:(int)idx{
    CICalendarViewController* calView = [[CICalendarViewController alloc] initWithNibName:@"CICalendarViewController" bundle:nil];
    NSDateFormatter* df = [[NSDateFormatter alloc] init];
    //            DLog(@"date(%@):%@",[[self.productData objectAtIndex:[indexPath row]] objectForKey:kProductShipDate1],date);
    //    [df setDateFormat:@"yyyy-MM-dd"];
    [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
    
    NSDate* startDate = [[NSDate alloc]init];
    NSDate* endDate = [[NSDate alloc]init];
    
    if ([self.itemsDB objectForKey:kItems] == nil) {
        DLog(@"no items");
        return;
    }
    if ([[self.itemsDB objectForKey:kItems] objectAtIndex:idx] == nil) {
        DLog(@"not for idx:%d",idx);
        return;
    }
    if ([[[self.itemsDB objectForKey:kItems] objectAtIndex:idx] objectForKey:@"product"] == nil) {
        DLog(@"no product");
        return;
    }
    NSString* start = [[[[self.itemsDB objectForKey:kItems] objectAtIndex:idx] objectForKey:@"product"] objectForKey:kProductShipDate1];
    NSString* end = [[[[self.itemsDB objectForKey:kItems] objectAtIndex:idx] objectForKey:@"product"] objectForKey:kProductShipDate2];

// FIXME: Setup calendar to show starting at current date

    //NSDate *now = [NSDate date];
    if(start && end && ![start isKindOfClass:[NSNull class]] && ![end isKindOfClass:[NSNull class]] && start.length > 0 && end.length > 0){
        startDate = [df dateFromString:start];
//        if (startDate < now)
//            startDate = now;
        endDate = [df dateFromString:end];
//        if (endDate < startDate)
//            endDate = startDate;
    }else{
        return;
    }
    
    NSCalendar *currentCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setDay:1];
    
    NSMutableArray *dateList = [NSMutableArray array];
    [dateList addObject: startDate];
    NSDate *currentDate = startDate;
    // add one the first time through, so that we can use NSOrderedAscending (prevents millisecond infinite loop)
    currentDate = [currentCalendar dateByAddingComponents:comps toDate:currentDate  options:0];
    while ( [endDate compare: currentDate] != NSOrderedAscending) {
        [dateList addObject: currentDate];
        currentDate = [currentCalendar dateByAddingComponents:comps toDate:currentDate  options:0];
    }
    
    calView.startDate = startDate;
    __weak CICalendarViewController *calViewW = calView;
    calView.cancelTouched = ^{
        DLog(@"calender canceled");
        [calViewW dismissViewControllerAnimated:YES completion:nil];
        [self.itemsTable reloadData];
		
    };
    
    calView.doneTouched = ^(NSArray* dates){
        [self.itemsShipDates removeObjectAtIndex:idx];
        [self.itemsShipDates insertObject:[dates copy] atIndex:idx];
        [calViewW dismissViewControllerAnimated:YES completion:nil];
        
        [self.itemsTable reloadData];
        [self UpdateTotal];
    };
    
    calView.afterLoad = ^{
        NSArray* dates = [self.itemsShipDates objectAtIndex:idx];
        calView.calendarView.selectedDates = [dates mutableCopy];
        calView.calendarView.avalibleDates = dateList;
        DLog(@"dates:%@ what it got:%@",dates, calView.calendarView.selectedDates);
    };
    
    [self presentViewController:calView animated:YES completion:nil];
}

-(void)setViewMovedUpDouble:(BOOL)movedUp
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.5]; // if you want to slide up the view
    
    CGRect rect = self.OrderDetailScroll.frame;
    if (movedUp)
    {
        // 1. move the view's origin up so that the text field that will be hidden come above the keyboard
        // 2. increase the size of the view so that the area behind the keyboard is covered up.
        rect.origin.y += kOFFSET_FOR_KEYBOARD * 3;//was -
        // rect.size.height += kOFFSET_FOR_KEYBOARD;
    }
    else
    {
        // revert back to original position relative to the top of the OrderDetailScroll.
        rect.origin.y = 0;
    }
    self.OrderDetailScroll.contentOffset = CGPointMake(0, rect.origin.y);//rect.origin;
    
    [UIView commitAnimations];
}

-(void)setActiveField:(UITextField *)textField {
    activeField = textField;
}

#pragma mark - CIProductViewDelegate

-(void)Return {
    if (!isLoadingOrders) {
        self.itemsDB = nil;
        [self loadOrders];
    }
}

#pragma mark - CIStoreQtyDelegate

-(void)QtyChange:(double)qty forIndex:(int)idx {
	
	//Not Imlemented
}

#pragma mark - Events

- (IBAction)AddNewOrder:(id)sender {
    [self loadProductView:YES];
}

-(void)logout
{
    void (^clearSettings)(void) = ^ {
        [[SettingsManager sharedManager] saveSetting:@"username" value:@""];
        [[SettingsManager sharedManager] saveSetting:@"password" value:@""];
    };
    
    NSString *logoutPath;
    if (!masterVender) {
        if (authToken) {
            logoutPath = [NSString stringWithFormat:@"%@?%@=%@",kDBLOGOUT,kAuthToken,authToken];
        } else {
            logoutPath = kDBLOGOUT;
        }
    } else {
        if (authToken) {
            logoutPath = [NSString stringWithFormat:@"%@?%@=%@",kDBMasterLOGOUT,kAuthToken,authToken];
        } else {
            logoutPath = kDBMasterLOGOUT;
        }
    }
    
    NSURL *url = [NSURL URLWithString:logoutPath];
    DLog(@"Signout url:%@",url);
    
    AFHTTPClient *client = [[AFHTTPClient alloc] initWithBaseURL:url];
    NSMutableURLRequest *request = [client requestWithMethod:@"DELETE" path:@"" parameters:nil];
    AFHTTPRequestOperation *operation = [client HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        clearSettings();
        [self dismissViewControllerAnimated:YES completion:nil];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        [[[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"There was an error logging out please try again! Error:%@",
                  [error localizedDescription]] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
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
    
    NSMutableArray* arr = [[NSMutableArray alloc] initWithCapacity:[self.itemsTable numberOfRowsInSection:0]];
    NSArray* data = [self.itemsDB objectForKey:kItems];
    for (NSInteger i =0; i<[self.itemsTable numberOfRowsInSection:0]; i++) {
        NSString* productID = [[data objectAtIndex:i] objectForKey:kOrderItemID];
        CIItemEditCell* cell = (CIItemEditCell*)[self.itemsTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        NSString* qty = cell.qty.text;
        if (self.itemsQty.count > i) {
            qty = [self.itemsQty objectAtIndex:i];
        }
        
        NSArray* dates = [self.itemsShipDates objectAtIndex:i];
        NSMutableArray* strs = [NSMutableArray array];
        NSDateFormatter* df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
        for(NSDate* date in dates){
            NSString* str = [df stringFromDate:date];
            [strs addObject:str];
        }
        
        NSDictionary* proDict = [NSDictionary dictionaryWithObjectsAndKeys:productID,kOrderItemID,[[data objectAtIndex:i] objectForKey:kID],kID,qty,kOrderItemNum,cell.price.text,kOrderItemPRICE,cell.voucher.text,kOrderItemVoucher,strs,kOrderItemShipDates, nil];
        [arr addObject:(id)proDict];
    }
    
    [arr removeObjectIdenticalTo:nil];
    DLog(@"array:%@",arr);
    NSDictionary* order;
    order = [NSDictionary dictionaryWithObjectsAndKeys:[self.itemsDB objectForKey:kOrderCustID],kOrderCustID,self.shipNotes.text,
             kShipNotes,self.notes.text,kNotes,[self.itemsDB objectForKey:kAuthorizedBy],kAuthorizedBy, arr, kOrderItems, nil];
    
    NSDictionary* final = [NSDictionary dictionaryWithObjectsAndKeys:order, kOrder, nil];
    NSString *url = [NSString stringWithFormat:@"%@?%@=%@",[NSString stringWithFormat:kDBORDEREDITS(currentOrderID)],kAuthToken,self.authToken];
    
    
    AFHTTPClient *client = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:url]];
    [client setParameterEncoding:AFJSONParameterEncoding];
    NSMutableURLRequest *request = [client requestWithMethod:@"PUT" path:nil parameters:final];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        NSString *status = [JSON valueForKey:@"status"];
        DLog(@"status = %@", status);
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSString *errorMsg = [NSString stringWithFormat:@"There was an error submitting the order. %@", error.localizedDescription];
        [[[UIAlertView alloc] initWithTitle:@"Error!" message:errorMsg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
    }];
    
    [operation start];
}

- (IBAction)Refresh:(id)sender {
    [self Return];
}

- (IBAction)Print:(id)sender {
    if (self.itemsDB&&self.itemsDB.allKeys.count > 0&&[self.itemsDB objectForKey:@"id"]) {
        CIPrintViewController* print = [[CIPrintViewController alloc] initWithNibName:@"CIPrintViewController" bundle:nil];
        print.modalPresentationStyle = UIModalPresentationFormSheet;
        print.orderID = [NSString stringWithFormat:@"%@",[self.itemsDB objectForKey:@"id"]];
        [self presentViewController:print animated:YES completion:nil];
    }else{
        [[[UIAlertView alloc]initWithTitle:@"Oops!" message:@"Please select an order to print!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
    }
}

- (IBAction)Delete:(id)sender {
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"DELETE" message:@"Are you sure you want to delete this order?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Delete", nil];
    alert.tag = kDeleteCompletedOrder;
    [alert show];
}

//method to move the view up/down whenever the keyboard is shown/dismissed
-(void)setViewMovedUp:(BOOL)movedUp
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.5]; // if you want to slide up the view
    
    CGRect rect = self.OrderDetailScroll.frame;
    if (movedUp)
    {
        // 1. move the view's origin up so that the text field that will be hidden come above the keyboard 
        // 2. increase the size of the view so that the area behind the keyboard is covered up.
        rect.origin.y += kOFFSET_FOR_KEYBOARD;//was -
        //rect.size.height += kOFFSET_FOR_KEYBOARD;
    }
    else
    {
        // revert back to the normal state.
        rect.origin.y = 0;
    }
    self.OrderDetailScroll.contentOffset = CGPointMake(0, rect.origin.y);
    
    [UIView commitAnimations];
}

- (void)keyboardWillShow {
    //keyboard will be shown now. depending for which textfield is active, move up or move down the view appropriately
    
    if (activeField)
    {
        [self setViewMovedUpDouble:YES];
        
    } else if ([self.shipNotes isFirstResponder] && self.view.frame.origin.y >= 0)
    {
        [self setViewMovedUp:YES];
    }
    else if (![self.shipNotes isFirstResponder] && self.view.frame.origin.y < 0)
    {
        [self setViewMovedUp:NO];
    }
}

-(void)keyboardDidHide {
    if (activeField) {
        [self setViewMovedUpDouble:NO];
        [self setActiveField:nil];
    } else {
        [self setViewMovedUp:NO];
    }
}

-(void)QtyTableChange:(NSMutableDictionary *)qty forIndex:(int)idx{
    NSString* JSON = [qty JSONString];
    DLog(@"setting qtys on index(%d) to %@",idx,JSON);
    
//    NSString* key = [[self.resultData objectAtIndex:idx] objectForKey:@"id"];
    
    CIItemEditCell* cell = (CIItemEditCell*)[self.itemsTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:idx inSection:1]];
    
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

-(void)networkLost {
	
	[ciLogo setImage:[UIImage imageNamed:@"ci_red.png"]];
}

-(void)networkRestored {
	
	[ciLogo setImage:[UIImage imageNamed:@"ci_green.png"]];
}

#pragma mark - UIAlertViewDelegate

-(void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex{
    if (alertView.tag == kDeleteCompletedOrder && buttonIndex == 1) {
        MBProgressHUD* deleteHUD = [MBProgressHUD showHUDAddedTo:self.view animated:NO];
        deleteHUD.labelText = @"Deleting Order";
        [deleteHUD show:NO];
        
        NSURL *url = [NSURL URLWithString:kDBORDEREDITS([[self.itemsDB objectForKey:@"id"] integerValue])];
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
            MBProgressHUD* deleteHUD = [MBProgressHUD showHUDAddedTo:self.view animated:NO];
            deleteHUD.labelText = @"Deleting Order";
            [deleteHUD show:NO];

            if ([[CoreDataUtil sharedManager] deleteObjectWithConfirmation:orderToDelete])
            {
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

- (void)deleteRowFromOrderListAtIndex:(NSInteger)index {
    NSDictionary *anOrder = [self.orders objectAtIndex:index];
    [self.orderData removeObjectIdenticalTo:anOrder];
    [self.orders removeObjectAtIndex:index];
    [self.sideTable reloadData];
}

#pragma mark - UISearchBarDelegate

-(void)searchBar:(UISearchBar *)sBar textDidChange:(NSString *)searchText{
 
	if (self.orders == nil||[self.orders isKindOfClass:[NSNull class]]) {
        return;
    }
	 
	if ([searchText isEqualToString:@""]) {
		self.orders = [self.orderData mutableCopy];
		DLog(@"string is empty");
	}else{
		DLog(@"Search Text %@", searchText);
		NSPredicate* pred = [NSPredicate predicateWithBlock:^BOOL(id obj, NSDictionary* bindings){
			NSMutableDictionary* dict = (NSMutableDictionary*)obj;
		 
			NSString *storeName = [[dict objectForKey:@"customer"] objectForKey:kBillName];
			NSString *custId = [[dict objectForKey:@"customer"] objectForKey:kCustID];
            NSString *authorized = [dict objectForKey:@"authorized"];
//			DLog(@"Bill Name: %@", storeName);
//			DLog(@"Cust Id: %@", custId);
//            DLog(@"Authorized: %@", authorized);
			
			return [[storeName uppercaseString] contains:[searchText uppercaseString]] ||
                    [[custId uppercaseString] hasPrefix:[searchText uppercaseString]] ||
                    [[authorized uppercaseString] hasPrefix:[searchText uppercaseString]];
		}];
		
		self.orders = [[self.orderData filteredArrayUsingPredicate:pred] mutableCopy];
		DLog(@"results count:%d", self.orders.count);
	}
	[self.sideTable reloadData];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [searchBar setShowsCancelButton:YES animated:YES];
}

-(void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    [searchBar setShowsCancelButton:NO animated:YES];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [searchBar setText:@""];
    [searchBar resignFirstResponder];
    self.orders = [self.orderData mutableCopy];
    [self.sideTable reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

#pragma mark - UITextFieldDelegate

-(void)textViewDidBeginEditing:(UITextView *)sender
{
    if ([sender isEqual:self.shipNotes])
    {
        //move the main view, so that the keyboard does not hide it.
        if  (self.view.frame.origin.y >= 0)
        {
            [self setViewMovedUp:YES];
        }
    }
}

-(void)textViewDidEndEditing:(UITextView *)sender
{
    if ([sender isEqual:self.shipNotes])
    {
        //move the main view, so that the keyboard does not hide it.
        if  (self.view.frame.origin.y >= 0)
        {
            [self setViewMovedUp:NO];
        }
    }
}

//// Called when the UIKeyboardDidShowNotification is sent.
//- (void)keyboardWasShown:(NSNotification*)aNotification
//{
//    if (activeField) {
//        NSDictionary* info = [aNotification userInfo];
//        CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
//
//        UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
//        OrderDetailScroll.contentInset = contentInsets;
//        OrderDetailScroll.scrollIndicatorInsets = contentInsets;
//        
//        // If active text field is hidden by keyboard, scroll it so it's visible
//        // Your application might not need or want this behavior.
//        CGRect aRect = self.view.frame;
//        aRect.size.height += kbSize.height;
//        if (!CGRectContainsPoint(aRect, activeField.frame.origin) ) {
//            CGPoint scrollPoint = CGPointMake(0.0, activeField.frame.origin.y - kbSize.height);
//            [OrderDetailScroll setContentOffset:scrollPoint animated:YES];
//        }
//    }
//}
//
//// Called when the UIKeyboardWillHideNotification is sent
//- (void)keyboardWillBeHidden:(NSNotification*)aNotification
//{
//    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
//    OrderDetailScroll.contentInset = contentInsets;
//    OrderDetailScroll.scrollIndicatorInsets = contentInsets;
//}

@end
