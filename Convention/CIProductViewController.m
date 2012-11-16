//
//  CIProductViewController.m
//  Convention
//
//  Created by Matthew Clark on 10/31/11.
//  Copyright (c) 2011 MotionMobs. All rights reserved.
//

#import "CIProductViewController.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
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
#import "StringManipulation.h"

@interface CIProductViewController (){
    //MBProgressHUD* loading;
    int currentVendor;
    NSArray* vendorsData;
    NSMutableDictionary* editableData;
    NSMutableSet* selectedIdx;
//    void(^loadCustomers)(void);
    BOOL isInitialized;
    CoreDataUtil* coreDataManager;
}
-(void) getCustomers;
@end

@implementation CIProductViewController
@synthesize vendorLabel;
@synthesize products;
@synthesize ciLogo;
@synthesize hiddenTxt;
@synthesize searchBar;
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
@synthesize customersReady;
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
@synthesize order;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        showPrice = YES;
        customersReady = NO;
        backFromCart = NO;
        tOffset = 0;
        currentVendor = 0;
        productCart = [NSMutableDictionary dictionary];
        editableData = [NSMutableDictionary dictionary];
        selectedIdx = [NSMutableSet set];
        multiStore = NO;
        isInitialized = NO;
        coreDataManager = [CoreDataUtil sharedManager];
    }
	
	reachDelegation = [[ReachabilityDelegation alloc] initWithDelegate:self
															   withUrl:kBASEURL];
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

-(void)networkLost {
	
	[ciLogo setImage:[UIImage imageNamed:@"ci_red.png"]];
	
	
	 
}

-(void)networkRestored {
	
	[ciLogo setImage:[UIImage imageNamed:@"ci_green.png"]];

	
}


#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated
{
//    self.products.allowsMultipleSelection = YES;
//    self.products.allowsMultipleSelectionDuringEditing = YES;
     //self.searchBar.backgroundColor =  [UIColor clearColor];
	[[searchBar.subviews objectAtIndex:0] removeFromSuperview];
    
    if(backFromCart && finishOrder) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self finishOrder:nil];
        });
        backFromCart = NO;
    }
    
    if(!backFromCart){
        
        NSString* url;
        if (self.vendorGroup&&![self.vendorGroup isKindOfClass:[NSNull class]]) {
            url = [NSString stringWithFormat:@"%@?%@=%@&%@=%@",kDBGETPRODUCTS,kAuthToken,self.authToken,kVendorGroupID,self.vendorGroup];
        }else {
            url = [NSString stringWithFormat:@"%@?%@=%@",kDBGETPRODUCTS,kAuthToken,self.authToken];
        }
        
        [self loadProductsForUrl:url withLoadLabel:@"Loading Products..."];
        
        navBar.topItem.title = self.title;
        //[self getCustomers];
    }
    
	self.vendorLabel.text = [[SettingsManager sharedManager] lookupSettingByString:@"username"];
    [self.vendorTable reloadData];
}

