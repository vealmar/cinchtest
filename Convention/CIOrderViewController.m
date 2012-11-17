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
#import "ASIHTTPRequest.h"
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

@interface CIOrderViewController (){
    int currentOrderID;
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

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        masterVender = NO;
        currentVender = 0;
        currentOrderID = 0;
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



-(void)loadOrders {
	
	self.OrderDetailScroll.hidden = YES;
	
	MBProgressHUD* __weak order = [MBProgressHUD showHUDAddedTo:self.sideTable animated:YES];
    order.labelText = @"Getting Orders...";
    
    [order show:YES];
	
    
    NSString* url = [NSString stringWithFormat:@"%@?%@=%@",kDBORDER,kAuthToken,self.authToken];
	 
    if (masterVender) {
        url = [NSString stringWithFormat:@"%@?%@=%@",kDBMasterORDER,kAuthToken,self.authToken];
    }
    DLog(@"Sending %@",url);
    ASIHTTPRequest* request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:url]];
    ASIHTTPRequest* __weak weakRequest = request;
    [request setNumberOfTimesToRetryOnTimeout:3];
    [request setCompletionBlock:^{
        ASIHTTPRequest* strongRequest = weakRequest;
        //DLog(@"response:%@",[strongRequest responseString]);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.orders = [[[strongRequest responseString] objectFromJSONString] mutableCopy];
			
			
			
			//        DLog(@"data:%@",data);
			self.orderData = [self.orders mutableCopy];
			//PW---        if (showPrice) {
			for( int i=0;i< self.orderData.count;i++){
				NSMutableDictionary* dict = [[self.orderData objectAtIndex:i] mutableCopy];
				
				//            DLog(@"invtid:%@",[dict objectForKey:kProductInvtid]);
				
				[self.orderData removeObjectAtIndex:i];
				[self.orderData insertObject:dict atIndex:i];
			}
			//        }
			//        DLog(@"Json:%@",self.productData);
			 
			 
			
            [self.sideTable reloadData];
			//[self.sideTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
            //[self.sideTable selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionTop];
            
            if ([self.orders count] > 0) {
                self.NoOrders.hidden = YES;
            }
            
            [order hide:YES];
        });
    }];
	
    [request setFailedBlock:^{
        ASIHTTPRequest* strongRequest = weakRequest;
        //DLog(@"error:%@", [strongRequest error]);
        [[[UIAlertView alloc] initWithTitle:@"Error!" message:[NSString stringWithFormat:@"There was an error loading orders:%@",[strongRequest error]] delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
        [order hide:YES];
    }];
    
    [request startAsynchronous];
	
	
	
	
	
	
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
    
  
	
	self.sideTable.contentOffset = CGPointMake(0, self.sBar.frame.size.height);
	
	[self loadOrders];
	
	
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
    [self setOrderDetailScroll:nil];
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

#pragma mark - UITableView Datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

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
            
            for(id currentObject in topLevelObjects)
            {
                if([currentObject isKindOfClass:[CIOrderCell class]])
                {
                    cell = (CIOrderCell *)currentObject;
                    break;
                }
            }
        }
        
        NSDictionary* data = [orders objectAtIndex:[indexPath row]];
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
        
//        DLog(@"Cell(%@-%@) is set to tag:%d",cell.Customer.text,cell.auth.text,cell.tag);
        
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
            
            for(id currentObject in topLevelObjects)
            {
                if([currentObject isKindOfClass:[CIItemEditCell class]])
                {
                    cell = (CIItemEditCell *)currentObject;
                    break;
                }
            }
        }
        
        cell.delegate = self;
        
        //cell.textLabel.text = [NSString stringWithFormat:@"%@ - %@", [[self.itemsDB objectAtIndex:[indexPath row]] objectForKey:kBillName],[[self.itemsDB objectAtIndex:[indexPath row]] objectForKey:kCustID]];
        //cell.tag = [[[self.itemsDB objectAtIndex:[indexPath row]] objectForKey:kID] intValue];
        if ([[self.itemsDB objectForKey:kItemCount] intValue]>[indexPath row]) {
            NSDictionary* data = [[self.itemsDB objectForKey:kItems] objectAtIndex:[indexPath row]];
            //DLog(@"items: %@",data);
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
            }else{
                //                DLog(@"not JSON err:%@, dict:%@",err,dict);
            }
            
            if (isJSON) {
                cell.qtyBtn.hidden = NO;
                
                for (NSString* key in dict.allKeys) {
                    q += [[dict objectForKey:key] doubleValue];
                }
            }
            
            int lblsd = 0;
            int nd = 1;
            if (((NSArray*)[self.itemsShipDates objectAtIndex:indexPath.row]).count>0) {
                nd = ((NSArray*)[self.itemsShipDates objectAtIndex:indexPath.row]).count;
                lblsd = nd;
            }
            
            DLog(@"Shipdate count:%d nd:%d array:%@",((NSArray*)[self.itemsShipDates objectAtIndex:indexPath.row]).count,nd,((NSArray*)[self.itemsShipDates objectAtIndex:indexPath.row]));
            
            cell.btnShipdates.titleLabel.text = [NSString stringWithFormat:@"SD:%d",lblsd];
            
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
                cell.price.hidden = YES;
                cell.total.text = [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithDouble:(price * q * nd)] numberStyle:NSNumberFormatterCurrencyStyle];
            }
            else {
                cell.price.text = @"0.00";
                cell.priceLbl.text = cell.price.text;
                cell.price.hidden = YES;
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

#pragma mark - UITableView Delegate methods

-(void)QtyChange:(double)qty forIndex:(int)idx {
	
	//Not Imlemented
}



- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.sideTable) {
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
        
        NSString* url = [NSString stringWithFormat:@"%@?%@=%@",[NSString stringWithFormat:kDBORDEREDIT(cell.tag)],kAuthToken,self.authToken];
        //        DLog(@"Sending edit order %@",url);
        ASIHTTPRequest* request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:url]];
        //        [request setTimeOutSeconds:10.f];
        ASIHTTPRequest* __weak weakRequest = request;
        [request setNumberOfTimesToRetryOnTimeout:3];
        
        [request setCompletionBlock:^{
            
            ASIHTTPRequest* strongRequest = weakRequest;
            
            //DLog(@"order response:%@",[request responseString]);
            //dispatch_async(dispatch_get_main_queue(), ^{
            self.itemsDB = [[strongRequest responseString] objectFromJSONString];
            NSArray* arr = [self.itemsDB objectForKey:kItems];
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
            
            __block NSMutableArray* SDs = [NSMutableArray array];
            
            [self.itemsShipDates enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                __block NSMutableArray* dates = (NSMutableArray*)obj;
                [dates enumerateObjectsUsingBlock:^(id obj1, NSUInteger idx1, BOOL *stop1) {
                    NSDate* date = (NSDate*)obj1;
                    if (![SDs containsObject:date]) {
                        [SDs addObject:date];
                    }
                }];
            }];
            
            __block NSString* sdtext = @"";
            
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
            //});
        }];
        
        [request setFailedBlock:^{
            ASIHTTPRequest* strongRequest = weakRequest;
            self.itemsPrice = [NSMutableArray array];
            self.itemsQty = [NSMutableArray array];
            
            self.itemsAct.hidden = YES;
            [self.itemsAct stopAnimating];
            if (strongRequest.error.code == 2) {
                [[[UIAlertView alloc] initWithTitle:@"Error!" message:@"Loading order timed out, please select it again to try again!" delegate:self cancelButtonTitle:@"OK!" otherButtonTitles: nil] show];
            }else{
                [[[UIAlertView alloc] initWithTitle:@"Error!" message:[NSString stringWithFormat:@"There was an error loading the order:%@",[strongRequest error]] delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
            }
            DLog(@"error:%@", [strongRequest error]);
        }];
        
        [request startAsynchronous];
    }
    else if(tableView == self.itemsTable){
        
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(tableView==self.sideTable)
        return 101;
    else
        return 44;
}

#pragma mark - CIItemEditDelegate
-(void) UpdateTotal{
    if(self.itemsDB)
    {
        //        DLog(@"in update total");
        double ttotal = 0;
        double sctotal = 0;
        
        NSNumberFormatter* nf = [[NSNumberFormatter alloc] init];
        [nf setNumberStyle:NSNumberFormatterCurrencyStyle];

        NSInteger itemCount = [[self.itemsDB objectForKey:kItemCount] intValue];
        DLog(@"itemCount:%i, itemQty:%i", itemCount, [self.itemsQty count]);
        
        //NSArray* arr = [self.itemsDB objectForKey:kItems];
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
        
        //        DLog(@"sctotal%f, item count:%d, SCtotal:%@",sctotal,self.itemsDB.count,self.SCtotal.text);
    }
}

-(void)Return{
     
    
        self.itemsDB = nil;
   
   
	[self loadOrders];
}

#pragma mark - buttons


- (IBAction)AddNewOrder:(id)sender {
    CIProductViewController* page;
    
    page = [[CIProductViewController alloc] initWithNibName:@"CIProductViewController" bundle:nil];
    page.authToken = self.authToken;
    page.vendorGroup = self.vendorGroup;
    page.delegate = self;
    page.managedObjectContext = self.managedObjectContext;
    
    [page setTitle:@"Select Products"];//[venderInfo objectForKey:kName]];
    if (venderInfo && venderInfo.count > 0) {
        if([[venderInfo objectAtIndex:currentVender] objectForKey:kVenderHidePrice] != nil){
            if ([[[venderInfo objectAtIndex:currentVender] objectForKey:kVenderHidePrice] boolValue]) {
                page.showPrice = NO;
            }
        }
        
        DLog(@"Vendor Name:%@, navTitle:%@",[[venderInfo objectAtIndex:currentVender] objectForKey:kName],page.navBar.topItem.title);
    }
    [self presentViewController:page animated:NO completion:nil];
}

-(void)logout
{
    if (!masterVender) {
        NSString* url = kDBLOGOUT;
        if (authToken) {
            url = [NSString stringWithFormat:@"%@?%@=%@",kDBLOGOUT,kAuthToken,authToken];
        }
        
        DLog(@"Signout url:%@",url);
        
        __weak  ASIHTTPRequest* signout = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:url]];
        [signout setRequestMethod:@"DELETE"];
        
        [signout setCompletionBlock:^{
           // DLog(@"Signout:%@",[signout responseString]);
            [self dismissViewControllerAnimated:YES completion:nil];
        }];
        
        [signout setFailedBlock:^{
            //DLog(@"Signout Error:%@",[signout error]);
            [[[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"There was an error logging out please try again! Error:%@",[signout error]] delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
        }];
        
        [signout startAsynchronous];
    }
    else {
        
        NSString* url = kDBMasterLOGOUT;
        if (authToken) {
            url = [NSString stringWithFormat:@"%@?%@=%@",kDBMasterLOGOUT,kAuthToken,authToken];
        }
        
        DLog(@"Signout url:%@",url);
        
        __weak ASIHTTPRequest* signout = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:url]];
        [signout setRequestMethod:@"DELETE"];
        
        [signout setCompletionBlock:^{
            //DLog(@"Signout:%@",[signout responseString]);
            [self dismissViewControllerAnimated:YES completion:nil];
        }];
        
        [signout setFailedBlock:^{
            //DLog(@"Signout Error:%@",[signout error]);
            [[[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"There was an error logging out please try again! Error:%@",[signout error]] delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
        }];
        
        [signout startAsynchronous];
    }
	
	
	[[SettingsManager sharedManager] saveSetting:@"username" value:@""];
	[[SettingsManager sharedManager] saveSetting:@"password" value:@""];
	
	 	
}

- (IBAction)logout:(id)sender {
    [self logout];
}

- (IBAction)Save:(id)sender {
    //UIButton* btn = (UIButton*)sender;
//    DLog(@"tag going into save is:%d, save:%d, current:%d",EditorView.tag,btn.tag, currentOrderID);
    if (currentOrderID == 0) {
        return;
    }
    
    NSMutableArray* arr = [[NSMutableArray alloc] initWithCapacity:[self.itemsTable numberOfRowsInSection:0]];
    NSArray* data = [self.itemsDB objectForKey:kItems];
    
//    NSNumberFormatter* nf = [[NSNumberFormatter alloc] init];
//    [nf setNumberStyle:NSNumberFormatterCurrencyStyle];
    for (NSInteger i =0; i<[self.itemsTable numberOfRowsInSection:0]; i++) {
        NSString* productID = [[data objectAtIndex:i] objectForKey:kOrderItemID];
        CIItemEditCell* cell = (CIItemEditCell*)[self.itemsTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        // NSInteger num = [cell.qty.text integerValue];
        //if (num>0) {
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
        
        //}
    }
    
    [arr removeObjectIdenticalTo:nil];
    
    DLog(@"array:%@",arr);
    NSDictionary* order;
    //if ([info objectForKey:kOrderCustID]) {
    order = [NSDictionary dictionaryWithObjectsAndKeys:[self.itemsDB objectForKey:kOrderCustID],kOrderCustID,self.shipNotes.text,kShipNotes,self.notes.text,kNotes,[self.itemsDB objectForKey:kAuthorizedBy],kAuthorizedBy, arr,kOrderItems, nil];
    //    }
    //    else{
    //        order = [NSDictionary dictionaryWithObjectsAndKeys:[info objectForKey:kCustName],kCustName,[info objectForKey:kStoreName],kStoreName,[info objectForKey:kCity],kCity,arr,kOrderItems, nil];
    //    }
    NSDictionary* final = [NSDictionary dictionaryWithObjectsAndKeys:order,kOrder, nil];
    
    NSString *url = [NSString stringWithFormat:@"%@?%@=%@",[NSString stringWithFormat:kDBORDEREDITS(currentOrderID)],kAuthToken,self.authToken];
    DLog(@"final URL:%@\n JSON:%@",url,[final JSONString]);
    
    __weak  ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:url]];
    [request addRequestHeader:@"Accept" value:@"application/json"];
    [request addRequestHeader:@"Content-Type" value:@"application/json"];
    //[request appendPostData:[dataContent dataUsingEncoding:NSUTF8StringEncoding]];
    [request setRequestMethod:@"PUT"];
    [request setNumberOfTimesToRetryOnTimeout:3];
    
    //[request addRequestHeader:@"Content-Type" value:@"application/json; charset=utf-8"];
    
    //[request setPostValue:self.authToken forKey:kAuthToken];
    
    //[request.postBody appendData:[final JSONData]];
    [request appendPostData:[[final JSONString] dataUsingEncoding:NSUTF8StringEncoding]];
    
//    DLog(@"pure:%@",[final JSONString]);
    
    [request setCompletionBlock:^{
        //DLog(@"Order complete:%@",[request responseString]);
        //[self dismissModalViewControllerAnimated:YES];
        NSDictionary* results = [[request responseString] objectFromJSONString];
        if (results) {
            [self Return];
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Success!" message:@"Updated order successfully!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
            [alert show];
            
        }else {
            [[[UIAlertView alloc] initWithTitle:@"Error!" message:@"It seems there was an odd error updating your order. Please contact Convention Innovations!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
        }
    }];
    
    [request setFailedBlock:^{
        [self Return];
        //DLog(@"Order Error:%@",[request error]);
        if (request.error.code == 2) {
            [[[UIAlertView alloc] initWithTitle:@"Error!" message:@"Update timed out, please try again!" delegate:self cancelButtonTitle:@"OK!" otherButtonTitles: nil] show];
        }else{
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Error!" message:request.error.localizedDescription delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
            [alert show];
        }
    }];
    
    DLog(@"request content-type:%@",request.requestHeaders);
    
    [request startAsynchronous];
    
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
        [[[UIAlertView alloc]initWithTitle:@"Oops!" message:@"Please select an order to print!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
    }
}

- (IBAction)Delete:(id)sender {
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"DELETE" message:@"Are you sure you want to delete this order?" delegate:self cancelButtonTitle:@"DO NOT DELETE" otherButtonTitles:@"Delete", nil];
    alert.tag = 42;
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
        //rect.origin.y -= kOFFSET_FOR_KEYBOARD;//was +
        //rect.size.height -= kOFFSET_FOR_KEYBOARD;
    }
    self.OrderDetailScroll.contentOffset = CGPointMake(0, rect.origin.y);
    
    [UIView commitAnimations];
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
        rect.origin.y += kOFFSET_FOR_KEYBOARD*3;//was -
       // rect.size.height += kOFFSET_FOR_KEYBOARD;
    }
    else
    {
        // revert back to the normal state.
        //rect.origin.y -= kOFFSET_FOR_KEYBOARD;//was +
        //rect.size.height -= kOFFSET_FOR_KEYBOARD;
    }
    self.OrderDetailScroll.contentOffset = CGPointMake(0, rect.origin.y);//rect.origin;
    
    [UIView commitAnimations];
}

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



