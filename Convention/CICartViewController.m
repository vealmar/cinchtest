//
//  CICartViewController.m
//  Convention
//
//  Created by Matthew Clark on 5/11/12.
//  Copyright (c) 2012 MotionMobs. All rights reserved.
//

#import "CICartViewController.h"
#import "config.h"
#import "JSONKit.h"
#import "CIViewController.h"
#import "CIProductCell.h"
#import "CICustomerInfoViewController.h"
#import "MBProgressHUD.h"
#import "Macros.h"
#import "SettingsManager.h"
#import "FarrisProductCell.h"
#import "UIAlertViewDelegateWithBlock.h"

@interface CICartViewController (){
    NSMutableArray *allCartItems;
    __weak IBOutlet UILabel *customerInfoLabel;
    __weak IBOutlet UIImageView *logo;
}
//-(void) getCustomers;

@end

@implementation CICartViewController
@synthesize products;
@synthesize productData;
@synthesize authToken;
@synthesize navBar;
@synthesize title;
@synthesize showPrice;
@synthesize indicator;
//@synthesize customerDB;
@synthesize customer;
@synthesize delegate;
@synthesize customersReady;
@synthesize tOffset;
@synthesize productCart;
@synthesize finishTheOrder;
@synthesize multiStore;
@synthesize popoverController;
@synthesize storeQtysPO;
@synthesize lblShipDate1, lblShipDate2, lblShipDateCount;
@synthesize tableHeaderPigglyWiggly, tableHeaderFarris;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        showPrice = YES;
        customersReady = NO;
        tOffset =0;
        productCart = [NSMutableDictionary dictionary];
        allCartItems = [NSMutableDictionary dictionary];
        
        DLog(@"self class:%@",NSStringFromClass([self class]));
        if (self.delegate) {
            DLog(@"delegate class:%@",NSStringFromClass([self.delegate class]));
        }
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle


