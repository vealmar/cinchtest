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

@interface CIProductViewController (){
    //MBProgressHUD* loading;
    int currentVendor;
    NSArray* vendorsData;
    NSMutableDictionary* editableData;
    NSMutableSet* selectedIdx;
//    void(^loadCustomers)(void);
    BOOL isInitialized;
//    CoreDataUtil* coreDataManager;
    UITapGestureRecognizer *gestureRecognizer;
    UITextField *currentTextField;
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

#pragma mark - constructor

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        showPrice = YES;
        backFromCart = NO;
        tOffset = 0;
        currentVendor = 0;
        productCart = [NSMutableDictionary dictionary];
        editableData = [NSMutableDictionary dictionary];
        selectedIdx = [NSMutableSet set];
        multiStore = NO;
        isInitialized = NO;
        _showCustomers = YES;
        currentTextField = nil;
    }
	
	reachDelegation = [[ReachabilityDelegation alloc] initWithDelegate:self withUrl:kBASEURL];
    return self;
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
        if (self.vendorGroup && ![self.vendorGroup isKindOfClass:[NSNull class]]) {
            url = [NSString stringWithFormat:@"%@?%@=%@&%@=%@",kDBGETPRODUCTS,kAuthToken,self.authToken,kVendorGroupID,self.vendorGroup];
        }else {
            url = [NSString stringWithFormat:@"%@?%@=%@",kDBGETPRODUCTS,kAuthToken,self.authToken];
        }
        
        [self loadProductsForUrl:url withLoadLabel:@"Loading Products..."];
        
        navBar.topItem.title = self.title;
    }
    
	self.vendorLabel.text = [[SettingsManager sharedManager] lookupSettingByString:@"username"];
    [self.vendorTable reloadData];
}

- (void)viewDidDisappear:(BOOL)animated
{
    // unregister for keyboard notifications while not visible.
    //[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];

//    [self.products removeGestureRecognizer:gestureRecognizer];
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
    
    DLog(@"Sending %@",url);
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    AFJSONRequestOperation *jsonOp = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
             success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                 
                 self.productData = [JSON mutableCopy];
                 
//                 [JSON enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
//                     [self.productData replaceObjectAtIndex:idx withObject:[obj mutableCopy]];
//                 }];
                 
                 self.resultData = [self.productData mutableCopy];
                 [JSON enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                     [self.resultData replaceObjectAtIndex:idx withObject:[obj mutableCopy]];
                 }];
                 
                 [self.products reloadData];
                 [loadProductsHUD hide:NO];
                 if (_showCustomers) {
                     [self loadCustomersView];
                 } else {
//                     [[NSNotificationCenter defaultCenter] postNotificationName:@"SetCustomer" object:nil];
                     [self getCustomers];
                 }
                 
             } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                 
                 [[[UIAlertView alloc] initWithTitle:@"Error!" message:error.localizedDescription delegate:nil
                                   cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
                 [loadProductsHUD hide:NO];
             }];

    [jsonOp start];
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

