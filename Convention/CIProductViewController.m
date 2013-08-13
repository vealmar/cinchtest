//
//  CIProductViewController.m
//  Convention
//
//  Created by Matthew Clark on 10/31/11.
//  Copyright (c) 2011 MotionMobs. All rights reserved.
//

#import "CIProductViewController.h"
#import "config.h"
#import "JSONKit.h"
#import "CIViewController.h"
#import "CIProductCell.h"
#import "CICustomerInfoViewController.h"
#import "CICartViewController.h"
#import "MBProgressHUD.h"
#import "Macros.h"
#import "CICalendarViewController.h"
#import "SettingsManager.h"
#import "DateUtil.h"
#import "CoreDataUtil.h"
#import "CIAppDelegate.h"
#import "Cart.h"
#import "ShipDate.h"
#import "Order+Extensions.h"
#import "Cart+Extensions.h"
#import "StringManipulation.h"
#import "AFJSONRequestOperation.h"
#import "AFHTTPClient.h"
#import "CustomerDataController.h"
#import "UIAlertViewDelegateWithBlock.h"
#import "PrinterSelectionViewController.h"
#import "FarrisProductCell.h"

@interface CIProductViewController (){
    //MBProgressHUD* loading;
    NSInteger currentVendor; //SG: This is the logged in vendor's id.
//    int currentVendId;
    int currentBulletin;
    NSArray* vendorsData;
    NSMutableDictionary* editableData;
    NSMutableSet* selectedIdx;
    BOOL isInitialized;
    UITapGestureRecognizer *gestureRecognizer;
    UITextField *currentTextField;
    NSDictionary *bulletins;
    BOOL isShowingBulletins;
    BOOL customerHasBeenSelected;
    NSArray *navItems;
    NSIndexPath *selectedItemRowIndexPath;
}

-(void) getCustomers;

@end

@implementation CIProductViewController
@synthesize vendorLabel;
@synthesize products;
@synthesize ciLogo;
@synthesize hiddenTxt;
@synthesize productData;
@synthesize authToken;
@synthesize navBar;
@synthesize vendorView;
@synthesize vendorTable;
@synthesize dismissVendor;
@synthesize customerLabel;
@synthesize title;
@synthesize showPrice;
@synthesize indicator;
@synthesize customerDB;
@synthesize customer;
@synthesize delegate;
@synthesize tOffset;
@synthesize productCart;
@synthesize backFromCart;
@synthesize finishOrder;
@synthesize vendorGroup;
@synthesize resultData;
@synthesize popoverController;
@synthesize storeQtysPO;
@synthesize multiStore;
@synthesize managedObjectContext;
@synthesize order = _order;
@synthesize showCustomers = _showCustomers;
@synthesize customerId = _customerId;
@synthesize printStationId = _printStationId;
@synthesize availablePrinters = _availablePrinters;
@synthesize cartButton;
@synthesize vendorDropdown;
@synthesize lblShipDate1, lblShipDate2, lblShipDateCount;
@synthesize btnSelectShipDates;
@synthesize tableHeaderPigglyWiggly, tableHeaderFarris;
@synthesize searchText;

#pragma mark - constructor

#define kBulletinsLoaded @"BulletinsLoaded"
#define kDeserializeOrder @"DeserializeOrder"
#define kLaunchCart @"LaunchCart"

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self != nil) {
        // Custom initialization
        showPrice = YES;
        backFromCart = NO;
        tOffset = 0;
        currentVendor = 0;
//        currentVendId = 0;
        currentBulletin = 0;
        productCart = [NSMutableDictionary dictionary];
        self.discountItems = [NSMutableDictionary dictionary];
        editableData = [NSMutableDictionary dictionary];
        selectedIdx = [NSMutableSet set];
        multiStore = NO;
        isInitialized = NO;
        _showCustomers = YES;
        currentTextField = nil;
        isShowingBulletins = NO;
        _printStationId = 0;
        customerHasBeenSelected = NO;
//        navItems = [NSArray arrayWithArray:vendorNav.items];
//        [vendorNav setItems:[NSArray array]];

    }
	
	reachDelegation = [[ReachabilityDelegation alloc] initWithDelegate:self withUrl:kBASEURL];
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.searchText addTarget:self action:@selector(searchTextUpdated:) forControlEvents:UIControlEventEditingChanged];
}

- (void)viewWillAppear:(BOOL)animated
{
    if ([kShowCorp isEqualToString:kPigglyWiggly]) {
        tableHeaderPigglyWiggly.hidden = NO;
        tableHeaderFarris.hidden = YES;
    } else if ([kShowCorp isEqualToString: kFarris]) {
        tableHeaderPigglyWiggly.hidden = YES;
        tableHeaderFarris.hidden = NO;
    } else {
        tableHeaderPigglyWiggly.hidden = YES;
        tableHeaderFarris.hidden = YES;
    }
    
    if (!self.showShipDates)
    {
        btnSelectShipDates.hidden = YES;
//        lblShipDate1.hidden = YES;
//        lblShipDate2.hidden = YES;
//        lblShipDateCount.hidden = YES;
    }
    //SG: When the view is loaded for the first time (CIOderViewController#loadProductView) backFromCart is NO.
    //When an order cart button is tapped, the view changes to the submit view.
    //After the order has been submitted, this view reappears. At that time backFromCart is YES.
    //If the user, submitted the order, finishOrder will also be YES.
    if (backFromCart && finishOrder) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self finishOrder:nil]; //SG: Displays the view that asks the user for Authorized By, Notes etc information in a modal window.
        });
        backFromCart = NO;
    }
    //SG: backFromCart is set to YES not only when you return from the submit window, but also when you return from the calendar popup.
    // I think this is because backFromCart is being used to decide if the view is being laded for the first time.
    //If backFromCart is YES it means view is being loaded for the first time, so all the initialization stuff like getting the order's customer info,
    // loading vendor's products etc. needs to be done.
    // If backFromCart is YES, it means it is NOT being loaded for the first time, so all the initialization stuff has already been done and need not be repeated.
    if (!backFromCart && _showCustomers){//SG: if view is being loaded for the first time and was asked to present customer selection list. This is usually when a new order is being created.
        
        NSString* url;
        if (self.vendorGroup && ![self.vendorGroup isKindOfClass:[NSNull class]]) {
//            url = [NSString stringWithFormat:@"%@?%@=%@&%@=%@",kDBGETPRODUCTS,kAuthToken,self.authToken,kVendorGroupID,self.vendorGroupId];
            currentVendor = [self.vendorGroup intValue];
            url = [NSString stringWithFormat:@"%@?%@=%@&%@=%d", kDBGETPRODUCTS, kAuthToken, self.authToken, @"vendor_id", currentVendor];
        }else {
            url = [NSString stringWithFormat:@"%@?%@=%@",kDBGETPRODUCTS,kAuthToken,self.authToken];
        }
    
        [self loadProductsForUrl:url withLoadLabel:@"Loading Products..."]; //SG: will load the products and then present the customer selection list if _showCustomers is YES.
        
        navBar.topItem.title = self.title;
    } else if (!backFromCart && !_showCustomers) {
        [self getCustomers]; //SG:gets all customers for this show and then looks for the customer of this order in the returned customers to set self.customer. Also updates self.multiStore. If the order has not been fetched, fetches order for the customer from coredata and updates self.order.
    } else {
        [self.products reloadData];
    }

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow)
                                                 name:UIKeyboardWillShowNotification object:self.view.window];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide)
                                                 name:UIKeyboardDidHideNotification object:self.view.window];

	self.vendorLabel.text = [[SettingsManager sharedManager] lookupSettingByString:@"username"];
    [self.vendorTable reloadData];
}

-(NSMutableDictionary*)createIfDoesntExist:(NSMutableDictionary*) dict orig:(NSDictionary*)odict{
    DLog(@"test this:%@",dict);
    if (dict != nil && [dict objectForKey:kEditablePrice] != nil
        && [dict objectForKey:kEditableVoucher] != nil && [dict objectForKey:kEditableQty] != nil) {
        return nil;
    }
    
    dict = [NSMutableDictionary dictionary];
    
    [dict setValue:[NSNumber numberWithDouble:[[odict objectForKey:kProductShowPrice] doubleValue]] forKey:kEditablePrice];
    [dict setValue:[NSNumber numberWithDouble:[[odict objectForKey:kProductVoucher] doubleValue]] forKey:kEditableVoucher];
    [dict setValue:[NSNumber numberWithInt:0] forKey:kEditableQty];
    
    return dict;
}

-(void)loadProducts {
    NSString* url;
    if (currentVendor == 0) {
        if (self.vendorGroup && ![self.vendorGroup isKindOfClass:[NSNull class]]) {
            url = [NSString stringWithFormat:@"%@?%@=%@&%@=%@", kDBGETPRODUCTS, kAuthToken, self.authToken, kVendorGroupID, self.vendorGroupId];
        }else {
            url = [NSString stringWithFormat:@"%@?%@=%@", kDBGETPRODUCTS, kAuthToken, self.authToken];
        }
        
        [self loadProductsForUrl:url withLoadLabel:@"Loading all Products..."];
        
    } else {
        url = [NSString stringWithFormat:@"%@?%@=%@&%@=%d", kDBGETPRODUCTS, kAuthToken, self.authToken, @"vendor_id", currentVendor];
        [self loadProductsForUrl:url withLoadLabel:@"Loading Products for Selection..."];
    }
}

-(void)loadProductsForUrl:(NSString*)url withLoadLabel:(NSString*)label{
    
    MBProgressHUD* __weak loadProductsHUD = [MBProgressHUD showHUDAddedTo:self.view animated:NO];
    loadProductsHUD.labelText = label;
    [loadProductsHUD show:NO];
    
    DLog(@"Sending %@",url);
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    AFJSONRequestOperation *jsonOp = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
             success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                 
                 self.productData = [JSON mutableCopy];
                 self.resultData = [[NSMutableArray alloc] init];
                 [JSON enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                     int bulletinId = 0;
//                     if ([kShowCorp isEqualToString: kPigglyWiggly]) {
                         if ([obj objectForKey:@"bulletin_id"] != nil && ![[obj objectForKey:@"bulletin_id"] isKindOfClass:[NSNull class]])
                             bulletinId = [[obj objectForKey:@"bulletin_id"] intValue];
//                     } else {
//                         if ([obj objectForKey:@"bulletin"] != nil && ![[obj objectForKey:@"bulletin"] isKindOfClass:[NSNull class]])
//                             bulletinId = [[obj objectForKey:@"bulletin"] intValue];
//                     }
                     if (currentBulletin == 0 || currentBulletin == bulletinId)
                         [self.resultData addObject:[obj mutableCopy]];
                 }];
                 
                 [self.products reloadData];
                 [loadProductsHUD hide:NO];
                 if (_showCustomers && !customerHasBeenSelected) {
                     [self loadCustomersView];
                 } else if (!_showCustomers) {
                     [[NSNotificationCenter defaultCenter] postNotificationName:kDeserializeOrder object:nil];
                 }
                 
             } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                 
                 [[[UIAlertView alloc] initWithTitle:@"Error!" message:error.localizedDescription delegate:nil
                                   cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
                 [loadProductsHUD hide:NO];
             }];

    [jsonOp start];
}

-(void)loadBulletins {
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:kDBGETBULLETINS]];
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
        success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {

            NSMutableDictionary *bulls = [[NSMutableDictionary alloc] init];
            [JSON enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop){
                NSDictionary* dict = (NSDictionary*)obj;
                NSNumber *vendid = [NSNumber numberWithInt:[[dict objectForKey:@"vendor_id"] intValue]];
//                if ([bulls objectForKey:vendorGroup] == nil) {
                if ([bulls objectForKey:vendid] == nil) {
                    NSDictionary *any = [NSDictionary dictionaryWithObjectsAndKeys:@"Any", @"name", [NSNumber numberWithInt:0], @"id", nil];
                    NSMutableArray *arr = [[NSMutableArray alloc] init];
                    [arr addObject:any];
//                    [bulls setObject:arr forKey:vendorGroup];
                    [bulls setObject:arr forKey:vendid];
                }
//                [[bulls objectForKey:vendorGroup] addObject:dict];
                [[bulls objectForKey:vendid] addObject:dict];
            }];
            
            bulletins = [NSDictionary dictionaryWithDictionary:bulls];

            DLog(@"Bulletins: %@", bulletins);
            
            [self showVendorView];
            
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
            bulletins = nil;
            //[self.vendorTable reloadData];
            [self showVendorView];
        }];
    
    [operation start];
}