- (void)keyboardWillShow:(NSNotification *)notif
{
    //keyboard will be shown now. depending for which textfield is active, move up or move down the view appropriately
    
    if ([self.shipNotes isFirstResponder] && self.view.frame.origin.y >= 0)
    {
        [self setViewMovedUp:YES];
    }
    else if (![self.shipNotes isFirstResponder] && self.view.frame.origin.y < 0)
    {
        [self setViewMovedUp:NO];
    }
}





- (void)viewWillAppear:(BOOL)animated
{
    // register for keyboard notifications
	
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) 
                                                 name:UIKeyboardWillShowNotification object:self.view.window]; 
    
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
    
	/*
    if (masterVender) {
        __block MBProgressHUD* venderHud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        venderHud.labelText = @"loading...";
        [venderHud show:YES];
        
        NSString* url = kDBGETVENDORS;
        if (authToken) {
            url = [NSString stringWithFormat:@"%@?%@=%@",kDBGETVENDORS,kAuthToken,authToken];
        }
        
        DLog(@"vendors get url:%@",url);
        
        __block ASIHTTPRequest* request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:url]];
        [request setNumberOfTimesToRetryOnTimeout:3];
        
        [request setCompletionBlock:^{
            //DLog(@"request:%@",[request responseString]); 
            NSArray* tempVendors = [request.responseString objectFromJSONString];
            venderInfo = [[NSMutableArray alloc] initWithCapacity:[tempVendors count]];
            for (NSDictionary* dict in tempVendors) {
                vender* tVendor = [[vender alloc] init];
                [tVendor loadDictionary:dict];
                //DLog(@"vendor:%@",tVendor);
                [self.venderInfo  addObject:[tVendor copy]];
            }
            //DLog(@"vendor List:%@ test0:%@",self.venderInfo,([self.venderInfo respondsToSelector:@selector(objectAtIndex:)]?[self.venderInfo objectAtIndex:0]:@"nil"));
            [venderHud hide:YES];
        }];
        
        [request setFailedBlock:^{
            //DLog(@"request Error:%@",[request error]);
            [venderHud hide:YES];
        }];
        
        [request startAsynchronous];
        
    }
	
	

    [self Return]; */
}