#pragma mark - UITableView Datasource

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)myTableView numberOfRowsInSection:(NSInteger)section {
    if (self.resultData && myTableView == self.products) {
        return [self.resultData count];
    }else if (vendorsData && myTableView == self.vendorTable) {
        return vendorsData.count;
    }
    return 0;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSMutableDictionary* dict = [self.resultData objectAtIndex:[indexPath row]];
    NSMutableDictionary* editableDict = [editableData objectForKey:[dict objectForKey:@"id"]];
    BOOL hasQty = NO;
    
    //if you want it to highlight based on qty uncomment this:
    if (multiStore && editableDict && [[editableDict objectForKey:kEditableQty] isKindOfClass:[NSString class]]
        && [[[editableDict objectForKey:kEditableQty] objectFromJSONString] isKindOfClass:[NSDictionary class]]
        && ((NSDictionary*)[[editableDict objectForKey:kEditableQty] objectFromJSONString]).allKeys.count>0) {
        for(NSNumber* n in [[[editableDict objectForKey:kEditableQty] objectFromJSONString] allObjects]){
            if(n>0)
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
        if (hasQty ^ hasShipDates) {
            UIView *view = [[UIView alloc] initWithFrame:cell.frame];
            view.backgroundColor = [UIColor colorWithRed:0.839 green:0.655 blue:0.655 alpha:0.75];
            cell.backgroundView = view;
        } else if (hasQty && hasShipDates) {
            UIView *view = [[UIView alloc] initWithFrame:cell.frame];
            view.backgroundColor = [UIColor colorWithRed:0.722 green:0.871 blue:0.765 alpha:0.75];
            cell.backgroundView = view;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)myTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (!self.resultData && myTableView==self.products) {
        return nil;
    }
    if (!vendorsData && myTableView==self.vendorTable) {
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
            cell = [topLevelObjects objectAtIndex:0];
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
        
        cell.regPrc.text = ([[editableDict objectForKey:kOrderItemShipDates] isKindOfClass:[NSArray class]]
                            ? [NSString stringWithFormat:@"%d",((NSArray*)[editableDict objectForKey:kOrderItemShipDates]).count]:@"0");
        
        if (editableDict&&[editableDict objectForKey:kEditableQty] && !multiStore) {
            
            cell.quantity.text = [[editableDict objectForKey:kEditableQty] stringValue];
        }
        else
            cell.quantity.text = @"0";
        cell.qtyLbl.hidden = YES;
        
        if ([[customer objectForKey:kStores] isKindOfClass:[NSArray class]] && [((NSArray*)[customer objectForKey:kStores]) count]>0) {
            multiStore = YES;
            cell.qtyBtn.hidden = NO;
            cell.qtyLbl.hidden = YES;
            cell.quantity.hidden = YES;
        }
        
        if (editableDict && [editableDict objectForKey:kEditableVoucher]) {
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
        
        if (showPrice && editableDict && [editableDict objectForKey:kEditablePrice]) {
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
        
//        BOOL hasQty = NO;
//        
//        //if you want it to highlight based on qty uncomment this:
//        if (multiStore && editableDict && [[editableDict objectForKey:kEditableQty] isKindOfClass:[NSString class]]
//            && [[[editableDict objectForKey:kEditableQty] objectFromJSONString] isKindOfClass:[NSDictionary class]]
//            && ((NSDictionary*)[[editableDict objectForKey:kEditableQty] objectFromJSONString]).allKeys.count>0) {
//            for(NSNumber* n in [[[editableDict objectForKey:kEditableQty] objectFromJSONString] allObjects]){
//                if(n>0)
//                    hasQty = YES;
//            }
//        }else if (editableDict&&[editableDict objectForKey:kEditableQty]&&[[editableDict objectForKey:kEditableQty] isKindOfClass:[NSString class]]&&[[editableDict objectForKey:kEditableQty] integerValue] >0){
//            hasQty = YES;
//        }else if (editableDict&&[editableDict objectForKey:kEditableQty]&&[[editableDict objectForKey:kEditableQty] isKindOfClass:[NSNumber class]]&&[[editableDict objectForKey:kEditableQty] intValue] > 0){
//            hasQty = YES;
//        }else{
//            cell.backgroundView = nil;
//        }
//        
//        BOOL hasShipDates = NO;
//        NSArray *shipDates = [editableDict objectForKey:kOrderItemShipDates];
//        if (shipDates && [shipDates count] > 0) {
//            hasShipDates = YES;
//        }
//        
//        if (hasQty ^ hasShipDates) {
//            UIView *view = [[UIView alloc] initWithFrame:cell.frame];
//            view.backgroundColor = [UIColor colorWithRed:0.839 green:0.655 blue:0.655 alpha:0.75];
//            cell.backgroundView = view;
//        } else if (hasQty && hasShipDates) {
//            UIView *view = [[UIView alloc] initWithFrame:cell.frame];
//            view.backgroundColor = [UIColor colorWithRed:0.722 green:0.871 blue:0.765 alpha:0.75];
//            cell.backgroundView = view;
//        }
        
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
            if (self.vendorGroup && ![self.vendorGroup isKindOfClass:[NSNull class]]) {
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
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (IBAction)Cancel:(id)sender {
    [self Cancel];
}

- (void)createNewOrderForCustomer:(NSNumber *)customerId andStore:(NSNumber *)custId
{
    NSManagedObjectContext *context = self.managedObjectContext;
    _order = [NSEntityDescription insertNewObjectForEntityForName:@"Order" inManagedObjectContext:context];
    [_order setBillname:self.customerLabel.text];
    [_order setCustomer_id:[customerId intValue]];
    [_order setCustid:[custId intValue]];
    [_order setMultiStore:multiStore];
    [_order setStatus:@"pending"];
    [_order setCreated_at:[NSDate timeIntervalSinceReferenceDate]];
    NSError *error = nil;
    BOOL success = [context save:&error];
    if (!success) {
        DLog(@"Error saving new order: %@", [error localizedDescription]);
        NSString *msg = [NSString stringWithFormat:@"Error saving new order: %@", [error localizedDescription]];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
    }
}

- (void)deserializeOrder
{
    NSDateFormatter* df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
    
    for (Cart *cart in _order.carts) {
        NSMutableDictionary *item = [[NSMutableDictionary alloc] init];
        [item setObject:[NSString stringWithFormat:@"%d", cart.adv] forKey:kProductAdv];
        [item setObject:cart.caseqty forKey:kProductCaseQty];
        [item setObject:cart.company forKey:kVendorCompany];
        [item setObject:cart.created_at forKey:@"created_at"];
        [item setObject:cart.descr forKey:kProductDescr];
        [item setObject:[NSString stringWithFormat:@"%d", cart.dirship] forKey:kProductDirShip];
        [item setObject:[NSNumber numberWithFloat:cart.discount] forKey:kProductDiscount];
        [item setObject:[NSNumber numberWithFloat:cart.editablePrice] forKey:kEditablePrice];
        
        if (!_order.multiStore) {
            NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
            [f setNumberStyle:NSNumberFormatterBehavior10_4];
            [item setObject:[f numberFromString:cart.editableQty] forKey:kEditableQty];
        } else {
            [item setObject:cart.editableQty forKey:kEditableQty];
        }
        [item setObject:[NSNumber numberWithFloat:cart.editableVoucher] forKey:kEditableVoucher];
        [item setObject:[NSNumber numberWithInt:cart.cartId] forKey:@"id"];
        [item setObject:[NSNumber numberWithInt:cart.idx] forKey:kProductIdx];
        [item setObject:[NSNumber numberWithInt:cart.import_id] forKey:kVendorImportID];
        [item setObject:[NSString stringWithFormat:@"%d", cart.invtid] forKey:kProductInvtid];
        [item setObject:cart.initial_show == nil ? @"" : cart.initial_show forKey:kVendorInitialShow];
        [item setObject:cart.linenbr forKey:kProductLineNbr];
        [item setObject:[NSString stringWithFormat:@"%d", cart.new] forKey:kProductNew];
        [item setObject:cart.partnbr == nil ? @"" : cart.partnbr forKey:kProductPartNbr];
        [item setObject:cart.regprc == nil ? @"" : cart.regprc forKey:kProductRegPrc];
        [item setObject:cart.shipdate1 forKey:kProductShipDate1];
        [item setObject:cart.shipdate2 forKey:kProductShipDate2];
        
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
        [item setObject:[NSNumber numberWithInt:cart.vendid] forKey:kVendorVendID];
        [item setObject:[NSNumber numberWithInt:cart.vendor_id] forKey:@"vendor_id"];
        [item setObject:cart.voucher forKey:kProductVoucher];
        
        [self.productCart setObject:item forKey:[NSNumber numberWithInt:cart.cartId]];
        
        NSNumber *invt_id = [NSNumber numberWithInt:cart.invtid];
        NSUInteger index = [self.resultData indexOfObjectPassingTest:^BOOL(id dictionary, NSUInteger idx, BOOL *stop) {
            NSNumber *prodId = [NSNumber numberWithInt:[[dictionary objectForKey:kProductInvtid] intValue]];
//            *stop = [[dictionary objectForKey:kProductInvtid] isEqualToNumber:invt_id];
            *stop = [prodId isEqualToNumber:invt_id];
            return *stop;
        }];
        if (index != NSNotFound) {
            NSMutableDictionary* dict = [self.resultData objectAtIndex:index];
            NSMutableDictionary* editableDict = [editableData objectForKey:[dict objectForKey:@"id"]];
            NSMutableDictionary* edict = [self createIfDoesntExist:editableDict orig:dict];
            
            if (edict == nil ) {
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

//- (IBAction)logout:(id)sender {
//    [self logout];
//}

-(void)setCustomerInfo:(NSDictionary*)info
{
    //[loading hide:YES];
    [self.products reloadData];
    
    self.customer = [info copy];
    DLog(@"set customerinfo:%@",self.customer);

    if ([self.customer objectForKey:kBillName]) {
        self.customerLabel.text = [self.customer objectForKey:kBillName];
    }
    
    NSNumber *custId = [NSNumber numberWithInt:[[self.customer objectForKey:@"custid"] integerValue]];
    
    if (!isInitialized) {
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        [fetchRequest setEntity:[NSEntityDescription entityForName:@"Order" inManagedObjectContext:managedObjectContext]];

        NSNumber *customerId = [NSNumber numberWithInt:[[self.customer objectForKey:@"id"] integerValue]];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(customer_id = %@) AND (custid = %@)", customerId, custId];
        [fetchRequest setPredicate:predicate];

        NSArray *keys = [NSArray arrayWithObjects:@"carts", @"carts.shipdates", nil];
        [fetchRequest setRelationshipKeyPathsForPrefetching:keys];
        [fetchRequest setReturnsObjectsAsFaults:NO];
        NSError *error = nil;
        NSArray *fetchedObjects = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
        if (!error && [fetchedObjects count] > 0) {
            _order = [fetchedObjects objectAtIndex:0];
        }
        
        if (_order)
        {
            if (_showCustomers) {
                NSString *useExisting = @"Use Existing";
                NSString *createNew = @"Create New";
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Confirm" message:@"A pending order exists for this customer. Would you like to use the existing order or delete it and start a new order?"
                                                               delegate:nil cancelButtonTitle:useExisting otherButtonTitles:createNew, nil];
                [UIAlertViewDelegateWithBlock showAlertView:alert withCallBack:^(NSInteger buttonIndex) {
                    
                    if (buttonIndex == 0) {
                        [self deserializeOrder];
                    } else {
                        [[CoreDataUtil sharedManager] deleteObject:_order];
                        _order = nil;
                        [self createNewOrderForCustomer:customerId andStore:custId];
                    }
                    
                }];
            } else {
                [self deserializeOrder];
            }
        } else {
            [self createNewOrderForCustomer:customerId andStore:custId];
            isInitialized = YES;
        }
    }
    else {
        if (_order.custid != [custId intValue])
            [_order setCustid:[custId intValue]];
        
        [[CoreDataUtil sharedManager] saveObjects];
    }
}

- (IBAction)submit:(id)sender {
    MBProgressHUD* submit = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    submit.labelText = @"Submitting order...";
    [submit show:YES];
    
    //NSMutableArray* arr = [[NSMutableArray alloc] initWithCapacity:[self.products numberOfRowsInSection:0]];
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    
    //    NSNumberFormatter* nf = [[NSNumberFormatter alloc] init];
    //    [nf setNumberStyle:NSNumberFormatterCurrencyStyle];
    NSArray* keys = self.productCart.allKeys;
    for (NSNumber* i in keys) {
        NSString* productID = [i stringValue];//[[self.productData objectAtIndex:] objectForKey:@"id"];
//        CIProductCell* cell = (CIProductCell*)[self.products cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i.intValue inSection:0]];
        NSDictionary* dict = [self.productCart objectForKey:i];
        
//        BOOL hasQty = NO;
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
        
//        BOOL hasShipDates = NO;
        if (num > 0) {
//            hasQty = YES;
            NSArray* dates = [dict objectForKey:kOrderItemShipDates];
            NSMutableArray* strs = [NSMutableArray array];
            
            NSDateFormatter* df = [[NSDateFormatter alloc] init];
            [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
            for(int i = 0; i < dates.count; i++){
                NSString* str = [df stringFromDate:[dates objectAtIndex:i]];
                [strs addObject:str];
            }
            
            if ([strs count] > 0) {
//                hasShipDates = YES;
                
                NSString *ePrice = [[dict objectForKey:kEditablePrice] stringValue];
                NSString *eVoucher = [[dict objectForKey:kEditableVoucher] stringValue];
                NSDictionary* proDict = [NSDictionary dictionaryWithObjectsAndKeys:productID,kOrderItemID,[dict objectForKey:kEditableQty],kOrderItemNum,ePrice,kOrderItemPRICE,eVoucher,kOrderItemVoucher,strs,kOrderItemShipDates, nil];
                [arr addObject:(id)proDict];
            }
        }
        
//        if (!hasQty || !hasShipDates) {
//            [submit hide:YES];
//            [[[UIAlertView alloc] initWithTitle:@"Missing Data" message:@"All items in the cart must have a quantity and ship date(s) before the order can be submitted. Check cart items and tray again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
//            return;
//        }
    }
    
    [arr removeObjectIdenticalTo:nil];
    
    DLog(@"array:%@",arr);
    
    if (!self.customer) {
        return;
    }

//    NSDictionary* newOrder = [NSDictionary dictionaryWithObjectsAndKeys:[self.customer objectForKey:@"id"],kOrderCustID, [self.customer objectForKey:kShipNotes],kShipNotes,
//                [self.customer objectForKey:kNotes],kNotes, [self.customer objectForKey:kAuthorizedBy],kAuthorizedBy,
//                [self.customer objectForKey:kEmail],kEmail, [self.customer objectForKey:kSendEmail], kSendEmail, arr, kOrderItems, nil];
    
    NSDictionary* newOrder = [NSDictionary dictionaryWithObjectsAndKeys:[self.customer objectForKey:@"id"],kOrderCustID, [self.customer objectForKey:kShipNotes],kShipNotes, [self.customer objectForKey:kNotes],kNotes, [self.customer objectForKey:kAuthorizedBy],kAuthorizedBy,arr, kOrderItems, nil];

    
    //    }
    //    else{
    //        order = [NSDictionary dictionaryWithObjectsAndKeys:[info objectForKey:kCustName],kCustName,[info objectForKey:kStoreName],kStoreName,[info objectForKey:kCity],kCity,arr,kOrderItems, nil];
    //    }
    
    NSDictionary* final = [NSDictionary dictionaryWithObjectsAndKeys:newOrder,kOrder, nil];
    
    NSString *url = [NSString stringWithFormat:@"%@?%@=%@",kDBORDER,kAuthToken,self.authToken];
    DLog(@"final JSON:%@\nURL:%@",[final JSONString],url);
    
    AFHTTPClient *client = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:url]];
    [client setParameterEncoding:AFJSONParameterEncoding];
    NSMutableURLRequest *request = [client requestWithMethod:@"POST" path:nil parameters:final];

    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
        success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
            
            [submit hide:YES];
            
            NSString *status = [JSON valueForKey:@"status"];
            DLog(@"status = %@", status);

            [[CoreDataUtil sharedManager] deleteObject:_order];
            _order = nil;
            [self Return];
            
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
            
            [submit hide:YES];
            NSString *errorMsg = [NSString stringWithFormat:@"There was an error submitting the order. %@", error.localizedDescription];
            [[[UIAlertView alloc] initWithTitle:@"Error!" message:errorMsg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
            
        }];
    
    [operation start];
}

-(void) Return{
    [self dismissViewControllerAnimated:YES completion:^{
        if (self.delegate) {
            [self.delegate Return];
        }
    }];
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
                if (j>num) {
                    num = j;
                    if (num>0) {
                        break;
                    }
                }
            }
        }
        
        BOOL hasShipDates = NO;
        if (num>0) {
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
        
        BOOL isVoucher = [dict objectForKey:kProductIdx] == 0 && [dict objectForKey:kProductInvtid] == 0;
        
        if (!isVoucher && (!hasQty || !hasShipDates)) {
            [[[UIAlertView alloc] initWithTitle:@"Missing Data" message:@"All items in the cart must have a quantity and ship date(s) before the order can be submitted. Check cart items and tray again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
            return NO;
        }
    }
    
    return YES;
}

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

- (IBAction)reviewCart:(id)sender {
    [self.hiddenTxt becomeFirstResponder];
    [self.hiddenTxt resignFirstResponder];
 
    CICartViewController* cart = [[CICartViewController alloc] initWithNibName:@"CICartViewController" bundle:nil];
    cart.delegate = self;
//    cart.finishTheOrder = ^{
//        [self finishOrder:nil];  
//    };
    cart.customerDB = self.customerDB;
    cart.productData = [NSMutableDictionary dictionaryWithDictionary:self.productCart];
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
    
    if (vendorsData == nil) {
        MBProgressHUD* venderLoading = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        venderLoading.labelText = @"Loading vendors from your vendor group...";
        [venderLoading show:YES];
        
        if (self.vendorGroup && ![self.vendorGroup isKindOfClass:[NSNull class]]) {
            
            NSString* url = [NSString stringWithFormat:@"%@&%@=%@",kDBGETVENDORSWithVG(self.vendorGroup),kAuthToken,self.authToken];
            NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
            AFJSONRequestOperation *jsonOp = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                 success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {

                     NSArray *results = [NSArray arrayWithArray:JSON];
                     if (!results || ![results objectAtIndex:0] || ![[results objectAtIndex:0] objectForKey:@"vendors"]) {
                         [venderLoading hide:YES];
                         [[[UIAlertView alloc] initWithTitle:@"Error!" message:@"Problem loading vendors! If this problem persists people notify Convention Innovations!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
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

                 } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {

                     [[[UIAlertView alloc] initWithTitle:@"Error!"
                                 message:[NSString stringWithFormat:@"Got error retrieving vendors for vendor group:%@", error.localizedDescription]
                                    delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
                     
                     vendorsData = [NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:@"Any",kVendorUsername,@"0",@"id", nil], nil];
                     [venderLoading hide:YES];
                     [self.vendorTable reloadData];
                 }];
            
            [jsonOp start];
            
        }else{
            [venderLoading hide:YES];
            vendorsData = [NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:@"Any",kVendorUsername,@"0",@"id", nil], nil];
            [self.vendorTable reloadData];
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
        
// FIXME: Setup calendar to show starting at current date
        NSDate* startDate = [[NSDate alloc]init];
        NSDate* endDate = [[NSDate alloc]init];

        DLog(@"about to get data from cell");
        if([dict objectForKey:kProductShipDate1] && ![[dict objectForKey:kProductShipDate1] isKindOfClass:[NSNull class]]){
            startDate = [df dateFromString:[dict objectForKey:kProductShipDate1]];
        }
        
        if([dict objectForKey:kProductShipDate2] && ![[dict objectForKey:kProductShipDate2] isKindOfClass:[NSNull class]]){
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
            
            if (edict == nil ) {
                edict = editableDict;
            }
            
            DLog(@"after done touch(should never be nil):%@ vs orig%@",edict,editableDict);
            
            [edict setObject:dates forKey:kOrderItemShipDates];
            [editableData setObject:edict forKey:[dict objectForKey:@"id"]];
            
            DLog(@"done Touch idx(%@) iedict:%@ full data is now:%@",idx,edict,[editableData objectForKey:[dict objectForKey:@"id"]]);
            DLog(@"DT cart data:%@",self.productCart);
            
            if ([self.productCart objectForKey:[dict objectForKey:@"id"]]) {
//                DLog(@"index(%@) shipdates updated to: %@",idx,dates);
//                NSMutableDictionary* dict2 = [self.productCart objectForKey:[dict objectForKey:@"id"]];
//                [dict2 setObject:dates forKey:kOrderItemShipDates];
                
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
                return [[obj objectForKey:kID] intValue] == self.customerId;
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
        [self.productCart removeObjectForKey:key];
        [self removeLineItemFromProductCart:[[dict objectForKey:@"id"] integerValue]];
    }
    
    [self updateCellColorForId:idx];
    
    DLog(@"qty change to %@ for index %@",[NSNumber numberWithDouble:qty],[NSNumber numberWithInt:idx]);
}

//-(void)setRowColorForIndex:(BOOL)isReady {
//    NSIndexPath *indexPath = [NSIndexPath indexPathWithIndex:idx];
//    
//    
//    UITableViewCell *cell = [self.products cellForRowAtIndexPath:indexPath];
//    if (cell != nil) {
//        [cell setBackgroundColor:[[UIColor redColor] colorByChangingAlphaTo:0.75]];
//    }
//}

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
        
        [cart setValuesForKeysWithDictionary:valuesForCart];
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
    
    [cartValues setValue:[self getNumberFromDictionary:dict forKey:kProductAdv asFloat:NO] forKey:kProductAdv];
    [cartValues setValue:[dict objectForKey:kProductCaseQty] forKey:kProductCaseQty];
    [cartValues setValue:[dict objectForKey:kVendorCompany] forKey:kVendorCompany];
    [cartValues setValue:[dict objectForKey:kVendorCreatedAt] forKey:kVendorCreatedAt];
    [cartValues setValue:[dict objectForKey:kProductDescr] forKey:kProductDescr];
    [cartValues setValue:[self getNumberFromDictionary:dict forKey:kProductDirShip asFloat:NO] forKey:kProductDirShip];
    [cartValues setValue:[self getNumberFromDictionary:dict forKey:kProductDiscount asFloat:YES] forKey:kProductDiscount];
    [cartValues setValue:[self getNumberFromDictionary:dict forKey:kEditablePrice asFloat:YES] forKey:kEditablePrice];
    if (!multiStore) {
        [cartValues setValue:[[dict objectForKey:kEditableQty] stringValue] forKey:kEditableQty];
    } else {
        [cartValues setValue:[dict objectForKey:kEditableQty] forKey:kEditableQty];
    }
    [cartValues setValue:[self getNumberFromDictionary:dict forKey:kEditableVoucher asFloat:YES] forKey:kEditableVoucher];
    [cartValues setValue:[self getNumberFromDictionary:dict forKey:kID asFloat:NO] forKey:kID];
    [cartValues setValue:[self getNumberFromDictionary:dict forKey:kProductIdx asFloat:NO] forKey:kProductIdx];
//    if ([dict objectForKey:kVendorImportID] && ![[dict objectForKey:kVendorImportID] isKindOfClass:[NSNull class]]) {
    if ([dict objectForKey:kVendorImportID] && ![[dict objectForKey:kVendorImportID] isEqual:[NSNull null]]) {
        [cartValues setValue:[self getNumberFromDictionary:dict forKey:kVendorImportID asFloat:NO] forKey:kVendorImportID];
    } else {
        [cartValues setValue:[NSNull null] forKey:kVendorImportID];
    }
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
            [cart removeShipdates:[cart shipdates]];
            for (NSDate *aDate in sortedDates) {
                ShipDate *sd = [NSEntityDescription insertNewObjectForEntityForName:@"ShipDate" inManagedObjectContext:cart.managedObjectContext];
                [cart addShipdatesObject:sd];
                [sd setShipdate:[aDate timeIntervalSinceReferenceDate]];
            }
            
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
    for (CIProductCell *cell in cells) {
        if ([invtid isEqualToString:cell.InvtID.text]) {
            BOOL hasQty = NO;
            
            //if you want it to highlight based on qty uncomment this:
            if (multiStore && editableDict && [[editableDict objectForKey:kEditableQty] isKindOfClass:[NSString class]]
                && [[[editableDict objectForKey:kEditableQty] objectFromJSONString] isKindOfClass:[NSDictionary class]]
                && ((NSDictionary*)[[editableDict objectForKey:kEditableQty] objectFromJSONString]).allKeys.count>0) {
                for(NSNumber* n in [[[editableDict objectForKey:kEditableQty] objectFromJSONString] allObjects]){
                    if(n>0)
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
                if (hasQty ^ hasShipDates) {
                    UIView *view = [[UIView alloc] initWithFrame:cell.frame];
                    view.backgroundColor = [UIColor colorWithRed:0.839 green:0.655 blue:0.655 alpha:0.75];
                    cell.backgroundView = view;
                } else if (hasQty && hasShipDates) {
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
                    invtid = [[dict objectForKey:kProductInvtid] stringValue];
				 
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

#pragma mark - Reachability delegate methods

-(void)networkLost {
	
	[ciLogo setImage:[UIImage imageNamed:@"ci_red.png"]];
}

-(void)networkRestored {
	
	[ciLogo setImage:[UIImage imageNamed:@"ci_green.png"]];
}

@end