/**
* SG: This is the Bulletins drop down.
*/
-(void)showVendorView {
    VendorViewController *vendorViewController = [[VendorViewController alloc] initWithNibName:@"VendorViewController" bundle:nil];
    vendorViewController.vendors = [NSArray arrayWithArray:vendorsData];
    
    if (bulletins != nil)
        vendorViewController.bulletins = [NSDictionary dictionaryWithDictionary:bulletins];
    
    vendorViewController.delegate = self;
    
    CGRect frame = vendorDropdown.frame;
    frame = CGRectOffset(frame, 0, 0);
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vendorViewController];
    nav.navigationBarHidden = NO;
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:nil action:nil];
    nav.navigationItem.backBarButtonItem = backButton;

    popoverController = [[UIPopoverController alloc] initWithContentViewController:nav];
    vendorViewController.parentPopover = popoverController;
    [popoverController presentPopoverFromRect:frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

#pragma mark - Customer data

-(void)loadCustomersView {
    CICustomerInfoViewController* ci = [[CICustomerInfoViewController alloc] initWithNibName:@"CICustomerInfoViewController" bundle:nil];
    
    // fire off this call to load customers asynchronously while the view continues to load.
    [self getCustomers];
    
    ci.modalPresentationStyle = UIModalPresentationFormSheet;
    ci.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    ci.delegate = self;
    ci.authToken = self.authToken;
    
    // Handling setting of the customer data via notification now.
    [self presentViewController:ci animated:NO completion:nil];
}

#pragma mark - UITableView Datasource

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)myTableView numberOfRowsInSection:(NSInteger)section {
    if (self.resultData && myTableView == self.products) {
        return [self.resultData count];
    }
//    else if (vendorsData != nil && myTableView == self.vendorTable) {
//        if (!isShowingBulletins)
//            return vendorsData.count;
//        else {
//            NSArray *bulls = [bulletins objectForKey:[NSNumber numberWithInt:currentVendId]];
//            if (bulls != nil) return [bulls count];
//        }
//    }
    return 0;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.products) {
        NSMutableDictionary* dict = [self.resultData objectAtIndex:[indexPath row]];
        NSMutableDictionary* editableDict = [editableData objectForKey:[dict objectForKey:@"id"]];
        BOOL hasQty = NO;
        
        //if you want it to highlight based on qty uncomment this:
        if (multiStore && editableDict != nil && [[editableDict objectForKey:kEditableQty] isKindOfClass:[NSString class]]
            && [[[editableDict objectForKey:kEditableQty] objectFromJSONString] isKindOfClass:[NSDictionary class]]
            && ((NSDictionary*)[[editableDict objectForKey:kEditableQty] objectFromJSONString]).allKeys.count > 0) {
            for(NSNumber* n in [[[editableDict objectForKey:kEditableQty] objectFromJSONString] allObjects]){
                if (n > 0)
                    hasQty = YES;
            }
        }else if (editableDict != nil && [editableDict objectForKey:kEditableQty]&&[[editableDict objectForKey:kEditableQty] isKindOfClass:[NSString class]]
                  && [[editableDict objectForKey:kEditableQty] integerValue] > 0){
            hasQty = YES;
        }else if (editableDict != nil && [editableDict objectForKey:kEditableQty]&&[[editableDict objectForKey:kEditableQty] isKindOfClass:[NSNumber class]]
                  && [[editableDict objectForKey:kEditableQty] intValue] > 0){
            hasQty = YES;
        }else{
            cell.backgroundView = nil;
        }
        
        BOOL hasShipDates = NO;
        NSArray *shipDates = [editableDict objectForKey:kOrderItemShipDates];
        if (shipDates != nil && [shipDates count] > 0) {
            hasShipDates = YES;
        }
        
        NSNumber *zero = [NSNumber numberWithInt:0];
        BOOL isVoucher = [[dict objectForKey:kProductIdx] isEqualToNumber:zero]
                            && [[dict objectForKey:kProductInvtid] isEqualToString:[zero stringValue]];
        if (!isVoucher) {
            if (hasQty && (hasShipDates || (self.showShipDates == NO))) {
                UIView *view = [[UIView alloc] initWithFrame:cell.frame];
                view.backgroundColor = [UIColor colorWithRed:0.722 green:0.871 blue:0.765 alpha:0.75];
                cell.backgroundView = view;
            } else if (hasQty ^ hasShipDates) {
                UIView *view = [[UIView alloc] initWithFrame:cell.frame];
                view.backgroundColor = [UIColor colorWithRed:0.839 green:0.655 blue:0.655 alpha:0.75];
                cell.backgroundView = view;
            }
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)myTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (myTableView == self.products && self.resultData == nil) {
        return nil;
    }
    
    NSMutableDictionary* dict = [self.resultData objectAtIndex:[indexPath row]];
    NSMutableDictionary* editableDict = [editableData objectForKey:[dict objectForKey:@"id"]];
    
    if ([kShowCorp isEqualToString: kPigglyWiggly]) {
        static NSString *CellIdentifier = @"CIProductCell";
        CIProductCell *cell = [myTableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil){
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:CellIdentifier owner:nil options:nil];
            cell = [topLevelObjects objectAtIndex:0];
        }
        
        cell.InvtID.text = [dict objectForKey:@"invtid"];
        cell.descr.text = [dict objectForKey:@"descr"];
        if ([dict objectForKey:kProductShipDate1] != nil && ![[dict objectForKey:kProductShipDate1] isKindOfClass:[NSNull class]]){
            NSDateFormatter* df = [[NSDateFormatter alloc] init];
            [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
            NSDate* date = [[NSDate alloc]init];
            date = [df dateFromString:[dict objectForKey:kProductShipDate1]];
            [df setDateFormat:@"yyyy-MM-dd"];
            cell.shipDate1.text = [df stringFromDate:date];
        }else {
            cell.shipDate1.text = @"";
        }
        if ([dict objectForKey:kProductShipDate2] != nil && ![[dict objectForKey:kProductShipDate2] isKindOfClass:[NSNull class]]){
            NSDateFormatter* df = [[NSDateFormatter alloc] init];
            [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
            NSDate* date = [[NSDate alloc]init];
            date = [df dateFromString:[dict objectForKey:kProductShipDate2]];
            [df setDateFormat:@"yyyy-MM-dd"];
            cell.shipDate2.text = [df stringFromDate:date];
        }else {
            cell.shipDate2.text = @"";
        }
        
        cell.numShipDates.text = ([[editableDict objectForKey:kOrderItemShipDates] isKindOfClass:[NSArray class]]
                                  ? [NSString stringWithFormat:@"%d",((NSArray*)[editableDict objectForKey:kOrderItemShipDates]).count]:@"0");
        if (!multiStore && editableDict != nil && [editableDict objectForKey:kEditableQty] != nil) {
            cell.quantity.text = [[editableDict objectForKey:kEditableQty] stringValue];
        }
        else
            cell.quantity.text = @"0";
        
        if ([dict objectForKey:@"caseqty"] != nil && ![[dict objectForKey:@"caseqty"] isKindOfClass:[NSNull class]])
            cell.CaseQty.text = [dict objectForKey:@"caseqty"];
        else
            cell.CaseQty.text = @"";
        if ([[customer objectForKey:kStores] isKindOfClass:[NSArray class]] && [((NSArray*)[customer objectForKey:kStores]) count] > 0) {
            multiStore = YES;
            cell.qtyBtn.hidden = NO;
            cell.qtyLbl.hidden = YES;
            cell.quantity.hidden = YES;
        }
        if (editableDict != nil && [editableDict objectForKey:kEditableVoucher] != nil) {
            NSNumberFormatter* nf = [[NSNumberFormatter alloc] init];
            nf.formatterBehavior = NSNumberFormatterBehavior10_4;
            nf.maximumFractionDigits = 2;
            nf.minimumFractionDigits = 2;
            nf.minimumIntegerDigits = 1;
            
            cell.voucher.text = [nf stringFromNumber:[editableDict objectForKey:kEditableVoucher]];
            cell.voucherLbl.text = cell.voucher.text;
            cell.voucher.hidden = YES;//PW changes!
        }else if ([dict objectForKey:kProductVoucher] != nil){
            NSNumberFormatter* nf = [[NSNumberFormatter alloc] init];
            nf.formatterBehavior = NSNumberFormatterBehavior10_4;
            nf.maximumFractionDigits = 2;
            nf.minimumFractionDigits = 2;
            nf.minimumIntegerDigits = 1;
            
            cell.voucher.text = [nf stringFromNumber:[NSNumber numberWithDouble:[[dict objectForKey:kProductVoucher] doubleValue]]];
            cell.voucherLbl.text = cell.voucher.text;
            cell.voucher.hidden = YES;//PW changes!
        }else{
            cell.voucher.text = @"0.00";
            cell.voucherLbl.text = cell.voucher.text;
            cell.voucher.hidden = YES;//PW changes!
        }
        
        if (showPrice && editableDict != nil && [editableDict objectForKey:kEditablePrice] != nil) {
            //            cell.price.text = [[self.productPrices objectForKey:[dict objectForKey:@"id"]] stringValue];
            NSNumberFormatter* nf = [[NSNumberFormatter alloc] init];
            nf.formatterBehavior = NSNumberFormatterBehavior10_4;
            nf.maximumFractionDigits = 2;
            nf.minimumFractionDigits = 2;
            nf.minimumIntegerDigits = 1;
            
            cell.price.text = [nf stringFromNumber:[editableDict objectForKey:kEditablePrice]];
            cell.priceLbl.text = cell.price.text;
            cell.price.hidden = YES;//PW changes!
            //NSNumberFormatter* nf = [[NSNumberFormatter alloc] init];
            //[nf setNumberStyle:NSNumberFormatterCurrencyStyle];
            //double price = [[nf numberFromString:cell.price.text] doubleValue];
            //DLog(@"price:%f",price);
        }
        else if ([dict objectForKey:kProductShowPrice] != nil) {
            NSNumberFormatter* nf = [[NSNumberFormatter alloc] init];
            nf.formatterBehavior = NSNumberFormatterBehavior10_4;
            nf.maximumFractionDigits = 2;
            nf.minimumFractionDigits = 2;
            nf.minimumIntegerDigits = 1;
            
            cell.price.text = [nf stringFromNumber:[NSNumber numberWithDouble:[[dict objectForKey:kProductShowPrice] doubleValue]]];
            cell.priceLbl.text = cell.price.text;
            cell.price.hidden = YES;//PW changes!
        }else{
            cell.price.text = @"0.00";
            cell.priceLbl.text = cell.price.text;
            cell.price.hidden = YES;//PW changes!
        }
        
        
        if ([selectedIdx containsObject:[NSNumber numberWithInteger:[indexPath row]]]
            && ![[dict objectForKey:@"invtid"] isEqualToString:@"0"]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        
        //cell.selectionStyle = UITableViewCellSelectionStyleGray;
        cell.delegate = self;
        cell.tag = [indexPath row];
        return (UITableViewCell *)cell;
        
    } else if ([kShowCorp isEqualToString: kFarris]) {
        static NSString *CellIdentifier = @"FarrisProductCell";
        FarrisProductCell *cell = [myTableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil){
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:CellIdentifier owner:nil options:nil];
            cell = [topLevelObjects objectAtIndex:0];
        }
        
        cell.itemNumber.text = [dict objectForKey:@"invtid"];
        [cell setDescription:[dict objectForKey:kProductDescr] withSubtext:[dict objectForKey:kProductDescr2]];
        cell.min.text = [[dict objectForKey:@"min"] stringValue];
        if (editableDict != nil && [editableDict objectForKey:kEditableQty] != nil) {
            cell.quantity.text = [[editableDict objectForKey:kEditableQty] stringValue];
        } else {
            cell.quantity.text = @"0";
        }
        
        NSNumberFormatter* nf = [[NSNumberFormatter alloc] init];
        nf.formatterBehavior = NSNumberFormatterBehavior10_4;
        nf.maximumFractionDigits = 2;
        nf.minimumFractionDigits = 2;
        nf.minimumIntegerDigits = 1;
        
        cell.regPrice.text = [nf stringFromNumber:[NSNumber numberWithDouble:[[dict objectForKey:kProductRegPrc] doubleValue]]];
        cell.showPrice.text = [nf stringFromNumber:[NSNumber numberWithDouble:[[dict objectForKey:kProductShowPrice] doubleValue]]];
        cell.delegate = self;
        cell.tag = [indexPath row];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryType = UITableViewCellAccessoryNone;
        return (UITableViewCell *)cell;
    }
    
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.products) {
        NSDictionary* dict = [self.resultData objectAtIndex:[indexPath row]];
        DLog(@"product details:%@", dict);
        if ([selectedIdx containsObject:[NSNumber numberWithInteger:[indexPath row]]]) {
            [selectedIdx removeObject:[NSNumber numberWithInteger:[indexPath row]]];
            //            [[tableView cellForRowAtIndexPath:indexPath] setSelected:NO];
            [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryNone;
        }else{
            [selectedIdx addObject:[NSNumber numberWithInteger:[indexPath row]]];
            //            [[tableView cellForRowAtIndexPath:indexPath] setSelected:YES];
            if (![[dict objectForKey:@"invtid"] isEqualToString:@"0"] && self.showShipDates) {
                [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
            }
        }
    }
//    else if (tableView == self.vendorTable) {
//        UITableViewCell* cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
//        if (!isShowingBulletins) {
//            [selectedIdx removeAllObjects];
//            currentVendor = cell.tag;
//            if (currentVendor != 0) {
//                NSUInteger index = [vendorsData indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
//                    int _id = [[obj objectForKey:@"id"] intValue];
//                    *stop = currentVendor == _id;
//                    return *stop;
//                }];
//                
//                if (index != NSNotFound)
//                    currentVendId = [[[vendorsData objectAtIndex:index] objectForKey:@"vendid"] intValue];
//                
//                if (bulletins != nil && [[bulletins allKeys] count] > 0) {
//                    [self selectBulletin];
//                }
//            } else {
//                [self dismissVendorTouched:nil];
//                currentVendId = 0;
//                currentBulletin = 0;
//                [self loadProducts];
//            }
//            
//            if (cell.tag != currentVendor) {
//                _order.vendor_id = currentVendor;
//                [[CoreDataUtil sharedManager] saveObjects];
//            }
//            
//            NSDictionary* details = [vendorsData objectAtIndex:[indexPath row]];
//            self.vendorLabel.text = [NSString stringWithFormat:@"%@ - %@", [details objectForKey:kVendorVendID],
//                                     [details objectForKey:kVendorUsername]];
//        } else {
//            isShowingBulletins = NO;
//            [self dismissVendorTouched:nil];
//            currentBulletin = cell.tag;
//            [self loadProducts];
//        }
//    }
}

#pragma mark - Other

-(void)Cancel{
   
	if (isInitialized && _order.orderId == 0) {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Cancel Order?"
                                  message:@"This will cancel the current order."
                                  delegate:self
                                  cancelButtonTitle:@"Cancel"
                                  otherButtonTitles:@"OK", nil];
        
        [alertView show];
    } else {
//        [self dismissViewControllerAnimated:YES completion:nil];
        [self Return];
    }
}

- (void)cancelNewOrder {
    [self dismissViewControllerAnimated:YES completion:^{
        NSLog(@"%@ - %@", self, self.delegate);
        [self.delegate Return];
    }];
}

-(IBAction)Cancel:(id)sender {
    [self Cancel];
}

- (void)createNewOrderForCustomer:(NSString *)customerId andStore:(NSString *)custId
{
    NSManagedObjectContext *context = self.managedObjectContext;
    _order = [NSEntityDescription insertNewObjectForEntityForName:@"Order" inManagedObjectContext:context];
    [_order setBillname:self.customerLabel.text];
    [_order setCustomer_id:customerId];
    [_order setCustid:custId];
    [_order setMultiStore:multiStore];
    [_order setStatus:@"pending"];
    [_order setCreated_at:[NSDate timeIntervalSinceReferenceDate]];
    [_order setVendorGroup:vendorGroup];
    [_order setVendorGroupId:self.vendorGroupId];
    [_order setVendor_id:currentVendor];
    NSError *error = nil;
    BOOL success = [context save:&error];
    if (!success) {
        DLog(@"Error saving new order: %@", [error localizedDescription]);
        NSString *msg = [NSString stringWithFormat:@"Error saving new order: %@", [error localizedDescription]];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
    }
}

-(void)loadProductsForVendor {
    self.vendorGroup = _order.vendorGroup;
    self.vendorGroupId = _order.vendorGroupId;
    currentVendor = _order.vendor_id;
   
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deserializeOrder) name:kDeserializeOrder object:nil];
    [self loadProducts];
}