- (void)viewWillDisappear:(BOOL)animated
{
    // unregister for keyboard notifications while not visible.
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil]; 
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
    
    if(start&&end&&![start isKindOfClass:[NSNull class]]&&![end isKindOfClass:[NSNull class]]&&start.length > 0 && end.length > 0){
    startDate = [df dateFromString:start];
    endDate = [df dateFromString:end];
    }else{
        DLog(@"bad luck on dates themselves, %@-%@",start, end);
        return;
    }
    
    __block NSMutableArray *dateList = [NSMutableArray array];
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

-(void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex{
    if (alertView.tag == 42) {
        if (buttonIndex == 1) {
            __block MBProgressHUD* deleteHUD = [MBProgressHUD showHUDAddedTo:self.view animated:NO];
            deleteHUD.labelText = @"Deleting Order...";
            [deleteHUD show:NO];
            
            
            __block ASIHTTPRequest* request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:kDBORDEREDITS([[self.itemsDB objectForKey:@"id"] integerValue])]];
            request.requestMethod = @"DELETE";
            [request setNumberOfTimesToRetryOnTimeout:3];
//            DLog(@"delete url = %@ itemsdb:%@ id:%d", request.url, self.itemsDB, [[self.itemsDB objectForKey:@"id"] integerValue]);
            
            [request setCompletionBlock:^{
                //DLog(@"request:%@",[request responseString]);
                
                [self Return];
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Success!" message:@"Deleted order successfully!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
                [alert show];
                
                [deleteHUD hide:YES];
            }];
            
            [request setFailedBlock:^{
               // DLog(@"request Error:%@",[request error]);
                [deleteHUD hide:YES];
            }];
            
            [request startAsynchronous];
        }
    }
}


#pragma mark - Search Delegate stuff

 



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
			DLog(@"Bill Name: %@", storeName);
			DLog(@"Cust Id: %@", custId);
				
		 
			
			return [[storeName uppercaseString] contains:[searchText uppercaseString]] ||
					 [[custId uppercaseString] hasPrefix:[searchText uppercaseString]];
		}];
		
		self.orders = [[self.orderData filteredArrayUsingPredicate:pred] mutableCopy];
		//[selectedIdx removeAllObjects];
		DLog(@"results count:%d", self.orders.count);
	}
	[self.sideTable reloadData];
	//    }

}

@end