- (void)viewWillAppear:(BOOL)animated
{
    // register for keyboard notifications
    DLog(@"in view will appear... need CI");
    
    if ([kShowCorp isEqualToString:kPigglyWiggly]) {
        tableHeaderPigglyWiggly.hidden = NO;
        tableHeaderFarris.hidden = YES;
        logo.hidden = YES; //SG: Hiding this at present since I don't have the PW logo image.
    } else if ([kShowCorp isEqualToString: kFarris]) {
        tableHeaderPigglyWiggly.hidden = YES;
        tableHeaderFarris.hidden = NO;
        self.zeroVouchers.hidden = YES;
        logo.image = [UIImage imageNamed:@"FarrisBrosWhiteLogo.png"];
    } else {
        tableHeaderPigglyWiggly.hidden = YES;
        tableHeaderFarris.hidden = YES;
    }
    customerInfoLabel.text = customer != nil &&
            customer[kBillName] != nil &&
            ![customer[kBillName]isKindOfClass:[NSNull class]]? customer[kBillName] : @"";

    allCartItems = [NSMutableArray arrayWithCapacity:[self.productData count] + [self.discountItems count]];
    
    double grossTotal = 0.0;
    NSArray *keys = [self.productData allKeys];
    for (NSString *key in keys) {
        [allCartItems addObject:[self.productData objectForKey:key]];
        int qty = 0;
        if (multiStore) {
            NSDictionary *quantitiesByStore = [[[self.productData objectForKey:key] objectForKey:kEditableQty] objectFromJSONString];
            for (NSString *storeId in [quantitiesByStore allKeys]) {
                qty += [[quantitiesByStore objectForKey:storeId] intValue];
            }
        }
        else {
            qty += [[[self.productData objectForKey:key] objectForKey:kEditableQty] intValue];
        }
        double price = [[[self.productCart objectForKey:key] objectForKey:kEditablePrice] doubleValue];
        grossTotal += qty * price;
    }
    
//    allCartItems = [NSMutableDictionary dictionaryWithDictionary:self.productData];
//    [allCartItems addEntriesFromDictionary:self.discountItems];
    
    double discountTotal = 0.0;
    keys = [self.discountItems allKeys];
    for (NSString *key in keys) {
        [allCartItems addObject:[self.discountItems objectForKey:key]];
        double price = [[[self.discountItems objectForKey:key] objectForKey:@"price"] doubleValue];
        double qty = [[[self.discountItems objectForKey:key] objectForKey:@"quantity"] doubleValue];
        discountTotal += price*qty;
    }
    
    NSNumberFormatter* nf = [[NSNumberFormatter alloc] init];
    nf.formatterBehavior = NSNumberFormatterBehavior10_4;
    nf.maximumFractionDigits = 2;
    nf.minimumFractionDigits = 2;
    nf.minimumIntegerDigits = 1;

    self.grossTotal.text = [nf stringFromNumber:[NSNumber numberWithDouble:grossTotal]];
    self.discountTotal.text = [nf stringFromNumber:[NSNumber numberWithDouble:discountTotal]];
    
    double netTotal = grossTotal + discountTotal;
    self.netTotal.text = [nf stringFromNumber:[NSNumber numberWithDouble:netTotal]];

    [self.products reloadData];
    [self.indicator stopAnimating];
    self.indicator.hidden = YES;
    
    DLog(@"self class:%@",NSStringFromClass([self class]));
    if (self.delegate) {
        DLog(@"delegate class:%@",NSStringFromClass([self.delegate class]));
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.indicator startAnimating];
    // Do any additional setup after loading the view from its nib.
    
    navBar.topItem.title = self.title;
    //    [self getCustomers];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

#pragma mark - Table stuff
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)myTableView numberOfRowsInSection:(NSInteger)section {
//    if (self.productData) {
//        return [self.productData count];
//    }
    if (allCartItems) {
        return [allCartItems count];
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)myTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (!self.productData) {
        return nil;
    }
    
//    NSString* key = [[self.productData allKeys] objectAtIndex:indexPath.row];
//    NSString *key = [[allCartItems allKeys] objectAtIndex:indexPath.row];
//    NSMutableDictionary* dict = [self.productData objectForKey:key];
//    NSMutableDictionary *dict = [allCartItems objectForKey:key];
    NSDictionary *dict = [allCartItems objectAtIndex:indexPath.row];
    if ([kShowCorp isEqualToString: kPigglyWiggly]) {
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
        
        //DLog(@"data:%@",[self.productData objectForKey:key]);
        DLog(@"data:%@",[allCartItems objectAtIndex:indexPath.row]);
        
        cell.InvtID.text = [dict objectForKey:@"invtid"];
        cell.descr.text = [dict objectForKey:@"descr"];
        
        //PW -- swapping out partnbr and UOM for Ship date range
        if([dict objectForKey:kProductShipDate1]&&![[dict objectForKey:kProductShipDate1] isKindOfClass:[NSNull class]]){
            NSDateFormatter* df = [[NSDateFormatter alloc] init];
            [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
            NSDate* date = [[NSDate alloc]init];
            date = [df dateFromString:[dict objectForKey:kProductShipDate1]];
            [df setDateFormat:@"yyyy-MM-dd"];
    //        cell.PartNbr.text = [df stringFromDate:date];
            cell.shipDate1.text = [df stringFromDate:date];
        }else {
    //        cell.PartNbr.text = @"";
            cell.shipDate1.text = @"";
        }
        if([dict objectForKey:kProductShipDate2]&&![[dict objectForKey:kProductShipDate2] isKindOfClass:[NSNull class]]){
            NSDateFormatter* df = [[NSDateFormatter alloc] init];
            [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
            NSDate* date = [[NSDate alloc]init];
            date = [df dateFromString:[dict objectForKey:kProductShipDate2]];
            [df setDateFormat:@"yyyy-MM-dd"];
    //        cell.Uom.text = [df stringFromDate:date];
            cell.shipDate2.text = [df stringFromDate:date];
        }else {
    //        cell.Uom.text = @"";
            cell.shipDate2.text = @"";
        }
        //PW---
        
        if([dict objectForKey:@"caseqty"] && ![[dict objectForKey:@"caseqty"] isKindOfClass:[NSNull class]])
            cell.CaseQty.text = [dict objectForKey:@"caseqty"];
        else
            cell.CaseQty.text = @"";
        cell.numShipDates.text = ([[dict objectForKey:kOrderItemShipDates] isKindOfClass:[NSArray class]]?[NSString stringWithFormat:@"%d", ((NSArray*)[dict objectForKey:kOrderItemShipDates]).count]:@"0");
        cell.quantity.hidden = YES;
        
        if ([dict objectForKey:kEditableQty] && !multiStore) {
            cell.quantity.text = [[dict objectForKey:kEditableQty] stringValue];
            cell.qtyLbl.text = cell.quantity.text;
        } else {
            cell.quantity.text = @"0";
        }
        
        if (multiStore) {
            cell.qtyBtn.hidden = NO;
        } else {
            cell.qtyLbl.hidden = NO;
        }
        
        cell.price.hidden = YES;
        
        if ([dict objectForKey:kEditableVoucher]) {
            NSNumberFormatter* nf = [[NSNumberFormatter alloc] init];
            nf.formatterBehavior = NSNumberFormatterBehavior10_4;
            nf.maximumFractionDigits = 2;
            nf.minimumFractionDigits = 2;
            nf.minimumIntegerDigits = 1;
            
            cell.voucher.text = [nf stringFromNumber:[dict objectForKey:kEditableVoucher]];
        }else{
            cell.voucher.text = @"0.00";
        }
        
        if (showPrice) {
            NSNumberFormatter* nf = [[NSNumberFormatter alloc] init];
            nf.formatterBehavior = NSNumberFormatterBehavior10_4;
            nf.maximumFractionDigits = 2;
            nf.minimumFractionDigits = 2;
            nf.minimumIntegerDigits = 1;
            NSString* price = [nf stringFromNumber:[dict objectForKey:kEditablePrice]];
            
            cell.price.text = price;
            cell.priceLbl.text = price;
        }
        else
            cell.price.text = @"0.00";
        cell.tag = [indexPath row];
        
        BOOL hasQty = NO;
        
        //if you want it to highlight based on qty uncomment this:
        if (multiStore && dict && [[dict objectForKey:kEditableQty] isKindOfClass:[NSString class]]
            && [[[dict objectForKey:kEditableQty] objectFromJSONString] isKindOfClass:[NSDictionary class]]
            && ((NSDictionary*)[[dict objectForKey:kEditableQty] objectFromJSONString]).allKeys.count>0) {
            for(NSNumber* n in [[[dict objectForKey:kEditableQty] objectFromJSONString] allObjects]){
                if(n>0)
                    hasQty = YES;
            }
        }else if (dict && [dict objectForKey:kEditableQty] && [[dict objectForKey:kEditableQty] isKindOfClass:[NSString class]]
                  && [[dict objectForKey:kEditableQty] integerValue] >0){
            hasQty = YES;
        }else if (dict && [dict objectForKey:kEditableQty] && [[dict objectForKey:kEditableQty] isKindOfClass:[NSNumber class]]
                  && [[dict objectForKey:kEditableQty] intValue] > 0){
            hasQty = YES;
        }else{
            cell.backgroundView = nil;
        }
        
        BOOL hasShipDates = NO;
        NSArray *shipDates = [dict objectForKey:kOrderItemShipDates];
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
            }
        }

        cell.delegate = (id<ProductCellDelegate>) self;
        return (UITableViewCell *)cell;
    } else if ([kShowCorp isEqualToString: kFarris]) {
        static NSString *CellIdentifier = @"FarrisProductCell";
        FarrisProductCell *cell = [myTableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil){
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:CellIdentifier owner:nil options:nil];
            cell = [topLevelObjects objectAtIndex:0];
        }

        BOOL isDiscount = [[dict objectForKey:@"category"] isEqualToString:@"discount"];
        UIFont *discountFont = [UIFont italicSystemFontOfSize:14];
        
        
        cell.itemNumber.text = isDiscount?@"Discount":[dict objectForKey:@"invtid"];
        [cell setDescription:[dict objectForKey:(isDiscount?@"desc":kProductDescr)] withSubtext:[dict objectForKey:(isDiscount?@"desc2":kProductDescr2)]];



        cell.min.text = [[dict objectForKey:@"min"] stringValue];
        
        if (!isDiscount) {
            cell.quantity.text = [[dict objectForKey:kEditableQty] stringValue];
            cell.quantity.hidden = NO;
            cell.qtyLbl.hidden = YES;
        }
        else {
            NSString *qty = [dict objectForKey:@"quantity"];
            cell.qtyLbl.text = qty;
            cell.quantity.hidden = YES;
            cell.qtyLbl.font = discountFont;
            cell.qtyLbl.hidden = NO;
        }
        
        NSNumberFormatter* nf = [[NSNumberFormatter alloc] init];
        nf.formatterBehavior = NSNumberFormatterBehavior10_4;
        nf.maximumFractionDigits = 2;
        nf.minimumFractionDigits = 2;
        nf.minimumIntegerDigits = 1;
        
        if (!isDiscount) {
            cell.regPrice.text = [nf stringFromNumber:[NSNumber numberWithDouble:[[dict objectForKey:kProductRegPrc] doubleValue]]];
            cell.showPrice.text = [nf stringFromNumber:[NSNumber numberWithDouble:[[dict objectForKey:kProductShowPrice] doubleValue]]];
        } else {
            cell.regPrice.text = @"";
            cell.showPrice.text = [nf stringFromNumber:[NSNumber numberWithDouble:[[dict objectForKey:@"price"] doubleValue]]];
            cell.showPrice.font = discountFont;
        }
        cell.delegate = (id<ProductCellDelegate>) self;
        cell.tag = [indexPath row];
        return (UITableViewCell *)cell;
    }

    return nil;
}