- (void)viewDidDisappear:(BOOL)animated
{
    // unregister for keyboard notifications while not visible.
    //[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];

    [self setProducts:nil];
    [self setNavBar:nil];
    [self setIndicator:nil];
    [self setHiddenTxt:nil];
    [self setVendorView:nil];
    [self setVendorTable:nil];
    [self setDismissVendor:nil];
    [self setCustomerLabel:nil];
	[self setVendorLabel:nil];
    [self setSearchBar:nil];
    [super viewDidDisappear:animated];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

-(NSMutableDictionary*)createIfDoesntExist:(NSMutableDictionary*) dict orig:(NSDictionary*)odict{
    DLog(@"test this:%@",dict);
    if (dict&&[dict objectForKey:kEditablePrice]&&[dict objectForKey:kEditableVoucher]&&[dict objectForKey:kEditableQty]) {
        return nil;
    }
    
    dict = [NSMutableDictionary dictionary];
    
    [dict setValue:[NSNumber numberWithDouble:[[odict objectForKey:kProductShowPrice] doubleValue]] forKey:kEditablePrice];
    [dict setValue:[NSNumber numberWithDouble:[[odict objectForKey:kProductVoucher] doubleValue]] forKey:kEditableVoucher];
    [dict setValue:[NSNumber numberWithInt:0] forKey:kEditableQty];
    
    return dict;
}

-(void)loadProductsForUrl:(NSString*)url withLoadLabel:(NSString*)label{
    
    MBProgressHUD* __weak loadProductsHUD = [MBProgressHUD showHUDAddedTo:self.view animated:NO];
    loadProductsHUD.labelText = label;
    [loadProductsHUD show:NO];
    
    // Do any additional setup after loading the view from its nib.
    DLog(@"Sending %@",url);
    ASIHTTPRequest* request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:url]];
    [request setNumberOfTimesToRetryOnTimeout:3];
    
    ASIHTTPRequest __weak *weakRequest = request;
    [request setCompletionBlock:^{
        ASIHTTPRequest *strongRequest = weakRequest;
        
        //DLog(@"response:%@",[request responseString]);
        NSArray* data = [[strongRequest responseString] objectFromJSONString];
        
        //        DLog(@"data:%@",data);
        self.productData = [data mutableCopy];
        //PW---        if (showPrice) {
        for( int i=0;i< self.productData.count;i++){
            NSMutableDictionary* dict = [[self.productData objectAtIndex:i] mutableCopy];
            
            //            DLog(@"invtid:%@",[dict objectForKey:kProductInvtid]);
            
            [self.productData removeObjectAtIndex:i];
            [self.productData insertObject:dict atIndex:i];
        }
        //        }
        //        DLog(@"Json:%@",self.productData);
        self.resultData = [self.productData mutableCopy];
        [self.products reloadData];
        [loadProductsHUD hide:NO];
        [self loadCustomersView];
    }];
    
    [request setFailedBlock:^{
        //DLog(@"error:%@", [request error]);
        ASIHTTPRequest *strongRequest = weakRequest;
        [[[UIAlertView alloc] initWithTitle:@"Error!" message:[NSString stringWithFormat:@"Got error:%@",[strongRequest error]] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
        [loadProductsHUD hide:NO];
    }];
    
    [request startAsynchronous];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

#pragma mark - Customer data

-(void)loadCustomersView {
//    loading.labelText = @"Loading...";
//    [loading show:NO];
//    
//    [loading hide:NO];
    
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

#pragma mark - Table stuff
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return 1;
}
- (NSInteger)tableView:(UITableView *)myTableView numberOfRowsInSection:(NSInteger)section {
    if (self.resultData&&myTableView==self.products) {
        return [self.resultData count];
    }else if (vendorsData&& myTableView == self.vendorTable) {
        return vendorsData.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)myTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (!self.resultData&&myTableView==self.products) {
        return nil;
    }
    if (!vendorsData&&myTableView==self.vendorTable) {
        return nil;
    }
    
    
    if (myTableView==self.vendorTable) {
//        DLog(@"vendor table");
        static NSString* CellId = @"CIVendorCell";
        UITableViewCell* cell = [myTableView dequeueReusableCellWithIdentifier:CellId];
        
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellId];
        }
        
        //TODO: pull from list and set tag to internal vendor_id
        NSDictionary* details = [vendorsData objectAtIndex:[indexPath row]];
		if ([details objectForKey:kVendorVendID] != nil)
           cell.textLabel.text = [NSString stringWithFormat:@"%@ - %@", [details objectForKey:kVendorVendID] != nil ? [details objectForKey:kVendorVendID] : @"", [details objectForKey:kVendorUsername]];
		else
			cell.textLabel.text = [NSString stringWithFormat:@"%@", [details objectForKey:kVendorUsername]];

        cell.tag = [[details objectForKey:@"id"] intValue];
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        UIView* bg = [[UIView alloc] init];
        bg.backgroundColor = [UIColor colorWithRed:.94 green:.74 blue:.36 alpha:1.0];
        cell.selectedBackgroundView = bg;
        
        return cell;
    }else {
        
        static NSString *CellIdentifier = @"CIProductCell";
        
        CIProductCell *cell = [myTableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        if (cell == nil){
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"CIProductCell" owner:nil options:nil]; 
            
            for(id currentObject in topLevelObjects)
            {
                if([currentObject isKindOfClass:[CIProductCell class]])
                {
                    cell = (CIProductCell *)currentObject;
                    break;
                }
            }
        }
        
        NSMutableDictionary* dict = [self.resultData objectAtIndex:[indexPath row]];
        NSMutableDictionary* editableDict = [editableData objectForKey:[dict objectForKey:@"id"]];
        
//        DLog(@"data(%d):%@",indexPath.row,dict);
        
        //idx, invtid, descr, partnbr, uom, showprc, caseqty, dirship, linenbr, new, adv, discount
        if ([dict objectForKey:@"idx"]&&![[dict objectForKey:@"idx"] isKindOfClass:[NSNull class]]) {
            cell.ridx.text = [[dict objectForKey:@"idx"] stringValue];
        }else
            cell.ridx.text = @"0";
        
        cell.InvtID.text = [dict objectForKey:@"invtid"];
        cell.descr.text = [dict objectForKey:@"descr"];
        
        //PW -- swapping out partnbr and UOM for Ship date range
        if([dict objectForKey:kProductShipDate1]&&![[dict objectForKey:kProductShipDate1] isKindOfClass:[NSNull class]]){
            NSDateFormatter* df = [[NSDateFormatter alloc] init];
            [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
            NSDate* date = [[NSDate alloc]init];
            date = [df dateFromString:[dict objectForKey:kProductShipDate1]];
//            DLog(@"date(%@):%@",[[self.productData objectAtIndex:[indexPath row]] objectForKey:kProductShipDate1],date);
            [df setDateFormat:@"yyyy-MM-dd"];
            cell.PartNbr.text = [df stringFromDate:date];
        }else
            cell.PartNbr.text = @"";
        
        if([dict objectForKey:kProductShipDate2]&&![[dict objectForKey:kProductShipDate2] isKindOfClass:[NSNull class]]){
            NSDateFormatter* df = [[NSDateFormatter alloc] init];
            [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
            NSDate* date = [[NSDate alloc]init];
            date = [df dateFromString:[dict objectForKey:kProductShipDate2]];
            [df setDateFormat:@"yyyy-MM-dd"];
            cell.Uom.text = [df stringFromDate:date];
        }else
            cell.Uom.text = @"";
        //PW---
        
        if([dict objectForKey:@"caseqty"]&&![[dict objectForKey:@"caseqty"] isKindOfClass:[NSNull class]])
            cell.CaseQty.text = [dict objectForKey:@"caseqty"];
        else
            cell.CaseQty.text = @"";
        
        cell.DirShip.text = ([dict objectForKey:@"dirship"]?@"Y":@"N");
        
        if ([dict objectForKey:@"linenbr"]&&![[dict objectForKey:@"linenbr"] isKindOfClass:[NSNull class]]) {
            cell.LineNbr.text = [dict objectForKey:@"linenbr"];
        }else{
            cell.LineNbr.text = @"";
        }
        
        cell.New.text = ([dict objectForKey:@"new"]?@"Y":@"N");
        cell.Adv.text = ([dict objectForKey:@"adv"]?@"Y":@"N");
        //DLog(@"regPrc:%@",[dict objectForKey:@"regprc"]);
        
//        cell.regPrc.text = [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithDouble:[[dict objectForKey:@"regprc"] doubleValue]] numberStyle:NSNumberFormatterCurrencyStyle];
        
        cell.regPrc.text = ([[editableDict objectForKey:kOrderItemShipDates] isKindOfClass:[NSArray class]]?[NSString stringWithFormat:@"%d",((NSArray*)[editableDict objectForKey:kOrderItemShipDates]).count]:@"0");
        
        if (editableDict&&[editableDict objectForKey:kEditableQty]&&!multiStore) {
            cell.quantity.text = [[editableDict objectForKey:kEditableQty] stringValue];
        }
        else
            cell.quantity.text = @"0";
        cell.qtyLbl.hidden = YES;
        
        if ([[customer objectForKey:kStores] isKindOfClass:[NSArray class]]&&[((NSArray*)[customer objectForKey:kStores]) count]>0) {
            multiStore = YES;
            cell.qtyBtn.hidden = NO;
            cell.qtyLbl.hidden = YES;
            cell.quantity.hidden = YES;
        }
        
        if (editableDict&&[editableDict objectForKey:kEditableVoucher]) {
            NSNumberFormatter* nf = [[NSNumberFormatter alloc] init];
            nf.formatterBehavior = NSNumberFormatterBehavior10_4;
            nf.maximumFractionDigits = 2;
            nf.minimumFractionDigits = 2;
            nf.minimumIntegerDigits = 1;
            
            cell.voucher.text = [nf stringFromNumber:[editableDict objectForKey:kEditableVoucher]];
            cell.voucherLbl.text = cell.voucher.text;
            cell.voucher.hidden = YES;//PW changes!
        }else if([dict objectForKey:kProductVoucher]){
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
        
        if (showPrice&&editableDict&&[editableDict objectForKey:kEditablePrice]) {
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
        else if([dict objectForKey:kProductShowPrice]){
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
        
        
        if ([selectedIdx containsObject:[NSNumber numberWithInteger:[indexPath row]]]) {
//            [[self.products cellForRowAtIndexPath:indexPath] setSelected:NO];
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }else{
            //            [[self.products cellForRowAtIndexPath:indexPath] setSelected:YES];
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        
        
        //if you want it to highlight based on shipdates uncomment this:
//        if ([[editableDict objectForKey:kOrderItemShipDates] isKindOfClass:[NSArray class]]&&((NSArray*)[editableDict objectForKey:kOrderItemShipDates]).count>0) {
////            DLog(@"highlight");
//            UIView* view = [[UIView alloc] initWithFrame:cell.frame];
//            view.backgroundColor = [UIColor colorWithRed:.9 green:.9 blue:.9 alpha:1.0];
//            cell.backgroundView = view;
//        }else{
////            DLog(@"no highlight");
//            cell.backgroundView = nil;
//        }
        
        
        //if you want it to highlight based on qty uncomment this:
        if (multiStore&&editableDict&&[[editableDict objectForKey:kEditableQty] isKindOfClass:[NSString class]]&&[[[editableDict objectForKey:kEditableQty] objectFromJSONString] isKindOfClass:[NSDictionary class]]&&((NSDictionary*)[[editableDict objectForKey:kEditableQty] objectFromJSONString]).allKeys.count>0) {
//            DLog(@"first");
            BOOL hasQty = NO;
            for(NSNumber* n in [[[editableDict objectForKey:kEditableQty] objectFromJSONString] allObjects]){
                if(n>0)
                    hasQty = YES;
            }
            if (hasQty) {
                UIView* view = [[UIView alloc] initWithFrame:cell.frame];
                view.backgroundColor = [UIColor colorWithRed:.9 green:.9 blue:.9 alpha:1.0];
                cell.backgroundView = view;
            }
        }else if (editableDict&&[editableDict objectForKey:kEditableQty]&&[[editableDict objectForKey:kEditableQty] isKindOfClass:[NSString class]]&&[[editableDict objectForKey:kEditableQty] integerValue] >0){
//            DLog(@"second");
            //            DLog(@"highlight");
            UIView* view = [[UIView alloc] initWithFrame:cell.frame];
            view.backgroundColor = [UIColor colorWithRed:.9 green:.9 blue:.9 alpha:1.0];
            cell.backgroundView = view;
        }else if (editableDict&&[editableDict objectForKey:kEditableQty]&&[[editableDict objectForKey:kEditableQty] isKindOfClass:[NSNumber class]]&&[[editableDict objectForKey:kEditableQty] intValue] > 0){
            //            DLog(@"highlight");
            UIView* view = [[UIView alloc] initWithFrame:cell.frame];
            view.backgroundColor = [UIColor colorWithRed:.9 green:.9 blue:.9 alpha:1.0];
            cell.backgroundView = view;
        }else{
//            DLog(@"nil");
            //            DLog(@"no highlight");
            cell.backgroundView = nil;
        }
        
        
        cell.cartBtn.hidden = YES;
        cell.delegate = self;
        cell.tag = [indexPath row];
        //cell.subtitle.text = [[dict objectForKey:@"id"] stringValue];
        
        return (UITableViewCell *)cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.products) {
        DLog(@"product details:%@",[self.resultData objectAtIndex:[indexPath row]]);
        if ([selectedIdx containsObject:[NSNumber numberWithInteger:[indexPath row]]]) {
            [selectedIdx removeObject:[NSNumber numberWithInteger:[indexPath row]]];
            //            [[tableView cellForRowAtIndexPath:indexPath] setSelected:NO];
            [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryNone;
        }else{
            [selectedIdx addObject:[NSNumber numberWithInteger:[indexPath row]]];
            //            [[tableView cellForRowAtIndexPath:indexPath] setSelected:YES];
            [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
        }
    }else if(tableView == self.vendorTable){
        [self dismissVendorTouched:nil];
        [selectedIdx removeAllObjects];
        UITableViewCell* cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
        if (cell.tag == currentVendor) {
            return;
        }
        currentVendor = cell.tag;
        NSString* url;
        if (cell.tag == 0) {
            if (self.vendorGroup&&![self.vendorGroup isKindOfClass:[NSNull class]]) {
                url = [NSString stringWithFormat:@"%@?%@=%@&%@=%@",kDBGETPRODUCTS,kAuthToken,self.authToken,kVendorGroupID,self.vendorGroup];
            }else {
                url = [NSString stringWithFormat:@"%@?%@=%@",kDBGETPRODUCTS,kAuthToken,self.authToken];
            }
            
            [self loadProductsForUrl:url withLoadLabel:@"Loading all Products..."];
        }else {
            url = [NSString stringWithFormat:@"%@?%@=%@&%@=%d",kDBGETPRODUCTS,kAuthToken,self.authToken,@"vendor_id",cell.tag];
            
            [self loadProductsForUrl:url withLoadLabel:@"Loading Products for Selection..."];
        }
		
		NSDictionary* details = [vendorsData objectAtIndex:[indexPath row]];
       self.vendorLabel.text = [NSString stringWithFormat:@"%@ - %@", [details objectForKey:kVendorVendID], [details objectForKey:kVendorUsername]];

    }
}

#pragma mark - Other
-(void)logout
{
    NSString* url = kDBLOGOUT;
    if (authToken) {
        url = [NSString stringWithFormat:@"%@?%@=%@",kDBLOGOUT,kAuthToken,authToken];
    }
    
    DLog(@"Signout url:%@",url);
    
    __block ASIHTTPRequest* signout = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:url]];
    [signout setRequestMethod:@"DELETE"];
    
    [signout setCompletionBlock:^{
        //DLog(@"Signout:%@",[signout responseString]);
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    
    [signout setFailedBlock:^{
        //DLog(@"Signout Error:%@",[signout error]);
    }];
    
    [signout startAsynchronous];
}

-(void)Cancel{
    if (isInitialized) {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Cancel Order?"
                                  message:@"This will cancel the current order."
                                  delegate:self
                                  cancelButtonTitle:@"Cancel"
                                  otherButtonTitles:@"OK", nil];
        
        [alertView show];
    } else {
        [self dismissViewControllerAnimated:NO completion:^{
            if (self.delegate) {
                [self.delegate Return];
            }
        }];
    }
}

- (IBAction)Cancel:(id)sender {
    [self Cancel];
}

- (IBAction)logout:(id)sender {
    [self logout];
}

-(void)setCustomerInfo:(NSDictionary*)info
{
    //[loading hide:YES];
    [self.products reloadData];
    
    //int customer_id = -1;
    int custid = -1;
    if (isInitialized) {
        //customer_id = [[self.customer objectForKey:@"id"] integerValue];
        custid = [[self.customer objectForKey:@"custid"] integerValue];
    }
    
    self.customer = [info copy];
    DLog(@"set customerinfo:%@",self.customer);
    
    //if they want Billname displayed uncomment this
    if ([self.customer objectForKey:kBillName]) {
        self.customerLabel.text = [self.customer objectForKey:kBillName];
    }
    
    if (!isInitialized) {
        order = (Order *)[coreDataManager createNewEntity:@"Order"];
        [order setCustomer_id:[NSNumber numberWithInt:[[self.customer objectForKey:@"id"] integerValue]]];
        [order setCustid:[NSNumber numberWithInt:[[self.customer objectForKey:@"custid"] integerValue]]];
        [order setMultiStore:[NSNumber numberWithBool:multiStore]];
        [order setPartial:[NSNumber numberWithBool:YES]];
        [order setCreated_at:[NSDate date]];
        [coreDataManager saveObjects];
        isInitialized = YES;
    }
    else {
        //NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(customer_id = %@) AND (custid = %@)", customer_id, custid];
        //order = [[CoreDataUtil sharedManager] fetchObject:@"Order" withPredicate:predicate];
        
        [order setCustid:[NSNumber numberWithInt:custid]];
        [coreDataManager saveObjects];
    }
}

- (IBAction)submit:(id)sender {
    MBProgressHUD* submit = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    submit.labelText = @"Submitting order...";
    [submit show:YES];
    
    NSMutableArray* arr = [[NSMutableArray alloc] initWithCapacity:[self.products numberOfRowsInSection:0]];
    
    //    NSNumberFormatter* nf = [[NSNumberFormatter alloc] init];
    //    [nf setNumberStyle:NSNumberFormatterCurrencyStyle];
    NSArray* keys = self.productCart.allKeys;
    for (NSString* i in keys) {
        NSString* productID = i;//[[self.productData objectAtIndex:] objectForKey:@"id"];
//        CIProductCell* cell = (CIProductCell*)[self.products cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i.intValue inSection:0]];
        NSDictionary* dict = [self.productCart objectForKey:i];
        
        NSInteger num = 0;
        if (!multiStore) {
            DLog(@"!multiStore:%@",[dict objectForKey:kEditableQty]);
            num = [[dict objectForKey:kEditableQty] integerValue];
        }else{
            NSMutableDictionary* qty = [[dict objectForKey:kEditableQty] objectFromJSONString];
            for( NSString* n in qty.allKeys){
                int j =[[qty objectForKey:n] intValue];
                if (j>num) {
                    num = j;
                    if (num>0) {
                        break;
                    }
                }
            }
        }
        DLog(@"orig yo q:%@=%d with %@ and %@",[dict objectForKey:kEditableQty], num,[dict objectForKey:kEditablePrice],[dict objectForKey:kEditableVoucher]);
        if (num>0) {
            
            NSArray* dates = [dict objectForKey:kOrderItemShipDates];
            NSMutableArray* strs = [NSMutableArray array];
            
            NSDateFormatter* df = [[NSDateFormatter alloc] init];
            [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
            for(int i = 0; i < dates.count; i++){
                NSString* str = [df stringFromDate:[dates objectAtIndex:i]];
                [strs addObject:str];
            }
            
            NSDictionary* proDict = [NSDictionary dictionaryWithObjectsAndKeys:productID,kOrderItemID,[dict objectForKey:kEditableQty],kOrderItemNum,[dict objectForKey:kEditablePrice],kOrderItemPRICE,[dict objectForKey:kEditableVoucher],kOrderItemVoucher,strs,kOrderItemShipDates, nil];
            [arr addObject:(id)proDict];
        }
    }
    
    [arr removeObjectIdenticalTo:nil];
    
    DLog(@"array:%@",arr);
    NSDictionary* _order;
    //if ([info objectForKey:kOrderCustID]) {
    if (!self.customer) {
        return;
    }
    _order = [NSDictionary dictionaryWithObjectsAndKeys:[self.customer objectForKey:@"id"],kOrderCustID,[self.customer objectForKey:kShipNotes],kShipNotes,[self.customer objectForKey:kNotes],kNotes,[self.customer objectForKey:kAuthorizedBy],kAuthorizedBy,[self.customer objectForKey:kEmail],kEmail,[self.customer objectForKey:kSendEmail],kSendEmail, arr,kOrderItems, nil];
    //    }
    //    else{
    //        order = [NSDictionary dictionaryWithObjectsAndKeys:[info objectForKey:kCustName],kCustName,[info objectForKey:kStoreName],kStoreName,[info objectForKey:kCity],kCity,arr,kOrderItems, nil];
    //    }
    NSDictionary* final = [NSDictionary dictionaryWithObjectsAndKeys:_order,kOrder, nil];
    
    NSString *url = [NSString stringWithFormat:@"%@?%@=%@",kDBORDER,kAuthToken,self.authToken];
    DLog(@"final JSON:%@\nURL:%@",[final JSONString],url);
    
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:url]];
    [request addRequestHeader:@"Accept" value:@"application/json"];
    [request addRequestHeader:@"Content-Type" value:@"application/json"];
    //[request appendPostData:[dataContent dataUsingEncoding:NSUTF8StringEncoding]];
    [request setRequestMethod:@"POST"];
    [request setNumberOfTimesToRetryOnTimeout:3];
    
    //[request addRequestHeader:@"Content-Type" value:@"application/json; charset=utf-8"];
    
    //[request setPostValue:self.authToken forKey:kAuthToken];
    
    //[request.postBody appendData:[final JSONData]];
    [request appendPostData:[[final JSONString] dataUsingEncoding:NSUTF8StringEncoding]];
    
    //DLog(@"pure:%@",[request postBody]);
    
    ASIHTTPRequest __weak *weakRequest = request;
    
    [request setCompletionBlock:^{
        
        ASIHTTPRequest* strongRequest = weakRequest;
        
        [submit hide:YES];
        
        NSString* _response = [strongRequest responseString];
        DLog(@"response: %@", _response);
        
        //DLog(@"Order complete:%@",[request responseString]);
        if (![[strongRequest responseString] objectFromJSONString]) {
            [[[UIAlertView alloc] initWithTitle:@"Error!" message:@"Something odd happened. Please try submitting your order again from the Cart!"
                                       delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
            return;
        }
        
        self.productCart = [NSMutableDictionary dictionary];
        [self.products reloadData];
        
        dispatch_queue_t tapQueue;
        tapQueue = dispatch_queue_create("tapQueue", NULL);
        dispatch_async(tapQueue, ^{
            [NSThread sleepForTimeInterval:1];
            DLog(@"tap");
            dispatch_async(dispatch_get_main_queue(), ^{
                DLog(@"tap2");
                if (self.delegate != nil) {
                    [self.delegate Return];
                    //[self.delegate performSelector:@selector(Return) withObject:nil afterDelay:0.0f];
                }
                [self dismissViewControllerAnimated:NO completion:nil];
            });
        });
    }];
    
    [request setFailedBlock:^{
        ASIHTTPRequest* strongRequest = weakRequest;
        [submit hide:YES];
        // DLog(@"Order Error:%@",[request error]);
        [[[UIAlertView alloc] initWithTitle:@"Error!" message:[NSString stringWithFormat:@"Got the following error on submittion:%@",[strongRequest error]] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
    }];
    
    DLog(@"request content-type:%@",request.requestHeaders);
    
    [request startAsynchronous];
    
        
//    [self dismissModalViewControllerAnimated:YES];
}

-(void) Return{
    if (self.delegate) {
        [self.delegate Return];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)finishOrder:(id)sender {
    
    if ([[self.productCart allKeys] count] <= 0) {
        [[[UIAlertView alloc] initWithTitle:@"Cart Empty." message:@"You don't have anything in your cart!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
        return;
    }
    CIFinalCustomerInfoViewController* ci = [[CIFinalCustomerInfoViewController alloc] initWithNibName:@"CIFinalCustomerInfoViewController" bundle:nil];
    ci.modalPresentationStyle = UIModalPresentationFormSheet;
    ci.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    ci.delegate = self;
//    [ci setCustomerData:self.customerDB];
    [self presentViewController:ci animated:YES completion:nil];
}

- (IBAction)reviewCart:(id)sender {
    [self.hiddenTxt becomeFirstResponder];
    [self.hiddenTxt resignFirstResponder];
 
    CICartViewController* cart = [[CICartViewController alloc] initWithNibName:@"CICartViewController" bundle:nil];
    cart.delegate = self;
//    cart.finishTheOrder = ^{
//        [self finishOrder:nil];  
//    };
    cart.customerDB = self.customerDB;
    cart.productData = [self.productCart copy];
    cart.productCart = self.productCart;
    cart.multiStore = multiStore;
    cart.modalPresentationStyle = UIModalPresentationFullScreen;
//    cart.modalTransitionStyle = UIModalTransitionStylePartialCurl;
    [self presentViewController:cart  animated:YES completion:nil];
}

- (IBAction)vendorTouch:(id)sender {
    if (!self.vendorView.hidden&&!self.dismissVendor.hidden) {
        self.vendorView.hidden = YES;
        self.dismissVendor.hidden = YES;
        return;
    }
    
    [self.searchBar becomeFirstResponder];
    [self.searchBar resignFirstResponder];
    [selectedIdx removeAllObjects];
    
    //lazy load this bizal
    if (vendorsData == nil) {
        MBProgressHUD* venderLoading = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        venderLoading.labelText = @"Loading vendors from your vendor group...";
        [venderLoading show:YES];
        
        if (self.vendorGroup&&![self.vendorGroup isKindOfClass:[NSNull class]]) {
            NSString* url = [NSString stringWithFormat:@"%@&%@=%@",kDBGETVENDORSWithVG(self.vendorGroup),kAuthToken,self.authToken];
            ASIHTTPRequest* request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:url]];
            [request setNumberOfTimesToRetryOnTimeout:3];
            __weak ASIHTTPRequest* weakRequest = request;
            [request setCompletionBlock:^{
                //DLog(@"success got:%@",[request responseString]);
                ASIHTTPRequest* strongRequest = weakRequest;
                NSArray* results = [[strongRequest responseString] objectFromJSONString];
                if (!results||![results objectAtIndex:0]||![[results objectAtIndex:0] objectForKey:@"vendors"]) {
                    [venderLoading hide:YES];
                    [[[UIAlertView alloc] initWithTitle:@"Error!" message:@"Something weird happened! If this problem persists people notify Convention Innovations!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
                    return;
                }
                
                NSArray* vendors = [[results objectAtIndex:0] objectForKey:@"vendors"];
                
                NSMutableArray* vs = [NSMutableArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:@"Any",kVendorUsername,@"0",@"id", nil], nil];
                
                [vendors enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop){
                    NSDictionary* dict = (NSDictionary*)obj;
                    [vs addObject:dict];
                }];
                
                vendorsData = [vs mutableCopy];
                
                [venderLoading hide:YES];
                [self.vendorTable reloadData];
            }];
            
            [request setFailedBlock:^{
                ASIHTTPRequest* strongRequest = weakRequest;
                [[[UIAlertView alloc] initWithTitle:@"Error!" message:[NSString stringWithFormat:@"Got error retrieving vendors for vendor group:%@",[strongRequest error]] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
                
                vendorsData = [NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:@"Any",kVendorUsername,@"0",@"id", nil], nil];
                
                [venderLoading hide:YES];
                [self.vendorTable reloadData];
            }];
            
            [request startAsynchronous];
            
        }else{
            [venderLoading hide:YES];
            
            vendorsData = [NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:@"Any",kVendorUsername,@"0",@"id", nil], nil];
        
            [self.vendorTable reloadData];
            DLog(@"reloading vendor table");
        }
    }
    
    self.vendorView.hidden = NO;
    self.dismissVendor.hidden = NO;
}

- (IBAction)dismissVendorTouched:(id)sender {
    self.vendorView.hidden = YES;
    self.dismissVendor.hidden = YES;
}

- (IBAction)shipdatesTouched:(id)sender {
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
        
        
        NSDate* startDate = [[NSDate alloc]init];
        NSDate* endDate = [[NSDate alloc]init];
        
        DLog(@"about to get data from cell");
        if([dict objectForKey:kProductShipDate1]&&![[dict objectForKey:kProductShipDate1] isKindOfClass:[NSNull class]]){
            startDate = [df dateFromString:[dict objectForKey:kProductShipDate1]];
        }
        
        if([dict objectForKey:kProductShipDate2]&&![[dict objectForKey:kProductShipDate2] isKindOfClass:[NSNull class]]){
            endDate = [df dateFromString:[dict objectForKey:kProductShipDate2]];
        }
        
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
            
            if (edict == nil ) {
                edict = editableDict;
            }
            
            DLog(@"after done touch(should never be nil):%@ vs orig%@",edict,editableDict);
            
            [edict setObject:dates forKey:kOrderItemShipDates];
            [editableData setObject:edict forKey:[dict objectForKey:@"id"]];
            
            DLog(@"done Touch idx(%@) iedict:%@ full data is now:%@",idx,edict,[editableData objectForKey:[dict objectForKey:@"id"]]);
            
            DLog(@"DT cart data:%@",self.productCart);
            
            if ([self.productCart objectForKey:[dict objectForKey:@"id"]]) {
                DLog(@"index(%@) shipdates updated to: %@",idx,dates);
                NSMutableDictionary* dict2 = [self.productCart objectForKey:[dict objectForKey:@"id"]];
                [dict2 setObject:dates forKey:kOrderItemShipDates];
            }
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
                calView.calendarView.selectedDates = [selectedArr mutableCopy];
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
                calView.calendarView.selectedDates = [selectedArr mutableCopy];
            };
            
//            DLog(@"copied");
            [self presentViewController:calView animated:NO completion:nil];
//            DLog(@"presented");
        }else{
            DLog(@"empty date range... er... shite");
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

-(void) getCustomers{

//    NSURL *docs = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
//    NSString __block *path = nil;
//    if (docs)
//    {
//        path = [docs URLByAppendingPathComponent:kCustomerFile].path;
//        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
//            self.customerDB = [NSArray arrayWithContentsOfFile:path];
//            customersReady = YES;
//            [self postNotification];
//            return;
//        }
//    }
    
    NSString* url = [NSString stringWithFormat:@"%@?%@=%@",kDBGETCUSTOMERS,kAuthToken,self.authToken];
    DLog(@"Sending %@",url);
    ASIHTTPRequest* request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:url]];
    [request setNumberOfTimesToRetryOnTimeout:3];
    
    ASIHTTPRequest* __weak weakRequest = request;
    [request setCompletionBlock:^{
        ASIHTTPRequest* strongRequest = weakRequest;
        self.customerDB = [[strongRequest responseString] objectFromJSONString];
//        if (path != nil)
//        {
////            dispatch_queue_t writeQueue = dispatch_queue_create("writeQueue", NULL);
////            dispatch_async(writeQueue, ^{
//                [self.customerDB writeToFile:path atomically:YES];
////            });
//            path = nil;
//        }
        customersReady = YES;
        [self postNotification];
        
    }];
    
    [request setFailedBlock:^{
        self.customerDB = nil;
        [self dismissViewControllerAnimated:YES completion:nil];
        //DLog(@"error:%@", [request error]);
    }];
    
    [request startAsynchronous];
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
        [self.productCart removeObjectForKey:key];
        [self removeLineItemFromProductCart:[[dict objectForKey:@"id"] integerValue]];
    }
    DLog(@"qty change to %@ for index %@",[NSNumber numberWithDouble:qty],[NSNumber numberWithInt:idx]);
}

-(void)AddToCartForIndex:(int)idx{
    NSString* key = [[self.resultData objectAtIndex:idx] objectForKey:@"id"];
    DLog(@"add item at %d to cart",idx);
    NSMutableDictionary* dict = [[self.resultData objectAtIndex:idx] mutableCopy];
    NSMutableDictionary* editableDict = [editableData objectForKey:[dict objectForKey:@"id"]];
    
    NSMutableDictionary* edict = [self createIfDoesntExist:editableDict orig:dict];
    
    if (edict == nil ) {
        edict = editableDict;
    }
    
    [dict addEntriesFromDictionary:edict];
    
    DLog(@"after done touch(should never be nil):%@ vs %@ dict now:%@",edict, editableDict,dict);
    [self.productCart setObject:dict forKey:key];

    // add item to core data store
    [self addLineItemToProductCart:dict];

    DLog(@"cart now:%@",self.productCart);
}

#pragma mark - Core Data routines

// Adds a Cart object to the data store using the key/value pairs in the dictionary.
-(void)addLineItemToProductCart:(NSMutableDictionary*)dict {
    
//    NSError *error = nil;
//    int _id = [[dict objectForKey:kID] integerValue];
//    Cart *oldCart = nil;
//    NSFetchRequest *request = [[NSFetchRequest alloc] init];
//    [request setEntity:[NSEntityDescription entityForName:@"Cart" inManagedObjectContext:order.managedObjectContext]];
//    [request setPredicate:[NSPredicate predicateWithFormat:@"id=%@",[NSNumber numberWithInt:_id]]];
//    oldCart = [[order.managedObjectContext executeFetchRequest:request error:&error] lastObject];
//    
//    if (error) {
//    }
//
    
    Cart *oldCart = [order fetchCart:[[dict objectForKey:kID] integerValue]];
    
    if (!oldCart)
    {
        NSMutableDictionary *valuesForCart = [self convertForCoreData:dict];

        //NSManagedObject *cart = [NSEntityDescription insertNewObjectForEntityForName:@"Cart" inManagedObjectContext:order.managedObjectContext];
        Cart *cart = (Cart*)[coreDataManager createNewEntity:@"Cart"];
        [cart setValuesForKeysWithDictionary:valuesForCart];
        
        NSArray* dates = [dict objectForKey:kOrderItemShipDates];
        if (dates.count > 0)
        {
            NSMutableArray *shipDates = [NSMutableArray arrayWithCapacity:dates.count];
            //        NSDateFormatter* df = [[NSDateFormatter alloc] init];
            //        [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
            for(int i = 0; i < dates.count; i++){
                
                ShipDate *sd = (ShipDate *)[coreDataManager createNewEntity:@"ShipDate"];
//                NSManagedObject *sd = [NSEntityDescription insertNewObjectForEntityForName:@"ShipDate"
//                                                                    inManagedObjectContext:cart.managedObjectContext];
                [sd setShipdate:[dates objectAtIndex:i]];
                [sd setCart:cart];
                
                //[sd setValue:[dates objectAtIndex:i] forKey:@"shipdate"];
                
                [shipDates addObject:sd];
            }
            
            NSOrderedSet *orderedSet = [NSOrderedSet orderedSetWithArray:shipDates];
            [cart setValue:orderedSet forKey:@"shipdates"];
        }
        
        [order addCartsObject:cart];
    }
    else {
        [oldCart setEditableQty:[self getNumberFromDictionary:dict forKey:kEditableQty asFloat:NO]];
    }
    
    [coreDataManager saveObjects];
}

// This method takes the values in the dictionary and makes sure they are in the
// propery object format to be translated to the core data Cart entity.
-(NSMutableDictionary *)convertForCoreData:(NSMutableDictionary*)dict {
    NSMutableDictionary *cartValues = [NSMutableDictionary dictionaryWithCapacity:dict.count];
    
    [cartValues setValue:[self getNumberFromDictionary:dict forKey:kProductAdv asFloat:NO] forKey:kProductAdv];
    [cartValues setValue:[dict objectForKey:kProductCaseQty] forKey:kProductCaseQty];
    [cartValues setValue:[dict objectForKey:kVendorCompany] forKey:kVendorCompany];
    [cartValues setValue:[dict objectForKey:kVendorCreatedAt] forKey:kVendorCreatedAt];
    [cartValues setValue:[dict objectForKey:kProductDescr] forKey:kProductDescr];
    [cartValues setValue:[self getNumberFromDictionary:dict forKey:kProductDirShip asFloat:NO] forKey:kProductDirShip];
    [cartValues setValue:[self getNumberFromDictionary:dict forKey:kProductDiscount asFloat:YES] forKey:kProductDiscount];
    [cartValues setValue:[self getNumberFromDictionary:dict forKey:kEditablePrice asFloat:NO] forKey:kEditablePrice];
    [cartValues setValue:[self getNumberFromDictionary:dict forKey:kEditableQty asFloat:NO] forKey:kEditableQty];
    [cartValues setValue:[self getNumberFromDictionary:dict forKey:kEditableVoucher asFloat:YES] forKey:kEditableVoucher];
    [cartValues setValue:[self getNumberFromDictionary:dict forKey:kID asFloat:NO] forKey:kID];
    [cartValues setValue:[self getNumberFromDictionary:dict forKey:kProductIdx asFloat:NO] forKey:kProductIdx];
    [cartValues setValue:[self getNumberFromDictionary:dict forKey:kVendorImportID asFloat:NO] forKey:kVendorImportID];
    [cartValues setValue:[dict objectForKey:kVendorInitialShow] forKey:kVendorInitialShow];
    [cartValues setValue:[self getNumberFromDictionary:dict forKey:kProductInvtid asFloat:NO] forKey:kProductInvtid];
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
    [cartValues setValue:[self getNumberFromDictionary:dict forKey:kVendorVendID asFloat:NO] forKey:kVendorVendID];
    [cartValues setValue:[self getNumberFromDictionary:dict forKey:@"vendor_id" asFloat:NO] forKey:@"vendor_id"];
    [cartValues setValue:[dict objectForKey:kProductVoucher] forKey:kProductVoucher];
    
    return cartValues;
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
    Cart *oldCart = [order fetchCart:productId];
    if (oldCart) {
        [coreDataManager deleteObject:oldCart];
        [coreDataManager saveObjects];
    }
}

-(void)cancelOrder {
    if (isInitialized && order)
    {
        [coreDataManager deleteObject:order];
        [coreDataManager saveObjects];
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
    
    for( NSString* n in qty.allKeys){
        int j =[[qty objectForKey:n] intValue];
        if (j>highestQty) {
            highestQty = j;
            if (highestQty>0) {
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
    [self.products reloadData];
}

#pragma mark - keyboard functionality 
-(void)setViewMovedUp:(BOOL)movedUp
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.5]; // if you want to slide up the view
        
        CGPoint rect = self.products.contentOffset;
        if (movedUp)
        {
            // 1. move the view's origin up so that the text field that will be hidden come above the keyboard 
            // 2. increase the size of the view so that the area behind the keyboard is covered up.
            tOffset = rect.y;
            rect.y += (kOFFSET_FOR_KEYBOARD*6);//was -
            //rect.size.height += kOFFSET_FOR_KEYBOARD;
        }
        else
        {
            // revert back to the normal state.
            rect.y = tOffset;//-(kOFFSET_FOR_KEYBOARD-16);//was +
            //tOffset =0;
            //rect.size.height -= kOFFSET_FOR_KEYBOARD;
        }
        self.products.contentOffset = rect;
        
        [UIView commitAnimations];
    });
}

-(void)textEditBeginWithFrame:(CGRect)frame{
    int offset = frame.origin.y - self.products.contentOffset.y;
    DLog(@"cell edit begin, %d", offset);
    if (offset>=340) {
        [self setViewMovedUp:YES];
    }
    else{
        tOffset = self.products.contentOffset.y;
        DLog(@"offset to %d",tOffset);
        [self setViewMovedUp:NO];
    }
}

-(void)textEditEndWithFrame:(CGRect)frame{
    DLog(@"cell edit end");
//    [self setViewMovedUp:NO];
    [self.products reloadData];
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

#pragma mark - Search Delegate stuff


-(void)searchBar:(UISearchBar *)sBar textDidChange:(NSString *)searchText{
//    DLog(@"search did change:%@ - %@",sBar.text,searchText);
    if (self.productData == nil||[self.productData isKindOfClass:[NSNull class]]) {
        return;
    }
//    if (sBar == self.searchBar) {
        if ([searchText isEqualToString:@""]) {
            self.resultData = [self.productData mutableCopy];
            DLog(@"string is empty");
        }else{
            
            NSPredicate* pred = [NSPredicate predicateWithBlock:^BOOL(id obj, NSDictionary* bindings){
                NSMutableDictionary* dict = (NSMutableDictionary*)obj;
                
                NSString *invtid = nil;
				
                
				DLog(@"Text : %@", [dict objectForKey:kProductDescr]);
				
                if ([dict objectForKey:kProductInvtid] && ![[dict objectForKey:kProductInvtid] isKindOfClass:[NSNull class]]) {
                    invtid = [dict objectForKey:kProductInvtid];
				 
               }else{
                    invtid = @"";
                }
				NSString *descrip = [dict objectForKey:kProductDescr];
//                DLog(@"invtid:%@ - %@, %@",invtid,sBar.text,([invtid hasPrefix:sBar.text]?@"YES":@"NO"));
                
                return [invtid hasPrefix:searchText] || [[descrip uppercaseString] contains:[searchText uppercaseString]];
            }];
            
            self.resultData = [[self.productData filteredArrayUsingPredicate:pred] mutableCopy];
            [selectedIdx removeAllObjects];
            DLog(@"results count:%d", self.resultData.count);
        }
        [self.products reloadData];
//    }
}

/*

-(void)searchBarTextDidBeginEditing:(UISearchBar *)sBar{
	
	[self searchBar:sBar textDidChange:sBar.text];
	
	
}

-(void)searchBarTextDidEndEditing:(UISearchBar *)sBar{
	
	[self searchBar:sBar textDidChange:sBar.text];

} */

@end