- (void)deserializeOrder
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kDeserializeOrder object:nil];
    NSDateFormatter* df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
    
    NSNumberFormatter* nf = [[NSNumberFormatter alloc] init];
    nf.formatterBehavior = NSNumberFormatterBehavior10_4;
    nf.maximumFractionDigits = 2;
    nf.minimumFractionDigits = 2;
    nf.minimumIntegerDigits = 1;
    
    self.totalCost.text = [nf stringFromNumber:[NSNumber numberWithDouble:_order.totalCost]];
    
    for (Cart *cart in _order.carts) {
        NSMutableDictionary *item = [[NSMutableDictionary alloc] init];
        [item setObject:cart.category forKey:@"category"];
        [item setObject:[NSString stringWithFormat:@"%d", cart.adv] forKey:kProductAdv];
        [item setObject:cart.caseqty forKey:kProductCaseQty];
        [item setObject:cart.company forKey:kVendorCompany];
        [item setObject:cart.created_at forKey:@"created_at"];
        [item setObject:cart.descr forKey:kProductDescr];
        
        if ([kShowCorp isEqualToString: kFarris])
            [item setObject:cart.descr2 forKey:kProductDescr2];
        
        [item setObject:[NSString stringWithFormat:@"%d", cart.dirship] forKey:kProductDirShip];
        [item setObject:[NSNumber numberWithFloat:cart.discount] forKey:kProductDiscount];
        [item setObject:[NSNumber numberWithFloat:cart.editablePrice] forKey:kEditablePrice];
        
        if (!_order.multiStore) {
            NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
            [f setFormatterBehavior:NSNumberFormatterBehavior10_4];
            [item setObject:[f numberFromString:cart.editableQty] forKey:kEditableQty];
        } else {
            [item setObject:cart.editableQty forKey:kEditableQty];
        }
        [item setObject:[NSNumber numberWithFloat:cart.editableVoucher] forKey:kEditableVoucher];
        [item setObject:[NSNumber numberWithInt:cart.cartId] forKey:@"id"];
        [item setObject:[NSNumber numberWithInt:cart.idx] forKey:kProductIdx];
        [item setObject:[NSNumber numberWithInt:cart.import_id] forKey:kVendorImportID];
        [item setObject:[NSString stringWithFormat:@"%@", cart.invtid] forKey:kProductInvtid];
        [item setObject:cart.initial_show == nil ? @"" : cart.initial_show forKey:kVendorInitialShow];
        [item setObject:cart.linenbr == nil ? @"" : cart.linenbr forKey:kProductLineNbr];
        [item setObject:[NSString stringWithFormat:@"%d", cart.new] forKey:kProductNew];
        [item setObject:cart.partnbr == nil ? @"" : cart.partnbr forKey:kProductPartNbr];
        [item setObject:cart.regprc == nil ? @"" : cart.regprc forKey:kProductRegPrc];
        [item setObject:cart.shipdate1 == nil ? @"" : cart.shipdate1 forKey:kProductShipDate1];
        [item setObject:cart.shipdate2 == nil ? @"" : cart.shipdate2 forKey:kProductShipDate2];
        
        NSMutableArray *shipdates = [[NSMutableArray alloc] initWithCapacity:[cart.shipdates count]];
        if ([cart.shipdates count] > 0) {
            for (ShipDate *sd in cart.shipdates) {
                //[shipdates addObject:[df stringFromDate:[NSDate dateWithTimeIntervalSinceReferenceDate:sd.shipdate]]];
                [shipdates addObject:[NSDate dateWithTimeIntervalSinceReferenceDate:sd.shipdate]];
            }

            [item setObject:shipdates forKey:kOrderItemShipDates];
        }
        [item setObject:cart.showprc forKey:kProductShowPrice];
        [item setObject:cart.unique_product_id forKey:kProductUniqueId];
        [item setObject:cart.uom == nil ? @"" : cart.uom forKey:kProductUom];
        [item setObject:cart.updated_at == nil ? @"" : cart.updated_at forKey:kVendorUpdatedAt];
        [item setObject:cart.vendid forKey:kVendorVendID];
        [item setObject:[NSNumber numberWithInt:cart.vendor_id] forKey:@"vendor_id"];
        [item setObject:cart.voucher forKey:kProductVoucher];
        
        if (cart.orderLineItem_id > 0)
            [item setObject:[NSNumber numberWithInt:cart.orderLineItem_id] forKey:kOrderLineItemId];
        
        [self.productCart setObject:item forKey:[NSNumber numberWithInt:cart.cartId]];
        
        NSString *invt_id = cart.invtid;
        NSUInteger index = [self.resultData indexOfObjectPassingTest:^BOOL(id dictionary, NSUInteger idx, BOOL *stop) {
            //NSNumber *prodId = [NSNumber numberWithInt:[[dictionary objectForKey:kProductInvtid] intValue]];
            NSString *prodId = [dictionary objectForKey:kProductInvtid];
//            *stop = [[dictionary objectForKey:kProductInvtid] isEqualToNumber:invt_id];
            *stop = [prodId isEqualToString:invt_id];
            return *stop;
        }];
        if (index != NSNotFound) {
            NSMutableDictionary* dict = [self.resultData objectAtIndex:index];
            NSMutableDictionary* editableDict = [editableData objectForKey:[dict objectForKey:@"id"]];
            NSMutableDictionary* edict = [self createIfDoesntExist:editableDict orig:dict];
            
            if (edict == nil) {
                edict = editableDict;
            }
            
            [edict setValue:[item objectForKey:kEditablePrice] forKey:kEditablePrice];
            [edict setValue:[item objectForKey:kEditableQty] forKey:kEditableQty];
            [edict setValue:[item objectForKey:kEditableVoucher] forKey:kEditableVoucher];
            if ([shipdates count] > 0){
                [edict setObject:shipdates forKey:kOrderItemShipDates];
            }
            
            [editableData setObject:edict forKey:[dict objectForKey:@"id"]];
        }
    }
    
    [self.products reloadData];
    isInitialized = YES;
}