#pragma mark - Other

-(void)Cancel{
    self.indicator.hidden = NO;
    [self.indicator startAnimating];
    
    if (self.delegate) {
        [self.delegate setProductCart:[NSMutableDictionary dictionaryWithDictionary:self.productCart]];
        [self.delegate setBackFromCart:YES];
        [self.delegate setFinishOrder:NO];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

- (IBAction)Cancel:(id)sender {
    [self Cancel];
}

//-(void)setCustomerInfo:(NSDictionary*)info
//{
//    self.customer = [info copy];
//}

//- (IBAction)submit:(id)sender {
//    NSMutableArray* arr = [[NSMutableArray alloc] initWithCapacity:[self.products numberOfRowsInSection:0]];
//    
//    //    NSNumberFormatter* nf = [[NSNumberFormatter alloc] init];
//    //    [nf setNumberStyle:NSNumberFormatterCurrencyStyle];
//    NSArray* keys = self.productCart.allKeys;
//    for (NSString* i in keys) {
//        NSString* productID = [[self.productData objectForKey:i] objectForKey:@"id"];
//        NSMutableDictionary* dict = [self.productCart objectForKey:i];
//        NSInteger num = [[dict objectForKey:kEditableQty] integerValue];
//        DLog(@"q:%@=%d with %@ and %@",[dict objectForKey:kEditableQty], num,[dict objectForKey:kEditablePrice],[dict objectForKey:kEditableVoucher]);
//        if (num>0) {
//            NSDictionary* proDict = [NSDictionary dictionaryWithObjectsAndKeys:productID,kOrderItemID,[NSString stringWithFormat:@"%d",num],kOrderItemNum,[dict objectForKey:kEditablePrice],kOrderItemPRICE,[dict objectForKey:kEditableVoucher],kOrderItemVoucher, nil];
//            [arr addObject:(id)proDict];
//        }
//    }
//    
//    [arr removeObjectIdenticalTo:nil];
//    
//    DLog(@"array:%@",arr);
//    NSDictionary* order;
//    //if ([info objectForKey:kOrderCustID]) {
//    if (!self.customer) {
//        return;
//    }
//    order = [NSDictionary dictionaryWithObjectsAndKeys:[self.customer objectForKey:kOrderCustID],kOrderCustID,[self.customer objectForKey:kShipNotes],kShipNotes,[self.customer objectForKey:kNotes],kNotes,[self.customer objectForKey:kAuthorizedBy],kAuthorizedBy,[self.customer objectForKey:kEmail],kEmail,[self.customer objectForKey:kSendEmail],kSendEmail, arr,kOrderItems, nil];
//    //    }
//    //    else{
//    //        order = [NSDictionary dictionaryWithObjectsAndKeys:[info objectForKey:kCustName],kCustName,[info objectForKey:kStoreName],kStoreName,[info objectForKey:kCity],kCity,arr,kOrderItems, nil];
//    //    }
//    NSDictionary* final = [NSDictionary dictionaryWithObjectsAndKeys:order,kOrder, nil];
//    
//    NSString *url = [NSString stringWithFormat:@"%@?%@=%@",kDBORDER,kAuthToken,self.authToken];
//    DLog(@"final JSON:%@\nURL:%@",[final JSONString],url);
//    
//    AFHTTPClient *client = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:url]];
//    [client setParameterEncoding:AFJSONParameterEncoding];
//    NSMutableURLRequest *request = [client requestWithMethod:@"POST" path:@"" parameters:final];
//    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
//        
//        [self dismissViewControllerAnimated:YES completion:^{
//            if (self.delegate != nil) {
//                [self.delegate Return];
//                [self.delegate setBackFromCart:YES];
//            }
//
//        }];
//    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
//        
//        [[[UIAlertView alloc] initWithTitle:@"Order Error!" message:[NSString stringWithFormat:@"Error message:%@",error.localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
//
//    }];
//    
//    [operation start];
//    
////    __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:url]];
////    [request addRequestHeader:@"Accept" value:@"application/json"];
////    [request addRequestHeader:@"Content-Type" value:@"application/json"];
////    //[request appendPostData:[dataContent dataUsingEncoding:NSUTF8StringEncoding]];
////    [request setRequestMethod:@"POST"];
////    
////    //[request addRequestHeader:@"Content-Type" value:@"application/json; charset=utf-8"];
////    
////    //[request setPostValue:self.authToken forKey:kAuthToken];
////    
////    //[request.postBody appendData:[final JSONData]];
////    [request appendPostData:[[final JSONString] dataUsingEncoding:NSUTF8StringEncoding]];
////    
////    //DLog(@"pure:%@",[request postBody]);
////    
////    [request setCompletionBlock:^{
////        //DLog(@"Order complete:%@",[request responseString]);
////        dispatch_async(dispatch_get_main_queue(), ^{
////            if (self.delegate != nil) {
////                [self.delegate Return];
////                //[self.delegate performSelector:@selector(Return) withObject:nil afterDelay:0.0f];
////                [self.delegate setBackFromCart:YES];
////            }
////            [self dismissViewControllerAnimated:YES completion:nil];
////        });
////    }];
////    
////    [request setFailedBlock:^{
////        //DLog(@"Order Error:%@",[request error]);
////        [[[UIAlertView alloc] initWithTitle:@"Order Error!" message:[NSString stringWithFormat:@"Error message:%@",request.error] delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
////    }];
////    
////    DLog(@"request content-type:%@",request.requestHeaders);
////    
////    [request startAsynchronous];
//    
//    
//    //    [self dismissModalViewControllerAnimated:YES];
//}

- (IBAction)finishOrder:(id)sender {
    if ([[self.productCart allKeys] count] <= 0) {
        [[[UIAlertView alloc] initWithTitle:@"Cart Empty." message:@"You don't have anything in your cart!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
        return;
    }
    DLog(@"FO self class:%@",NSStringFromClass([self class]));
    DLog(@"FO delegate class:%@",NSStringFromClass([self.delegate class]));
    if ([self.delegate respondsToSelector:@selector(setFinishOrder:)]&&[self.delegate respondsToSelector:@selector(setBackFromCart:)]) {
        [self.delegate setProductCart:self.productCart];
        [self.delegate setBackFromCart:YES];
        [self.delegate setFinishOrder:YES];
        //        [self.delegate finishOrder:nil];
    }
    else{
        DLog(@"no delegate class at all");
    }
    [self dismissViewControllerAnimated:NO completion:nil];
}

-(IBAction)clearVouchers:(id)sender {
    if ([[self.productCart allKeys] count] <= 0) {
        [[[UIAlertView alloc] initWithTitle:@"Cart Empty." message:@"You don't have anything in your cart!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
        return;
    }

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Confirm" message:@"Zero out all vouchers?"
                                                   delegate:nil cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
    [UIAlertViewDelegateWithBlock showAlertView:alert withCallBack:^(NSInteger buttonIndex) {
        
        if (buttonIndex == 1) {
            [self zeroAllVouchers];
        }
        
    }];

}

-(void)zeroAllVouchers {
    for (NSString *key in [self.productData allKeys]) {
        NSMutableDictionary *dict = [self.productData objectForKey:key];
        [dict setObject:[NSNumber numberWithDouble:0.0] forKey:kEditableVoucher];
    }

    [self.products reloadData];
    DLog(@"Set voucher values for all cart items to zero.");
}

-(void)VoucherChange:(double)price forIndex:(int)idx{
    NSString* key = [[self.productData allKeys] objectAtIndex:idx];
    NSMutableDictionary* dict = [self.productCart objectForKey:key];
    [dict setObject:[NSNumber numberWithDouble:price] forKey:kEditableVoucher];
    DLog(@"voucher change to %@ for index %@ (idx:%d)",[NSNumber numberWithDouble:price],key,idx);
}

-(void)PriceChange:(double)price forIndex:(int)idx{
    NSString* key = [[self.productData allKeys] objectAtIndex:idx];
    NSMutableDictionary* dict = [self.productCart objectForKey:key];
    [dict setObject:[NSNumber numberWithDouble:price] forKey:kEditablePrice];
}

-(void)QtyChange:(double)qty forIndex:(int)idx{
    NSString* key = [[self.productData allKeys] objectAtIndex:idx];
    NSMutableDictionary* dict = [self.productCart objectForKey:key];
    if (qty <= 0) {
        [self.productData removeObjectForKey:key];
        [self.productCart removeObjectForKey:key];
        [self.products reloadData];
    }
    
    [dict setObject:[NSNumber numberWithDouble:qty] forKey:kEditableQty];
    DLog(@"qty change to %@ for index %@",[NSNumber numberWithDouble:qty],key);
}

-(void)QtyTouchForIndex:(int)idx{
    if ([popoverController isPopoverVisible]) {
        [popoverController dismissPopoverAnimated:YES];
    }else{
        if (!storeQtysPO) {
            storeQtysPO = [[CIStoreQtyTableViewController alloc] initWithNibName:@"CIStoreQtyTableViewController" bundle:nil];
        }
        NSString* key = [[self.productData allKeys] objectAtIndex:idx];
        NSMutableDictionary* dict = [self.productCart objectForKey:key];
        if ([[dict objectForKey:kEditableQty] isKindOfClass:[NSNumber class]]) {
            NSArray* storeNums = [customer objectForKey:kStores];
            NSMutableDictionary* stores = [NSMutableDictionary dictionaryWithCapacity:storeNums.count+1];
            
            [stores setValue:[NSNumber numberWithInt:0] forKey:[customer objectForKey:kCustID]];
            DLog(@"setting %@ to %@ so stores is now:%@",[customer objectForKey:kCustID],[NSNumber numberWithInt:0],stores);
            for(int i = 0; i<storeNums.count;i++){
                [stores setValue:[NSNumber numberWithInt:0] forKey:[[storeNums objectAtIndex:i] stringValue]];
                //                DLog(@"setting %@ to %@ so stores is now:%@",[storeNums objectAtIndex:i],[NSNumber numberWithInt:0],stores);
            }
            
            NSString* JSON = [stores JSONString];
            [dict setObject:JSON forKey:kEditableQty];
        }
        storeQtysPO.stores = [[[dict objectForKey:kEditableQty] objectFromJSONString] mutableCopy];
        storeQtysPO.tag = idx;
        storeQtysPO.editable = NO;
        storeQtysPO.delegate = (id<CIStoreQtyTableDelegate>) self;
        CGRect frame = [self.products rectForRowAtIndexPath:[NSIndexPath indexPathForRow:idx inSection:0]];
        frame = CGRectOffset(frame, 750, 0);
        DLog(@"pop from frame:%@",NSStringFromCGRect(frame));
        popoverController = [[UIPopoverController alloc] initWithContentViewController:storeQtysPO];
        [popoverController presentPopoverFromRect:frame inView:self.products permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
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
    [self setViewMovedUp:NO];
}

-(NSDictionary*)getCustomerInfo{
    return [self.customer copy];
}
@end