-(void)setCustomerInfo:(NSDictionary*)info
{
    self.customer = [info copy];
    DLog(@"set customerinfo:%@",self.customer);

    if ([self.customer objectForKey:kBillName] != nil) {
        self.customerLabel.text = [self.customer objectForKey:kBillName];
    }
    
    multiStore = [[customer objectForKey:kStores] isKindOfClass:[NSArray class]]
                    && [((NSArray*)[customer objectForKey:kStores]) count] > 0;

    [self.products reloadData];
    
    customerHasBeenSelected = YES;
    NSString *custId = [self.customer objectForKey:@"custid"];
    NSString *customerId = [[self.customer objectForKey:@"id"] stringValue];
    
    if (!isInitialized) {
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        [fetchRequest setEntity:[NSEntityDescription entityForName:@"Order" inManagedObjectContext:managedObjectContext]];

        
//        NSString *vg = [vendorGroup isEmpty] ? @"" : vendorGroup;
//        NSString *vg = [self.vendorGroupId isEmpty] ? @"" : self.vendorGroupId;

        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(customer_id ==[c] %@) AND (custid ==[c] %@) AND (vendorGroup ==[c] %@)", customerId, custId, self.vendorGroup];
        
//        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(customer_id ==[c] %@) AND (custid ==[c] %@)", customerId, custId];
        
        [fetchRequest setPredicate:predicate];

        NSArray *keys = [NSArray arrayWithObjects:@"carts", @"carts.shipdates", nil];
        [fetchRequest setRelationshipKeyPathsForPrefetching:keys];
        [fetchRequest setReturnsObjectsAsFaults:NO];
        NSError *error = nil;
        NSArray *fetchedObjects = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
        if (error == nil && fetchedObjects != nil && [fetchedObjects count] > 0) {
            _order = [fetchedObjects objectAtIndex:0];
        }
        
        if (_order != nil)
        {
            if (_showCustomers) {
                NSString *useExisting = @"Use Existing";
                NSString *createNew = @"Create New";
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Confirm" message:@"A pending order exists for this customer. Would you like to use the existing order or delete it and start a new order?"
                                                               delegate:nil cancelButtonTitle:useExisting otherButtonTitles:createNew, nil];
                [UIAlertViewDelegateWithBlock showAlertView:alert withCallBack:^(NSInteger buttonIndex) {
                    
                    if (buttonIndex == 0) {
                        _showCustomers = false;
                        [self loadProductsForVendor];
                    } else {
                        [[CoreDataUtil sharedManager] deleteObject:_order];
                        _order = nil;
                        [self createNewOrderForCustomer:customerId andStore:custId];
                    }
                    
                }];
            } else {
                [self loadProductsForVendor];
            }
        } else {
            [self createNewOrderForCustomer:customerId andStore:custId];
            isInitialized = YES;
        }
    }
    else {
        if (_order.custid != custId) {
            [_order setCustid:custId];
            [_order setCustomer_id:customerId];
            [_order setBillname:[self.customer objectForKey:kBillName]];
            [_order setMultiStore:multiStore];
        }
                                 
        [[CoreDataUtil sharedManager] saveObjects];
    }
}

-(void)setSelectedPrinter:(NSString *)printer {
    [popoverController dismissPopoverAnimated:YES];
    [[SettingsManager sharedManager] saveSetting:@"printer" value:printer];
    _printStationId = [[[_availablePrinters objectForKey:printer] objectForKey:@"id"] intValue];
    [self sendOrderToServer:YES asPending:NO beforeCart:NO];
}

-(void)selectPrintStation {
    PrinterSelectionViewController *psvc = [[PrinterSelectionViewController alloc] initWithNibName:@"PrinterSelectionViewController" bundle:nil];
    psvc.title = @"Available Printers";
    NSArray *keys = [[[_availablePrinters allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] copy];
    psvc.availablePrinters = [NSArray arrayWithArray:keys];
    psvc.delegate = self;
    
    CGRect frame = cartButton.frame;
    frame = CGRectOffset(frame, 0, 0);
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:psvc];
    popoverController = [[UIPopoverController alloc] initWithContentViewController:nav];
    [popoverController presentPopoverFromRect:frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (IBAction)calcOrder:(id)sender {
    [self sendOrderToServer:NO asPending:YES beforeCart:NO];
}

- (IBAction)submit:(id)sender {
    
    if (self.allowPrinting) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Confirm" message:@"Do you want to print the order after submission?"
                                                       delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@"Yes", @"No", nil];
        [UIAlertViewDelegateWithBlock showAlertView:alert withCallBack:^(NSInteger buttonIndex) {
            
            if (buttonIndex != 0) {
                if (buttonIndex == 1) { // YES
                    if (_printStationId == 0) {
                        if (_availablePrinters == nil) {
                            NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:kDBGETPRINTERS]];
                            AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                                
                                DLog(@"printers: %@", JSON);
                                if (JSON != nil && [JSON isKindOfClass:[NSArray class]] && [JSON count] > 0) {
                                    NSMutableDictionary *printStations = [[NSMutableDictionary alloc] initWithCapacity:[JSON count]];
                                    for (NSDictionary *printer in JSON) {
                                        [printStations setObject:printer forKey:[printer objectForKey:@"name"]];
                                    }
                                    
                                    _availablePrinters = [NSDictionary dictionaryWithDictionary:printStations];
                                    [self selectPrintStation];
                                }
                                
                            } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                                
                                NSString *msg = [NSString stringWithFormat:@"Unable to load available printers. Order will not be printed. %@", [error localizedDescription]];
                                [[[UIAlertView alloc] initWithTitle:@"No Printers" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
                            }];
                            
                            [operation start];
                        } else {
                            [self selectPrintStation];
                        }
                        
                    } else {
                        [self sendOrderToServer:YES asPending:NO beforeCart:NO];
                    }
                } else { // NO
                    [self sendOrderToServer:NO asPending:NO beforeCart:NO];
                }
            }
        }];
    } else {
        [self sendOrderToServer:NO asPending:NO beforeCart:NO];
    }
}

-(void)sendOrderToServer:(BOOL)printThisOrder asPending:(BOOL)asPending beforeCart:(BOOL)beforeCart {
    MBProgressHUD* submit = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    if (asPending)
        submit.labelText = @"Calculating order total...";
    else
        submit.labelText = @"Submitting order...";
    [submit show:YES];
    
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    NSArray* keys = self.productCart.allKeys;

    if ([self.productCart.allKeys count] == 0) {
        [[[UIAlertView alloc] initWithTitle:@"Error!" message:@"Please add at least one product to the cart before continuing." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
        [submit hide:YES];
        return;
    }

    if (![self orderReadyForSubmission]) {
        [submit hide:YES];
        return;
    }
    
    if (_order.orderId == 0) {
        for (NSNumber* i in keys) {
            NSDictionary* dict = [self.productCart objectForKey:i];
            NSString* productID = [i stringValue];//[[self.productData objectAtIndex:] objectForKey:@"id"];
            NSString *myId = [dict objectForKey:kOrderLineItemId] != nil ? [[dict objectForKey:kOrderLineItemId] stringValue] : @"";
            NSInteger num = 0;
            if (!multiStore) {
                DLog(@"!multiStore:%@",[dict objectForKey:kEditableQty]);
                num = [[dict objectForKey:kEditableQty] integerValue];
            }else{
                NSMutableDictionary* qty = [[dict objectForKey:kEditableQty] objectFromJSONString];
                for( NSString* n in qty.allKeys){
                    int j =[[qty objectForKey:n] intValue];
                    if (j > num) {
                        num = j;
                        if (num > 0) {
                            break;
                        }
                    }
                }
            }
            
            DLog(@"orig yo q:%@=%d with %@ and %@",[dict objectForKey:kEditableQty], num,[dict objectForKey:kEditablePrice],[dict objectForKey:kEditableVoucher]);
            if (num > 0) {
                if ([kShowCorp isEqualToString:kPigglyWiggly]) {
                    NSMutableArray* strs = [NSMutableArray array];
                    NSArray* dates = [dict objectForKey:kOrderItemShipDates];
                    if ([dates count] > 0) {
                        NSDateFormatter* df = [[NSDateFormatter alloc] init];
                        [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
                        for(int i = 0; i < dates.count; i++){
                            NSString* str = [df stringFromDate:[dates objectAtIndex:i]];
                            [strs addObject:str];
                        }
                    }

                    if ([strs count] > 0 || itemIsVoucher(dict)) {
                        NSString *lineItemId = [dict objectForKey:kOrderLineItemId] ? [[dict objectForKey:kOrderLineItemId] stringValue] : @"";
                        NSString *ePrice = [[dict objectForKey:kEditablePrice] stringValue];
                        NSString *eVoucher = [[dict objectForKey:kEditableVoucher] stringValue];
                        NSDictionary* proDict = [NSDictionary dictionaryWithObjectsAndKeys:lineItemId, kID, productID, kOrderItemID,
                                                 [dict objectForKey:kEditableQty], kOrderItemNum, ePrice, kOrderItemPRICE,
                                                 eVoucher, kOrderItemVoucher, strs, kOrderItemShipDates, nil];
                        [arr addObject:(id)proDict];
                    }
                } else {
                    NSString *ePrice = [[dict objectForKey:kEditablePrice] stringValue];
                    NSString *eVoucher = [[dict objectForKey:kEditableVoucher] stringValue];
                    NSDictionary *proDict;
                    
                    if ([myId isEqualToString:@""]) {
                        proDict = [NSDictionary dictionaryWithObjectsAndKeys:productID, kOrderItemID, [[dict objectForKey:kEditableQty] stringValue], kOrderItemNum, ePrice,kOrderItemPRICE, eVoucher, kOrderItemVoucher, nil];
                    }
                    else {
                        proDict = [NSDictionary dictionaryWithObjectsAndKeys:productID, kOrderItemID, myId, kID, [[dict objectForKey:kEditableQty] stringValue], kOrderItemNum, ePrice,kOrderItemPRICE, eVoucher, kOrderItemVoucher, nil];
                    }
                    [arr addObject:(id)proDict];
                }
            }
        }
    } else {
        for (NSNumber* i in keys) {
            NSMutableArray *strs = nil;
            NSDictionary* dict = [self.productCart objectForKey:i];
            if ([kShowCorp isEqualToString:kPigglyWiggly]) {
                strs = [NSMutableArray array];
                NSArray* dates = [dict objectForKey:kOrderItemShipDates];
                if ([dates count] > 0) {
                    NSDateFormatter* df = [[NSDateFormatter alloc] init];
                    [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
                    for(int i = 0; i < dates.count; i++){
                        NSString* str = [df stringFromDate:[dates objectAtIndex:i]];
                        [strs addObject:str];
                    }
                }
            }
            NSString* productID = [i stringValue];//[[self.productData objectAtIndex:] objectForKey:@"id"];
            NSString *myId = [dict objectForKey:kOrderLineItemId] != nil ? [[dict objectForKey:kOrderLineItemId] stringValue] : @"";
            NSString *ePrice = [[dict objectForKey:kEditablePrice] stringValue];
            NSString *eVoucher = [[dict objectForKey:kEditableVoucher] stringValue];
            NSDictionary *proDict;
            if ([kShowCorp isEqualToString:kPigglyWiggly]) {
                if (![myId isEqualToString:@""])
                    proDict = [NSDictionary dictionaryWithObjectsAndKeys:productID, kOrderItemID, myId, kID,
                                         (multiStore ? [dict objectForKey:kEditableQty] : [[dict objectForKey:kEditableQty] stringValue]), kOrderItemNum, ePrice, kOrderItemPRICE,
                                         eVoucher, kOrderItemVoucher, strs, kOrderItemShipDates, nil];
                else
                    proDict = [NSDictionary dictionaryWithObjectsAndKeys:productID, kOrderItemID, (multiStore ? [dict objectForKey:kEditableQty] : [[dict objectForKey:kEditableQty] stringValue]), kOrderItemNum,
                               ePrice, kOrderItemPRICE, strs, kOrderItemShipDates, nil];
            }
            else {
                if (![myId isEqualToString:@""])
                    proDict = [NSDictionary dictionaryWithObjectsAndKeys:productID, kOrderItemID, myId, kID, (multiStore ? [dict objectForKey:kEditableQty] : [[dict objectForKey:kEditableQty] stringValue]), kOrderItemNum, ePrice, kOrderItemPRICE, eVoucher, kOrderItemVoucher, nil];
                else
                    proDict = [NSDictionary dictionaryWithObjectsAndKeys:productID, kOrderItemID, (multiStore ? [dict objectForKey:kEditableQty] : [[dict objectForKey:kEditableQty] stringValue]), kOrderItemNum, ePrice, kOrderItemPRICE, nil];
            }
            [arr addObject:(id)proDict];
        }
    }
    
    [arr removeObjectIdenticalTo:nil];
    
    DLog(@"array:%@",arr);
    
    if (self.customer == nil) {
        return;
    }
    
    NSString *orderStatus = asPending ? @"pending" : @"complete";
    NSMutableDictionary* newOrder;
    
    if (!asPending) {
        NSString *_notes = [self.customer objectForKey:kNotes];
        if (_notes == nil || [_notes isEqualToString:@""])
            _notes = @"";
        NSString *_shipFlag = [self.customer objectForKey:kShipFlag];
        if (_shipFlag == nil)
            _shipFlag = @"0";
        NSString *shipNotes = [self.customer objectForKey:kShipNotes];
        shipNotes = (shipNotes == nil || [shipNotes isKindOfClass:[NSNull class]])?@"":shipNotes;

        newOrder = [NSMutableDictionary dictionaryWithObjectsAndKeys:[self.customer objectForKey:@"id"], kOrderCustID,
             _notes, kNotes, shipNotes, kShipNotes, [self.customer objectForKey:kAuthorizedBy], kAuthorizedBy,
             _shipFlag, kShipFlag, orderStatus, kOrderStatus,
             arr, kOrderItems, nil];
    } else {
        newOrder = [NSMutableDictionary dictionaryWithObjectsAndKeys:[self.customer objectForKey:@"id"], kOrderCustID, orderStatus, kOrderStatus, arr, kOrderItems, nil];
    }
    if (printThisOrder) {
        [newOrder setObject:@"TRUE" forKey:@"print"];
        [newOrder setObject:[NSNumber numberWithInt:_printStationId] forKey:@"printer"];
    }
    
    NSDictionary* final = [NSDictionary dictionaryWithObjectsAndKeys:newOrder,kOrder, nil];
 
    NSString *url;
    if (_order.orderId == 0) {
        url = [NSString stringWithFormat:@"%@?%@=%@",kDBORDER,kAuthToken,self.authToken];
    } else {
        url = [NSString stringWithFormat:@"%@?%@=%@",[NSString stringWithFormat:kDBORDEREDITS(_order.orderId)],kAuthToken,self.authToken];
    }
    DLog(@"final JSON:%@\nURL:%@",[final JSONString],url);
    
    AFHTTPClient *client = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:url]];
    [client setParameterEncoding:AFJSONParameterEncoding];
    
    NSString *method = @"POST";
    if (_order.orderId > 0)
        method = @"PUT";
    
    NSMutableURLRequest *request = [client requestWithMethod:method path:nil parameters:final];
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
        success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
            
            [submit hide:YES];
            
            DLog(@"status = %@", [JSON valueForKey:@"status"]);
            DLog(@"JSON = %@", JSON);
            
            if (asPending) {
                NSNumber *totalCost = [NSNumber numberWithDouble:[[JSON valueForKey:@"total"] doubleValue]];
                NSNumberFormatter* nf = [[NSNumberFormatter alloc] init];
                nf.formatterBehavior = NSNumberFormatterBehavior10_4;
                nf.maximumFractionDigits = 2;
                nf.minimumFractionDigits = 2;
                nf.minimumIntegerDigits = 1;
                
                double grossTotal = 0.0;
                int orderId = [[JSON objectForKey:kOrderId] intValue];
                NSArray *lineItems = [JSON objectForKey:@"line_items"];
                self.discountItems = [NSMutableDictionary dictionary];
                for (int i = 0; i < [lineItems count]; i++) {
                    NSDictionary *details = [[lineItems objectAtIndex:i] mutableCopy];
                    NSString *category = [details objectForKey:@"category"];
                    if ([category isEqualToString:@"standard"]) {
                        int productId = [[details objectForKey:@"product_id"] intValue];
                        int lineItemId = [[details objectForKey:kID] intValue];
                        Cart *cartItem = [self findCartForId:productId];
                        if (cartItem != nil) {
                            cartItem.orderLineItem_id = lineItemId;
                        }
                        
                        NSMutableDictionary *dict = [self.productCart objectForKey:[NSNumber numberWithInt:productId]];
                        [dict setObject:[NSNumber numberWithInt:lineItemId] forKey:kOrderLineItemId];
                        
                        int qty = [[dict objectForKey:kEditableQty] intValue];
                        double price = [[dict objectForKey:kEditablePrice] doubleValue];
                        grossTotal += qty * price;
                    } else if ([category isEqualToString:@"discount"]) {
                        [self.discountItems setObject:details forKey:[details objectForKey:@"id"]];
//                        discountTotal += [details objectForKey:@"]
                    }
                }
                
//                self.totalCost.text = [nf stringFromNumber:totalCost];
                self.totalCost.text = [nf stringFromNumber:[NSNumber numberWithDouble:grossTotal]];
                self.totalCost.textColor = [UIColor blackColor];

                [_order setOrderId:orderId];
                [_order setTotalCost:[totalCost doubleValue]];
                [[CoreDataUtil sharedManager] saveObjects];
                
                if (beforeCart)
                    [[NSNotificationCenter defaultCenter] postNotificationName:kLaunchCart object:nil];

            } else {
                [[CoreDataUtil sharedManager] deleteObject:_order];
                _order = nil;
                [self Return];
            }
            
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
            
            [submit hide:YES];
            NSString *errorMsg = [NSString stringWithFormat:@"There was an error submitting the order. %@", error.localizedDescription];
            [[[UIAlertView alloc] initWithTitle:@"Error!" message:errorMsg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
            
        }];
    
    [operation start];
}

-(void)Return {
    [self dismissViewControllerAnimated:YES completion:^{
        if (self.delegate != nil) {
            [self.delegate Return];
        }
    }];
}

BOOL itemIsVoucher(NSDictionary *dict);

BOOL itemIsVoucher(NSDictionary *dict) {
    int idx = [[dict objectForKey:kProductIdx] intValue];
    //int invtid = [[dict objectForKey:kProductInvtid] intValue];
    NSString *invtId = [dict objectForKey:kProductInvtid];
    
    return idx == 0 && ([invtId isEmpty] || [invtId isEqualToString:@"0"]);
}

-(BOOL)orderReadyForSubmission {
    NSArray* keys = self.productCart.allKeys;
    for (NSString* i in keys) {
        NSDictionary* dict = [self.productCart objectForKey:i];
        
        BOOL hasQty = NO;
        NSInteger num = 0;
        if (!multiStore) {
            num = [[dict objectForKey:kEditableQty] integerValue];
        }else{
            NSMutableDictionary* qty = [[dict objectForKey:kEditableQty] objectFromJSONString];
            for( NSString* n in qty.allKeys){
                int j =[[qty objectForKey:n] intValue];
                if (j > num) {
                    num = j;
                    if (num > 0) {
                        break;
                    }
                }
            }
        }
        
        BOOL hasShipDates = NO;
        if (num > 0) {
            hasQty = YES;
            NSArray* dates = [dict objectForKey:kOrderItemShipDates];
            NSMutableArray* strs = [NSMutableArray array];
            
            NSDateFormatter* df = [[NSDateFormatter alloc] init];
            [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
            for(int i = 0; i < dates.count; i++){
                NSString* str = [df stringFromDate:[dates objectAtIndex:i]];
                [strs addObject:str];
            }
            
            if ([strs count] > 0) {
                hasShipDates = YES;
            }
        }
        
        if (!itemIsVoucher(dict) && (!hasQty || !(hasShipDates || (self.showShipDates == NO)))) {
            [[[UIAlertView alloc] initWithTitle:@"Missing Data" message:@"All items in the cart must have a quantity and ship date(s) before the order can be submitted. Check cart items and try again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
            return NO;
        }
    }
    
    return YES;
}

//SG: This method loads the view that is displayed after you Submit an order. It prompts the user for information like Authorized By and Notes.
- (IBAction)finishOrder:(id)sender {
    if ([self orderReadyForSubmission])
    {
        if ([[self.productCart allKeys] count] <= 0) {
            [[[UIAlertView alloc] initWithTitle:@"Cart Empty." message:@"You don't have anything in your cart!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
            return;
        }
        CIFinalCustomerInfoViewController* ci = [[CIFinalCustomerInfoViewController alloc] initWithNibName:@"CIFinalCustomerInfoViewController" bundle:nil];
        ci.modalPresentationStyle = UIModalPresentationFormSheet;
        ci.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        ci.delegate = self;
        [self presentViewController:ci animated:YES completion:nil];
    }
}

/**
* SG: This method is called when user taps the cart button.
*/
- (IBAction)reviewCart:(id)sender {
    [self.hiddenTxt becomeFirstResponder];
    [self.hiddenTxt resignFirstResponder];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(launchCart) name:kLaunchCart object:nil];
    [self sendOrderToServer:NO asPending:YES beforeCart:YES];
}

-(void)launchCart {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kLaunchCart object:nil];
    CICartViewController* cart = [[CICartViewController alloc] initWithNibName:@"CICartViewController" bundle:nil];
    cart.delegate = self;
    cart.productData = [NSMutableDictionary dictionaryWithDictionary:self.productCart];
    cart.productCart = [NSMutableDictionary dictionaryWithDictionary:self.productCart];
    cart.discountItems = [NSMutableDictionary dictionaryWithDictionary:self.discountItems];
    cart.multiStore = multiStore;
    cart.allowPrinting = self.allowPrinting;
    cart.showShipDates = self.showShipDates;
    cart.modalPresentationStyle = UIModalPresentationFullScreen;
    //    cart.modalTransitionStyle = UIModalTransitionStylePartialCurl;
    cart.customer = self.customer;
    [self presentViewController:cart  animated:YES completion:nil];
}

- (IBAction)vendorTouch:(id)sender {
    if (!self.vendorView.hidden && !self.dismissVendor.hidden) {
        self.vendorView.hidden = YES;
        self.dismissVendor.hidden = YES;
        return;
    }
//    [vendorNav setItems:[NSArray array]];
    [selectedIdx removeAllObjects];
    
    if (vendorsData == nil) {
        MBProgressHUD* venderLoading = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        venderLoading.labelText = @"Loading vendors from your vendor group...";
        [venderLoading show:YES];
        
        if (self.vendorGroup && ![self.vendorGroup isKindOfClass:[NSNull class]]) {
            
//            NSString* url = [NSString stringWithFormat:@"%@&%@=%@",kDBGETVENDORSWithVG(self.vendorGroup),kAuthToken,self.authToken];
            NSString* url = [NSString stringWithFormat:@"%@&%@=%@",kDBGETVENDORSWithVG(self.vendorGroupId),kAuthToken,self.authToken];
            NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
            AFJSONRequestOperation *jsonOp = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                 success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {

                     NSArray *results = [NSArray arrayWithArray:JSON];
                     if (results == nil || [results isKindOfClass:[NSNull class]] || results.count == 0 || [results objectAtIndex:0] == nil || [[results objectAtIndex:0] objectForKey:@"vendors"] == nil) {
                         [venderLoading hide:YES];
                         [[[UIAlertView alloc] initWithTitle:@"Error!" message:@"Problem loading vendors! If this problem persists please notify Convention Innovations!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
                         return;
                     }
                     
                     NSArray* vendors = [[results objectAtIndex:0] objectForKey:@"vendors"];
                     NSMutableArray* vs = [NSMutableArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:@"Any",@"name",@"0",@"id", nil], nil];
                     
                     [vendors enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop){
                         NSDictionary* dict = (NSDictionary*)obj;
                         [vs addObject:dict];
                     }];
                     
                     vendorsData = [vs mutableCopy];
                     [venderLoading hide:YES];
                     [self loadBulletins];
                     
                 } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {

                     [[[UIAlertView alloc] initWithTitle:@"Error!"
                                 message:[NSString stringWithFormat:@"Got error retrieving vendors for vendor group:%@", error.localizedDescription]
                                    delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
                     
                     vendorsData = [NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:@"Any",@"name",@"0",@"id", nil], nil];
                     [venderLoading hide:YES];
                     //[self.vendorTable reloadData];
                     [self showVendorView];
                 }];
            
            [jsonOp start];
            
        }else{
            [venderLoading hide:YES];
            vendorsData = [NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:@"Any",@"name",@"0",@"id", nil], nil];
            //[self.vendorTable reloadData];
            [self showVendorView];
        }
    } else {
        //[self.vendorTable reloadData];
        [self showVendorView];
    }
    
    //self.vendorView.hidden = NO;
    //self.dismissVendor.hidden = NO;
}

- (IBAction)dismissVendorTouched:(id)sender {
    self.vendorView.hidden = YES;
    self.dismissVendor.hidden = YES;
    isShowingBulletins = NO;
}

- (IBAction)shipdatesTouched:(id)sender {
    [self.view endEditing:YES];
    
    if (selectedIdx.count <= 0) {
        [[[UIAlertView alloc]initWithTitle:@"Oops" message:@"Please select the item(s) you want to set dates for first"
                                  delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
        return;
    }
    
    MBProgressHUD* thinking = [MBProgressHUD showHUDAddedTo:self.view animated:NO];
    thinking.labelText = @"Calculating dates...";
    [thinking show:NO];
    
    NSMutableArray* ranges = [NSMutableArray arrayWithCapacity:selectedIdx.count];
    DLog(@"# selectedIdx(%d):%@",selectedIdx.count,selectedIdx);
    
    
    NSDateFormatter* df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
    
    for(NSNumber* idx in selectedIdx){
        DLog(@"starting %@",idx);
//        CIProductCell* cell = (CIProductCell*)[self.products cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[idx integerValue] inSection:0]];
        NSDictionary* dict = [self.resultData objectAtIndex:idx.intValue];
        if ([[dict objectForKey:@"invtid"] isEqualToString:@"0"]) {
            continue;
        }
        DLog(@"not in cell");
        
// FIXME: Setup calendar to show starting at current date
        NSDate* startDate = [[NSDate alloc]init];
        NSDate* endDate = [[NSDate alloc]init];

        DLog(@"about to get data from cell");
        if ([dict objectForKey:kProductShipDate1] != nil && ![[dict objectForKey:kProductShipDate1] isKindOfClass:[NSNull class]]){
            startDate = [df dateFromString:[dict objectForKey:kProductShipDate1]];
        }
        
        if ([dict objectForKey:kProductShipDate2] != nil && ![[dict objectForKey:kProductShipDate2] isKindOfClass:[NSNull class]]){
            endDate = [df dateFromString:[dict objectForKey:kProductShipDate2]];
        }

//        if (endDate < startDate)
//            endDate = startDate;
        
        DLog(@"got %@(%@) - %@(%@)",startDate,[dict objectForKey:kProductShipDate1],endDate,[dict objectForKey:kProductShipDate2]);
        
        NSMutableArray *dateList = [NSMutableArray array];
        NSCalendar *currentCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        NSDateComponents *comps = [[NSDateComponents alloc] init];
        [comps setDay:1];
        
        [dateList addObject: startDate];

        NSDate *currentDate = startDate;
        // add one the first time through, so that we can use NSOrderedAscending (prevents millisecond infinite loop)
        currentDate = [currentCalendar dateByAddingComponents:comps toDate:currentDate  options:0];
        while ( [endDate compare: currentDate] != NSOrderedAscending) {
            [dateList addObject: currentDate];
            currentDate = [currentCalendar dateByAddingComponents:comps toDate:currentDate  options:0];
        }
        
        DLog(@"adding %@",idx);
        [ranges addObject:dateList];
        DLog(@"finished %@",idx);
    }
    DLog(@"ranges:%@",ranges);

    CICalendarViewController* calView = [[CICalendarViewController alloc] initWithNibName:@"CICalendarViewController" bundle:nil];
    calView.modalPresentationStyle = UIModalPresentationFormSheet;
    
    CICalendarViewController __weak *weakCalView = calView;

    //calView.startDate = [NSDate date];
    
    calView.cancelTouched = ^{
        DLog(@"calender canceled");
        self.backFromCart = YES;
        CICalendarViewController *strongCalView = weakCalView;
        [strongCalView dismissViewControllerAnimated:NO completion:nil];
    };
    
    calView.doneTouched = ^(NSArray* dates){
        CICalendarViewController *strongCalView = weakCalView;
        [selectedIdx enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
            NSNumber* idx = (NSNumber*)obj;
            
            NSMutableDictionary* dict = [self.resultData objectAtIndex:[idx integerValue]];
            NSMutableDictionary* editableDict = [editableData objectForKey:[dict objectForKey:@"id"]];
            
            NSMutableDictionary* edict = [self createIfDoesntExist:editableDict orig:dict];
            
            if (edict == nil) {
                edict = editableDict;
            }
            
            [edict setObject:dates forKey:kOrderItemShipDates];
            [editableData setObject:edict forKey:[dict objectForKey:@"id"]];
            
            DLog(@"done Touch idx(%@) iedict:%@ full data is now:%@",idx,edict,[editableData objectForKey:[dict objectForKey:@"id"]]);
            
            if ([self.productCart objectForKey:[dict objectForKey:@"id"]] != nil) {
                DLog(@"index(%@) shipdates updated to: %@",idx,dates);
                NSMutableDictionary* dict2 = [self.productCart objectForKey:[dict objectForKey:@"id"]];
                [dict2 setObject:dates forKey:kOrderItemShipDates];
                [self updateShipDatesInCartWithId:[[dict objectForKey:@"id"] intValue] forDates:dates];
            }
            [self updateCellColorForId:[idx integerValue]];
        }];
        [selectedIdx removeAllObjects];
        self.backFromCart = YES;
        [self.products reloadData];
        [strongCalView dismissViewControllerAnimated:NO completion:nil];
    };
    
    __block NSMutableArray* selectedArr = [NSMutableArray array];
    
    for(NSNumber* idx in selectedIdx){
        NSMutableDictionary* dict = [self.resultData objectAtIndex:[idx integerValue]];
        NSMutableDictionary* editableDict = [editableData objectForKey:[dict objectForKey:@"id"]];
        
        if (editableDict&&[editableDict objectForKey:kOrderItemShipDates]) {
            if ([[editableDict objectForKey:kOrderItemShipDates] isKindOfClass:[NSArray class]]&&((NSArray*)[editableDict objectForKey:kOrderItemShipDates]).count > 0 ) {
                [selectedArr addObjectsFromArray:((NSArray*)[editableDict objectForKey:kOrderItemShipDates])];
            }
        }
    }

    NSArray *selectedDates = [[NSOrderedSet orderedSetWithArray:selectedArr] allObjects];
    
    if (ranges.count>1) {
//        DLog(@"more then one range");
        NSMutableSet* final = [NSMutableSet setWithArray:[ranges objectAtIndex:0]];
        for (int i = 1; i<ranges.count; i++) {
            NSSet* tempset = [NSSet setWithArray:[ranges objectAtIndex:i]];
            [final intersectSet:tempset];
//            DLog(@"current set:%@", final);
        }
        if (final.count <= 0) {
            [[[UIAlertView alloc] initWithTitle:@"Oops" message:@"We couldn't find any dates that could be used for all of the items you have selected! Please de-select some and then try again!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
        }else{
            calView.startDate = [[final allObjects] objectAtIndex:0];
//            DLog(@"presenting multi range");
            calView.afterLoad =^{
                calView.calendarView.avalibleDates = [[final allObjects] mutableCopy];
                calView.calendarView.selectedDates = [selectedDates mutableCopy];
            };
            [self presentViewController:calView animated:NO completion:nil];
//            DLog(@"presented");
        }
    }else{
        if (ranges&&ranges.count == 1) {
            calView.startDate = [[ranges objectAtIndex:0] objectAtIndex:0];
//            DLog(@"presenting single range:%@",[ranges objectAtIndex:0]);
            calView.afterLoad =^{
                calView.calendarView.avalibleDates =[[ranges objectAtIndex:0] mutableCopy];
                calView.calendarView.selectedDates = [selectedDates mutableCopy];
            };
            
//            DLog(@"copied");
            [self presentViewController:calView animated:NO completion:nil];
//            DLog(@"presented");
        }else{
            DLog(@"empty date range");
        }
    }
//    DLog(@"don't need thinking loader anymore");
    [thinking hide:NO];
}

-(void)postNotification{
    NSMutableDictionary* userInfo = [[NSMutableDictionary alloc] initWithCapacity:1];
    [userInfo setObject:self.customerDB forKey:kCustomerNotificationKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationCustomersLoaded object:nil userInfo:(NSDictionary*)userInfo];
}

-(void)customersLoaded:(NSNotification*)notif {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNotificationCustomersLoaded object:nil];
    NSArray *customers = nil;
    if (notif.userInfo) {
        customers = [notif.userInfo objectForKey:kCustomerNotificationKey];
    }
    if (customers && customers.count > 0){
        self.customerDB = customers;
        if (!self.showCustomers) {
            NSUInteger index = [customers indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
                
                NSString *custid = [obj objectForKey:kCustID];
                *stop = [custid isEqualToString:self.customerId];
                return *stop;
            }];
            if (index != NSNotFound) {
                [self setCustomerInfo:[customers objectAtIndex:index]];
            }
        }
    }else {
        self.customerDB = nil;
        isInitialized = NO;
        [self Cancel];
    }
}

-(void)getCustomers{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(customersLoaded:) name:kNotificationCustomersLoaded object:nil];
    [CustomerDataController loadCustomers:self.authToken];
}

-(void)VoucherChange:(double)price forIndex:(int)idx{
//    NSString* key = [[self.productData objectAtIndex:idx] objectForKey:@"id"];
    NSMutableDictionary* dict = [self.resultData objectAtIndex:idx];
    NSMutableDictionary* editableDict = [editableData objectForKey:[dict objectForKey:@"id"]];
    
    NSMutableDictionary* edict = [self createIfDoesntExist:editableDict orig:dict];
    
    if (edict == nil ) {
        edict = editableDict;
    }
    
    DLog(@"after done touch(should never be nil):%@",edict);
    [edict setObject:[NSNumber numberWithDouble:price] forKey:kEditableVoucher];
    [editableData setObject:edict forKey:[dict objectForKey:@"id"]];
}

-(void)PriceChange:(double)price forIndex:(int)idx{
    //    NSString* key = [[self.productData objectAtIndex:idx] objectForKey:@"id"];
    NSMutableDictionary* dict = [self.resultData objectAtIndex:idx];
    NSMutableDictionary* editableDict = [editableData objectForKey:[dict objectForKey:@"id"]];
    
    NSMutableDictionary* edict = [self createIfDoesntExist:editableDict orig:dict];
    
    if (edict == nil ) {
        edict = editableDict;
    }
    
    DLog(@"after done touch(should never be nil):%@",edict);
    [edict setObject:[NSNumber numberWithDouble:price] forKey:kEditablePrice];
    [editableData setObject:edict forKey:[dict objectForKey:@"id"]];
}

-(void)QtyChange:(double)qty forIndex:(int)idx{
    NSString* key = [[self.resultData objectAtIndex:idx] objectForKey:@"id"];
    NSMutableDictionary* dict = [self.resultData objectAtIndex:idx];
    NSMutableDictionary* editableDict = [editableData objectForKey:[dict objectForKey:@"id"]];
    
    NSMutableDictionary* edict = [self createIfDoesntExist:editableDict orig:dict];
    
    DLog(@"is it nil:%@ editableData:%@",edict,editableData);
    
    if (edict == nil ) {
        edict = editableDict;
    }
    
    DLog(@"after done touch(should never be nil):%@",edict);
    [edict setObject:[NSNumber numberWithDouble:qty] forKey:kEditableQty];
    [editableData setObject:edict forKey:[dict objectForKey:@"id"]];
    
    if (qty > 0) {
        [self AddToCartForIndex:idx];
    }else {
        NSDictionary *details = [self.productCart objectForKey:key];
        [self.productCart removeObjectForKey:key];
        [self removeLineItemFromProductCart:[key intValue]];
        if (_order.orderId > 0) {
            if ([details objectForKey:kOrderLineItemId])
                [self deleteLineItemFromOrder:[[details objectForKey:kOrderLineItemId] integerValue]];
        }
    }
    
    [self updateCellColorForId:idx];
    
    self.totalCost.textColor = [UIColor redColor];

    
    DLog(@"qty change to %@ for index %@",[NSNumber numberWithDouble:qty],[NSNumber numberWithInt:idx]);
}

-(void)deleteLineItemFromOrder:(NSInteger)lineItemId {
    NSString *url = [NSString stringWithFormat:@"%@?%@=%@",[NSString stringWithFormat:kDBOrderLineItemDelete(lineItemId)],kAuthToken,self.authToken];
    DLog(@"%@", url);
    AFHTTPClient *client = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:url]];
    
    [client deletePath:nil parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        DLog(@"DELETE success for line item id: %d", lineItemId);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DLog(@"DELETE failed for line item id: %d", lineItemId);
    }];
    
//    
//    
//    [client setParameterEncoding:AFJSONParameterEncoding];
//    NSMutableURLRequest *request = [client requestWithMethod:@"DELETE" path:nil parameters:nil];
//    
//    AFHTTPRequestOperation *op = [AFHTTPRequestOperation ]
//    
//    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
//        
//        NSString *status = [JSON valueForKey:@"status"];
//        DLog(@"status = %@", status);
//
//    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
//        NSString *errorMsg = [NSString stringWithFormat:@"There was an error submitting the order. %@", error.localizedDescription];
//        [[[UIAlertView alloc] initWithTitle:@"Error!" message:errorMsg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
//    }];
//    
//    [operation start];
}

-(void)AddToCartForIndex:(int)idx{
    NSNumber *key = [[self.resultData objectAtIndex:idx] objectForKey:@"id"];
    DLog(@"add item at %d to cart",idx);
    NSMutableDictionary* dict = [[self.resultData objectAtIndex:idx] mutableCopy];
    NSMutableDictionary* editableDict = [editableData objectForKey:[dict objectForKey:@"id"]];
    
    NSMutableDictionary* edict = [self createIfDoesntExist:editableDict orig:dict];
    
    if (edict == nil ) {
        edict = editableDict;
    }
    
    [dict addEntriesFromDictionary:edict];
    
    NSDictionary *oldCartItem = [self.productCart objectForKey:key];
    if (oldCartItem != nil) {
        NSNumber *lineItemId = [oldCartItem objectForKey:kOrderLineItemId];
        if (lineItemId != nil)
            [dict setObject:lineItemId forKey:kOrderLineItemId];
    }
    
    DLog(@"after done touch(should never be nil):%@ vs %@ dict now:%@",edict, editableDict,dict);
    [self.productCart setObject:dict forKey:key];

    // add item to core data store
    [self addLineItemToProductCart:dict];

    DLog(@"cart now:%@",self.productCart);
}

#pragma mark - Core Data routines

- (Cart *)findCartForId:(int)cartId {
    for (Cart *cart in _order.carts) {
        if (cart.cartId == cartId)
            return cart;
    }
    
    return nil;
}

// Adds a Cart object to the data store using the key/value pairs in the dictionary.
-(void)addLineItemToProductCart:(NSMutableDictionary*)dict {
    NSArray* dates = [dict objectForKey:kOrderItemShipDates];
    
    NSManagedObjectContext *context = _order.managedObjectContext;
    int cartId = [[dict objectForKey:kID] intValue];
    Cart *oldCart = [self findCartForId:cartId];
    
    if (!oldCart)
    {
        NSMutableDictionary *valuesForCart = [self convertForCoreData:dict];

        Cart *cart = [NSEntityDescription insertNewObjectForEntityForName:@"Cart" inManagedObjectContext:context];
        [_order addCartsObject:cart];
        @try {
            [cart setValuesForKeysWithDictionary:valuesForCart];
        }
        @catch (NSException * e) {
            NSLog(@"Exception: %@", e);
        }

        if (dates.count > 0)
        {
            //NSMutableArray *shipDates = [NSMutableArray arrayWithCapacity:dates.count];
            for(int i = 0; i < dates.count; i++){
                
                ShipDate *sd = [NSEntityDescription insertNewObjectForEntityForName:@"ShipDate" inManagedObjectContext:cart.managedObjectContext];
                [cart addShipdatesObject:sd];
                [sd setShipdate:[[dates objectAtIndex:i] timeIntervalSinceReferenceDate]];
                //[shipDates addObject:sd];
            }
            
            //NSOrderedSet *orderedSet = [NSOrderedSet orderedSetWithArray:shipDates];
            //[cart setValue:orderedSet forKey:@"shipdates"];
        }
        
        NSError *error = nil;
        if (![context save:&error]) {
            NSString *msg = [NSString stringWithFormat:@"There was an error saving the product item. %@", error.localizedDescription];
            [[[UIAlertView alloc] initWithTitle:@"Error" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
        }
    }
    else {
        if (!multiStore) {
            [oldCart setEditableQty:[[dict objectForKey:kEditableQty] stringValue]];
        } else {
            [oldCart setEditableQty:[dict objectForKey:kEditableQty]];
        }

        if (dates && [dates count] > 0) {
            [self updateShipDates:dates inCart:oldCart];
        }
        NSError *error = nil;
        if (![context save:&error]) {
            NSString *msg = [NSString stringWithFormat:@"There was an error updating the product item. %@", error.localizedDescription];
            [[[UIAlertView alloc] initWithTitle:@"Error" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
        }
    }
    
    //[coreDataManager saveObjects];
}

// This method takes the values in the dictionary and makes sure they are in the
// propery object format to be translated to the core data Cart entity.
-(NSMutableDictionary *)convertForCoreData:(NSMutableDictionary*)dict {
    NSMutableDictionary *cartValues = [NSMutableDictionary dictionaryWithCapacity:dict.count];
    
    [cartValues setValue:@"standard" forKey:@"category"];
    [cartValues setValue:[self getNumberFromDictionary:dict forKey:kProductAdv asFloat:NO] forKey:kProductAdv];
    [cartValues setValue:[dict objectForKey:kProductCaseQty] forKey:kProductCaseQty];
    [cartValues setValue:[dict objectForKey:kVendorCompany] forKey:kVendorCompany];
    [cartValues setValue:[dict objectForKey:kVendorCreatedAt] forKey:kVendorCreatedAt];
    [cartValues setValue:[dict objectForKey:kProductDescr] forKey:kProductDescr];
    
    if ([kShowCorp isEqualToString: kFarris])
        [cartValues setValue:[dict objectForKey:kProductDescr2] forKey:kProductDescr2];
    
    [cartValues setValue:[self getNumberFromDictionary:dict forKey:kProductDirShip asFloat:NO] forKey:kProductDirShip];
    [cartValues setValue:[self getNumberFromDictionary:dict forKey:kProductDiscount asFloat:YES] forKey:kProductDiscount];
    [cartValues setValue:[self getNumberFromDictionary:dict forKey:kEditablePrice asFloat:YES] forKey:kEditablePrice];
    if (!multiStore) {
        [cartValues setValue:[[dict objectForKey:kEditableQty] stringValue] forKey:kEditableQty];
    } else {
        [cartValues setValue:[dict objectForKey:kEditableQty] forKey:kEditableQty];
    }
    [cartValues setValue:[self getNumberFromDictionary:dict forKey:kEditableVoucher asFloat:YES] forKey:kEditableVoucher];
    [cartValues setValue:[self getNumberFromDictionary:dict forKey:kID asFloat:NO] forKey:@"cartId"];
    [cartValues setValue:[self getNumberFromDictionary:dict forKey:kProductIdx asFloat:NO] forKey:kProductIdx];
//    if ([dict objectForKey:kVendorImportID] && ![[dict objectForKey:kVendorImportID] isKindOfClass:[NSNull class]]) {
    if ([dict objectForKey:kVendorImportID] && ![[dict objectForKey:kVendorImportID] isEqual:[NSNull null]]) {
        [cartValues setValue:[self getNumberFromDictionary:dict forKey:kVendorImportID asFloat:NO] forKey:kVendorImportID];
    } else {
        [cartValues setValue:[NSNull null] forKey:kVendorImportID];
    }
    [cartValues setValue:[dict objectForKey:kVendorInitialShow] forKey:kVendorInitialShow];
    [cartValues setValue:[dict objectForKey:kProductInvtid] forKey:kProductInvtid];
    [cartValues setValue:[dict objectForKey:kProductLineNbr] forKey:kProductLineNbr];
    [cartValues setValue:[self getNumberFromDictionary:dict forKey:kProductNew asFloat:NO] forKey:kProductNew];
    [cartValues setValue:[dict objectForKey:kProductPartNbr] forKey:kProductPartNbr];
    [cartValues setValue:[dict objectForKey:kProductRegPrc] forKey:kProductRegPrc];
    [cartValues setValue:[dict objectForKey:kProductShipDate1] forKey:kProductShipDate1];
    [cartValues setValue:[dict objectForKey:kProductShipDate2] forKey:kProductShipDate2];
    [cartValues setValue:[dict objectForKey:kProductShowPrice] forKey:kProductShowPrice];
    [cartValues setValue:[dict objectForKey:kProductUniqueId] forKey:kProductUniqueId];
    [cartValues setValue:[dict objectForKey:kProductUom] forKey:kProductUom];
    [cartValues setValue:[dict objectForKey:kVendorUpdatedAt] forKey:kVendorUpdatedAt];
    [cartValues setValue:[dict objectForKey:kVendorVendID] forKey:kVendorVendID];
    [cartValues setValue:[self getNumberFromDictionary:dict forKey:@"vendor_id" asFloat:NO] forKey:@"vendor_id"];
    [cartValues setValue:[dict objectForKey:kProductVoucher] forKey:kProductVoucher];
    
    return cartValues;
}

-(void)updateShipDatesInCartWithId:(int)cartId forDates:(NSArray *)dates {
    if (dates && [dates count] > 0) {
        Cart *cart = [self findCartForId:cartId];
        [self updateShipDates:dates inCart:cart];
    }
}

-(void)updateShipDates:(NSArray *)dates inCart:(Cart *)cart {
    if (dates && cart && [dates count] > 0)
    {
        NSDateFormatter* df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
        
        NSMutableArray *cartDates = [[NSMutableArray alloc] initWithCapacity:[cart.shipdates count]];
        for (ShipDate *sd in cart.shipdates) {
            [cartDates addObject:[NSDate dateWithTimeIntervalSinceReferenceDate:sd.shipdate]];
        }
        
        NSMutableArray *newDates= [[NSMutableArray alloc] initWithCapacity:[dates count]];
        for (NSDate *aDate in dates) {
            NSTimeInterval timeInt = [aDate timeIntervalSinceReferenceDate];
            [newDates addObject:[[NSDate alloc] initWithTimeIntervalSinceReferenceDate:timeInt]];
        }
        
        NSArray *sortedCartDates = [cartDates sortedArrayUsingSelector:@selector(compare:)];
        NSArray *sortedDates = [newDates sortedArrayUsingSelector:@selector(compare:)];
        
        if (![sortedDates isEqualToArray:sortedCartDates]) {
            NSMutableArray *newShipDates = [[NSMutableArray alloc] init];
//            [cart removeShipdates:[cart shipdates]];
            for (NSDate *aDate in sortedDates) {
                ShipDate *sd = [NSEntityDescription insertNewObjectForEntityForName:@"ShipDate" inManagedObjectContext:cart.managedObjectContext];
//                [cart addShipdatesObject:sd];
                [sd setShipdate:[aDate timeIntervalSinceReferenceDate]];
                [newShipDates addObject:sd];
            }
            
            for (ShipDate *shipDate in cart.shipdates) {
                [managedObjectContext deleteObject:shipDate];
            }
            
            NSOrderedSet *orderedDates = [NSOrderedSet orderedSetWithArray:newShipDates];
            [cart setShipdates:orderedDates];
            
            NSError *error = nil;
            BOOL success = [managedObjectContext save:&error];
            if (!success) {
                DLog(@"Error updating shipdates in cart: %@", [error localizedDescription]);
            }
        }
    }
}

// Returns an NSNumber object from the dictonary for a given key. If asFloat=YES, returns floatValue, otherwise integerValue.
-(NSNumber*)getNumberFromDictionary:(NSMutableDictionary*)dict forKey:(NSString*)key asFloat:(BOOL)asFloat {
    NSNumber *num;
    if (!asFloat) {
        num = [NSNumber numberWithInt:[[dict objectForKey:key] integerValue]];
    } else {
        num = [NSNumber numberWithFloat:[[dict objectForKey:key] floatValue]];
    }
    
    return num;
}

// Removes a Cart object from the data store for a given product id.
-(void)removeLineItemFromProductCart:(int)productId {
    Cart *oldCart = [self findCartForId:productId];
    if (oldCart) {
        [[CoreDataUtil sharedManager] deleteObject:oldCart];
        [[CoreDataUtil sharedManager] saveObjects];
    }
}

-(void)cancelOrder {
    if (isInitialized && _order)
    {
        [[CoreDataUtil sharedManager] deleteObject:_order];
        [[CoreDataUtil sharedManager] saveObjects];
    }
}

-(void)updateCellColorForId:(NSUInteger)cellId {
    NSMutableDictionary* dict = [self.resultData objectAtIndex:cellId];
    NSMutableDictionary* editableDict = [editableData objectForKey:[dict objectForKey:@"id"]];
    NSString *invtid = [dict objectForKey:@"invtid"];
    NSArray *cells = [self.products visibleCells];
    if ([kShowCorp isEqualToString:kPigglyWiggly]) {
        for (CIProductCell *cell in cells) {
            if ([invtid isEqualToString:cell.InvtID.text]) {
                BOOL hasQty = NO;
                
                //if you want it to highlight based on qty uncomment this:
                if (multiStore && editableDict && [[editableDict objectForKey:kEditableQty] isKindOfClass:[NSString class]]
                    && [[[editableDict objectForKey:kEditableQty] objectFromJSONString] isKindOfClass:[NSDictionary class]]
                    && ((NSDictionary*)[[editableDict objectForKey:kEditableQty] objectFromJSONString]).allKeys.count>0) {
                    for(NSNumber* n in [[[editableDict objectForKey:kEditableQty] objectFromJSONString] allObjects]){
                        if (n > 0)
                            hasQty = YES;
                    }
                }else if (editableDict&&[editableDict objectForKey:kEditableQty]&&[[editableDict objectForKey:kEditableQty] isKindOfClass:[NSString class]]&&[[editableDict objectForKey:kEditableQty] integerValue] >0){
                    hasQty = YES;
                }else if (editableDict&&[editableDict objectForKey:kEditableQty]&&[[editableDict objectForKey:kEditableQty] isKindOfClass:[NSNumber class]]&&[[editableDict objectForKey:kEditableQty] intValue] > 0){
                    hasQty = YES;
                }else{
                    cell.backgroundView = nil;
                }
                
                BOOL hasShipDates = NO;
                NSArray *shipDates = [editableDict objectForKey:kOrderItemShipDates];
                if (shipDates && [shipDates count] > 0) {
                    hasShipDates = YES;
                }
                
                NSNumber *zero = [NSNumber numberWithInt:0];
                BOOL isVoucher = [[dict objectForKey:kProductIdx] isEqualToNumber:zero]
                    && [[dict objectForKey:kProductInvtid] isEqualToString:[zero stringValue]];
                if (!isVoucher) {
                    if (hasQty && (hasShipDates || (self.showShipDates == NO))) {
                        UIView *view = [[UIView alloc] initWithFrame:cell.frame];
                        view.backgroundColor = [UIColor colorWithRed:0.722 green:0.871 blue:0.765 alpha:0.75];
                        cell.backgroundView = view;
                    } else if (hasQty ^ hasShipDates) {
                        UIView *view = [[UIView alloc] initWithFrame:cell.frame];
                        view.backgroundColor = [UIColor colorWithRed:0.839 green:0.655 blue:0.655 alpha:0.75];
                        cell.backgroundView = view;
                    }
                }
            }
        }
    } else if ([kShowCorp isEqualToString:kFarris]) {
        for (FarrisProductCell *cell in cells) {
            if ([invtid isEqualToString:cell.itemNumber.text]) {
                BOOL hasQty = NO;
                
                //if you want it to highlight based on qty uncomment this:
                if (editableDict&&[editableDict objectForKey:kEditableQty]&&[[editableDict objectForKey:kEditableQty] isKindOfClass:[NSString class]]&&[[editableDict objectForKey:kEditableQty] integerValue] >0){
                    hasQty = YES;
                }else if (editableDict&&[editableDict objectForKey:kEditableQty]&&[[editableDict objectForKey:kEditableQty] isKindOfClass:[NSNumber class]]&&[[editableDict objectForKey:kEditableQty] intValue] > 0){
                    hasQty = YES;
                }else{
                    cell.backgroundView = nil;
                }
                
                if (hasQty) {
                    UIView *view = [[UIView alloc] initWithFrame:cell.frame];
                    view.backgroundColor = [UIColor colorWithRed:0.722 green:0.871 blue:0.765 alpha:0.75];
                    cell.backgroundView = view;
                }
            }
        }
    }
}

#pragma mark - line item entry

-(void)QtyTouchForIndex:(int)idx{
    if ([popoverController isPopoverVisible]) {
        [popoverController dismissPopoverAnimated:YES];
    }else{
        if (!storeQtysPO) {
            storeQtysPO = [[CIStoreQtyTableViewController alloc] initWithNibName:@"CIStoreQtyTableViewController" bundle:nil];
        }
        NSMutableDictionary* dict = [self.resultData objectAtIndex:idx];
        NSMutableDictionary* editableDict = [editableData objectForKey:[dict objectForKey:@"id"]];
        
        NSMutableDictionary* edict = [self createIfDoesntExist:editableDict orig:dict];
        
        if (edict == nil ) {
            edict = editableDict;
        }
        
        DLog(@"after done touch(should never be nil):%@",edict);
        if ([[edict objectForKey:kEditableQty] isKindOfClass:[NSNumber class]]) {
            NSArray* storeNums = [[customer objectForKey:kStores] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                NSNumber* n1 = (NSNumber*)obj1;NSNumber* n2 = (NSNumber*)obj2;
                return [n1 compare:n2];
            }];
            
            
            NSMutableDictionary* stores = [NSMutableDictionary dictionaryWithCapacity:storeNums.count+1];
            
            [stores setValue:[NSNumber numberWithInt:0] forKey:[customer objectForKey:kCustID]];
            DLog(@"setting %@ to %@ so stores is now:%@",[customer objectForKey:kCustID],[NSNumber numberWithInt:0],stores);
            for(int i = 0; i<storeNums.count;i++){
                [stores setValue:[NSNumber numberWithInt:0] forKey:[[storeNums objectAtIndex:i] stringValue]];
//                DLog(@"setting %@ to %@ so stores is now:%@",[storeNums objectAtIndex:i],[NSNumber numberWithInt:0],stores);
            }
            
            NSString* JSON = [stores JSONString];
            [edict setObject:JSON forKey:kEditableQty];
        }
        storeQtysPO.stores = [[[edict objectForKey:kEditableQty] objectFromJSONString] mutableCopy];
        DLog(@"stores = %@",storeQtysPO.stores);
        [editableData setObject:edict forKey:[dict objectForKey:@"id"]];
        storeQtysPO.tag = idx;
        storeQtysPO.delegate = self;
        CGRect frame = [self.products rectForRowAtIndexPath:[NSIndexPath indexPathForRow:idx inSection:0]];
        frame = CGRectOffset(frame, 750, 0);
//        DLog(@"pop from frame:%@",NSStringFromCGRect(frame));
        popoverController = [[UIPopoverController alloc] initWithContentViewController:storeQtysPO];
        [popoverController presentPopoverFromRect:frame inView:self.products permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
}

-(void)QtyTableChange:(NSMutableDictionary *)qty forIndex:(int)idx{
    NSString* JSON = [qty JSONString];
    DLog(@"setting qtys on index(%d) to %@",idx,JSON);
    
    NSString* key = [[self.resultData objectAtIndex:idx] objectForKey:@"id"];
    
    NSMutableDictionary* dict = [self.resultData objectAtIndex:idx];
    NSMutableDictionary* editableDict = [editableData objectForKey:[dict objectForKey:@"id"]];
    
    NSMutableDictionary* edict = [self createIfDoesntExist:editableDict orig:dict];
    
    if (edict == nil ) {
        edict = editableDict;
    }
    
    DLog(@"after done touch(should never be nil):%@",edict);
    [edict setValue:JSON forKey:kEditableQty];
    DLog(@"row now set to %@",edict);
    [editableData setObject:edict forKey:key];
    
    int highestQty = -1;
    
    for (NSString* n in qty.allKeys) {
        int j = [[qty objectForKey:n] intValue];
        if (j > highestQty) {
            highestQty = j;
            if (highestQty > 0) {
                break;
            }
        }
    }
    
    DLog(@"in qty %@ the qty picked is %d",qty,highestQty);
    
    if (highestQty > 0) {
        [self AddToCartForIndex:idx];
    }else {
        [self.productCart removeObjectForKey:key];
    }
    
    [self updateCellColorForId:idx];
}

#pragma mark - keyboard functionality 

-(void)dismissKeyboard {
    
}

-(NSDictionary*)getCustomerInfo{
    return [self.customer copy];
}

#pragma mark - UIAlertView delegate

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"OK"]) {
        DLog(@"cancel");
        
        [self cancelOrder];
        [self Return];
    }
}

#pragma mark - Product search

- (void)searchTextUpdated:(UITextField *)textField {
    [self searchProducts:textField];
}

-(IBAction)searchProducts:(id)sender {
    //    DLog(@"search did change:%@ - %@",sBar.text,searchText);
    if (self.productData == nil||[self.productData isKindOfClass:[NSNull class]]) {
        return;
    }
    //    if (sBar == self.searchBar) {
    if ([searchText.text isEqualToString:@""]) {
        self.resultData = [self.productData mutableCopy];
        DLog(@"string is empty");
    }else{
        
        NSPredicate* pred = [NSPredicate predicateWithBlock:^BOOL(id obj, NSDictionary* bindings){
            NSMutableDictionary* dict = (NSMutableDictionary*)obj;
            
            NSString *invtid = nil;
            
            
            DLog(@"Text : %@", [dict objectForKey:kProductDescr]);
            
            if ([dict objectForKey:kProductInvtid] && ![[dict objectForKey:kProductInvtid] isKindOfClass:[NSNull class]]) {
                if ([[dict objectForKey:kProductInvtid] respondsToSelector:@selector(stringValue)]) {
                    invtid = [[dict objectForKey:kProductInvtid] stringValue];
                } else {
                    invtid = [dict objectForKey:kProductInvtid];
                }
                
            }else{
                invtid = @"";
            }
            NSString *descrip = [dict objectForKey:kProductDescr];
            //                DLog(@"invtid:%@ - %@, %@",invtid,sBar.text,([invtid hasPrefix:sBar.text]?@"YES":@"NO"));
            NSString *desc2 = @"";
            if ([kShowCorp isEqualToString:kFarris])
                desc2 = [dict objectForKey:kProductDescr2];
            
            NSString *test = [searchText.text uppercaseString];
            return [invtid hasPrefix:test] || [[descrip uppercaseString] contains:test] || [[desc2 uppercaseString]contains:test];
        }];
        
        self.resultData = [[self.productData filteredArrayUsingPredicate:pred] mutableCopy];
        [selectedIdx removeAllObjects];
        DLog(@"results count:%d", self.resultData.count);
    }
    
    [self.products reloadData];
}

- (IBAction)handleTap:(UITapGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        for (CIProductCell *cell in self.products.visibleCells) {
            if ([cell.quantity isFirstResponder]) {
                [cell.quantity resignFirstResponder];
                break;
            }
        }
    }
}

#pragma mark - UITextFielDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if ([textField.restorationIdentifier isEqualToString:@"SearchField"]) {
        [self.view endEditing:YES];
    }
    
    return NO;
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    return YES;
}

#pragma mark - Reachability delegate methods

-(void)networkLost {
	
	[ciLogo setImage:[UIImage imageNamed:@"ci_red.png"]];
}

-(void)networkRestored {
	
	[ciLogo setImage:[UIImage imageNamed:@"ci_green.png"]];
}

#pragma mark - Vendor View Delegate

-(void)setVendor:(NSInteger)vendorId {
    currentVendor = vendorId;
}

-(void)setBulletin:(NSInteger)bulletinId {
    currentBulletin = bulletinId;
}

-(void)dismissVendorPopover {
    if ([popoverController isPopoverVisible])
        [popoverController dismissPopoverAnimated:YES];
    [self loadProducts];
}

#pragma CICartViewControlelr Delegate
-(void)reload{
    [self.products reloadData];
}

-(void)setSelectedRow:(NSUInteger)index {
    selectedItemRowIndexPath = [NSIndexPath indexPathForRow:index inSection:0];
}

- (void)keyboardWillShow{

    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.5];
    self.products.contentOffset = selectedItemRowIndexPath ?CGPointMake(0, [self.products rowHeight] * selectedItemRowIndexPath.row):CGPointMake(0,0);
    [UIView commitAnimations];
}

- (void)keyboardDidHide{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.5];
    self.products.contentOffset = CGPointMake(0,0);
    [UIView commitAnimations];
}

@end