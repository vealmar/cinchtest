//
//  CICartViewController.m
//  Convention
//
//  Created by Matthew Clark on 5/11/12.
//  Copyright (c) 2012 MotionMobs. All rights reserved.
//

#import "CICartViewController.h"
//#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "config.h"
#import "JSONKit.h"
#import "CIViewController.h"
#import "CIProductCell.h"
#import "CICustomerInfoViewController.h"
#import "MBProgressHUD.h"
#import "Macros.h"
#import "SettingsManager.h"
#import "AFHTTPClient.h"
#import "AFJSONRequestOperation.h"

@interface CICartViewController (){
    MBProgressHUD* loading;
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
@synthesize customerDB;
@synthesize customer;
@synthesize delegate;
@synthesize customersReady;
@synthesize tOffset;
@synthesize productCart;
@synthesize finishTheOrder;
@synthesize multiStore;
@synthesize popoverController;
@synthesize storeQtysPO;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        showPrice = YES;
        customersReady = NO;
        tOffset =0;
        productCart = [NSMutableDictionary dictionary];
        
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
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:self.view.window];
    [self.products reloadData];
    [self.indicator stopAnimating];
    self.indicator.hidden = YES;
    
    DLog(@"self class:%@",NSStringFromClass([self class]));
    if (self.delegate) {
        DLog(@"delegate class:%@",NSStringFromClass([self.delegate class]));
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    // unregister for keyboard notifications while not visible.
    //[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.indicator startAnimating];
    // Do any additional setup after loading the view from its nib.
    
    navBar.topItem.title = self.title;
    //    [self getCustomers];
}

- (void)viewDidUnload
{
    [self setProducts:nil];
    [self setNavBar:nil];
    [self setIndicator:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
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
    if (self.productData) {
        return [self.productData count];
    }
    return 0;
}
- (UITableViewCell *)tableView:(UITableView *)myTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (!self.productData) {
        return nil;
    }
    
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
    
    NSString* key = [[self.productData allKeys] objectAtIndex:indexPath.row];
    DLog(@"data:%@",[self.productData objectForKey:key]);
    
    //idx, invtid, descr, partnbr, uom, showprc, caseqty, dirship, linenbr, new, adv, discount
    if ([[self.productData objectForKey:key] objectForKey:@"idx"]&&![[[self.productData objectForKey:key] objectForKey:@"idx"] isKindOfClass:[NSNull class]]) {
        cell.ridx.text = [[[self.productData objectForKey:key] objectForKey:@"idx"] stringValue];
    }else{
        cell.ridx.text = @"";
    }
    cell.InvtID.text = [[self.productData objectForKey:key] objectForKey:@"invtid"];
    cell.descr.text = [[self.productData objectForKey:key] objectForKey:@"descr"];
    
    cell.delegate = (id<CIProductCellDelegate>) self;
    
    //PW -- swapping out partnbr and UOM for Ship date range
    if([[self.productData objectForKey:key] objectForKey:kProductShipDate1]&&![[[self.productData objectForKey:key] objectForKey:kProductShipDate1] isKindOfClass:[NSNull class]]){
        NSDateFormatter* df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
        NSDate* date = [[NSDate alloc]init];
        date = [df dateFromString:[[self.productData objectForKey:key] objectForKey:kProductShipDate1]];
        [df setDateFormat:@"yyyy-MM-dd"];
        cell.PartNbr.text = [df stringFromDate:date];
    }else
        cell.PartNbr.text = @"";
    if([[self.productData objectForKey:key] objectForKey:kProductShipDate2]&&![[[self.productData objectForKey:key] objectForKey:kProductShipDate2] isKindOfClass:[NSNull class]]){
        NSDateFormatter* df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
        NSDate* date = [[NSDate alloc]init];
        date = [df dateFromString:[[self.productData objectForKey:key] objectForKey:kProductShipDate2]];
        [df setDateFormat:@"yyyy-MM-dd"];
        cell.Uom.text = [df stringFromDate:date];
    }else
        cell.Uom.text = @"";
    //PW---
    
    if([[self.productData objectForKey:key] objectForKey:@"caseqty"]&&![[[self.productData objectForKey:key] objectForKey:@"caseqty"] isKindOfClass:[NSNull class]])
        cell.CaseQty.text = [[self.productData objectForKey:key] objectForKey:@"caseqty"];
    else
        cell.CaseQty.text = @"";
    cell.DirShip.text = ([[self.productData objectForKey:key] objectForKey:@"dirship"]?@"Y":@"N");
    if ([[self.productData objectForKey:key] objectForKey:@"linenbr"]&&![[[self.productData objectForKey:key] objectForKey:@"linenbr"] isKindOfClass:[NSNull class]]) {
        cell.LineNbr.text = [[self.productData objectForKey:key] objectForKey:@"linenbr"];
    }else{
        cell.LineNbr.text = @"";
    }
    cell.New.text = ([[self.productData objectForKey:key] objectForKey:@"new"]?@"Y":@"N");
    cell.Adv.text = ([[self.productData objectForKey:key] objectForKey:@"adv"]?@"Y":@"N");
    //DLog(@"regPrc:%@",[[self.productData objectAtIndex:[indexPath row]] objectForKey:@"regprc"]);
    //    cell.regPrc.text = [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithDouble:[[[self.productData objectForKey:key] objectForKey:@"regprc"] doubleValue]] numberStyle:NSNumberFormatterCurrencyStyle];
    cell.regPrc.text = ([[[self.productData objectForKey:key] objectForKey:kOrderItemShipDates] isKindOfClass:[NSArray class]]?[NSString stringWithFormat:@"%d",((NSArray*)[[self.productData objectForKey:key] objectForKey:kOrderItemShipDates]).count]:@"0");
    cell.quantity.hidden = YES;
    NSMutableDictionary* dict = [self.productCart objectForKey:key];
    if ([dict objectForKey:kEditableQty]&&!multiStore) {
        cell.quantity.text = [[dict objectForKey:kEditableQty] stringValue];
        cell.qtyLbl.text = cell.quantity.text;
    }
    else
        cell.quantity.text = @"0";
    if (multiStore) {
        cell.qtyBtn.hidden = NO;
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
        //NSNumberFormatter* nf = [[NSNumberFormatter alloc] init];
        //[nf setNumberStyle:NSNumberFormatterCurrencyStyle];
        //double price = [[nf numberFromString:cell.price.text] doubleValue];
        //DLog(@"price:%f",price);
    }
    else
        cell.price.text = @"0.00";
    cell.delegate = (id<CIProductCellDelegate>) self;
    cell.tag = [indexPath row];
    cell.cartBtn.hidden = YES;
    //cell.subtitle.text = [[[self.productData objectAtIndex:[indexPath row]] objectForKey:@"id"] stringValue];
    
    return (UITableViewCell *)cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //DLog(@"product details:%@",[self.productData objectForKey:[NSNumber numberWithInteger:[indexPath row]]]);
}


#pragma mark - Other

-(void)Cancel{
    self.indicator.hidden = NO;
    [self.indicator startAnimating];
    
    if (self.delegate) {
        [self.delegate setProductCart:self.productCart];
        [self.delegate setBackFromCart:YES];
        [self.delegate setFinishOrder:NO];
    }
    
    dispatch_queue_t myQueue;
    myQueue = dispatch_queue_create("myQueue", NULL);
    
    dispatch_async(myQueue, ^{
        sleep(1);
        dispatch_async(dispatch_get_main_queue(), ^{
            [loading hide:YES];
            [self dismissViewControllerAnimated:YES completion:nil];
            
        });
    });
}

- (IBAction)Cancel:(id)sender {
    [self Cancel];
}

-(void)setCustomerInfo:(NSDictionary*)info
{
    [loading hide:YES];
    self.customer = [info copy];
    
}


- (IBAction)submit:(id)sender {
    NSMutableArray* arr = [[NSMutableArray alloc] initWithCapacity:[self.products numberOfRowsInSection:0]];
    
    //    NSNumberFormatter* nf = [[NSNumberFormatter alloc] init];
    //    [nf setNumberStyle:NSNumberFormatterCurrencyStyle];
    NSArray* keys = self.productCart.allKeys;
    for (NSString* i in keys) {
        NSString* productID = [[self.productData objectForKey:i] objectForKey:@"id"];
        NSMutableDictionary* dict = [self.productCart objectForKey:i];
        NSInteger num = [[dict objectForKey:kEditableQty] integerValue];
        DLog(@"q:%@=%d with %@ and %@",[dict objectForKey:kEditableQty], num,[dict objectForKey:kEditablePrice],[dict objectForKey:kEditableVoucher]);
        if (num>0) {
            NSDictionary* proDict = [NSDictionary dictionaryWithObjectsAndKeys:productID,kOrderItemID,[NSString stringWithFormat:@"%d",num],kOrderItemNum,[dict objectForKey:kEditablePrice],kOrderItemPRICE,[dict objectForKey:kEditableVoucher],kOrderItemVoucher, nil];
            [arr addObject:(id)proDict];
        }
    }
    
    [arr removeObjectIdenticalTo:nil];
    
    DLog(@"array:%@",arr);
    NSDictionary* order;
    //if ([info objectForKey:kOrderCustID]) {
    if (!self.customer) {
        return;
    }
    order = [NSDictionary dictionaryWithObjectsAndKeys:[self.customer objectForKey:kOrderCustID],kOrderCustID,[self.customer objectForKey:kShipNotes],kShipNotes,[self.customer objectForKey:kNotes],kNotes,[self.customer objectForKey:kAuthorizedBy],kAuthorizedBy,[self.customer objectForKey:kEmail],kEmail,[self.customer objectForKey:kSendEmail],kSendEmail, arr,kOrderItems, nil];
    //    }
    //    else{
    //        order = [NSDictionary dictionaryWithObjectsAndKeys:[info objectForKey:kCustName],kCustName,[info objectForKey:kStoreName],kStoreName,[info objectForKey:kCity],kCity,arr,kOrderItems, nil];
    //    }
    NSDictionary* final = [NSDictionary dictionaryWithObjectsAndKeys:order,kOrder, nil];
    
    NSString *url = [NSString stringWithFormat:@"%@?%@=%@",kDBORDER,kAuthToken,self.authToken];
    DLog(@"final JSON:%@\nURL:%@",[final JSONString],url);
    
    AFHTTPClient *client = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:url]];
    [client setParameterEncoding:AFJSONParameterEncoding];
    NSMutableURLRequest *request = [client requestWithMethod:@"POST" path:@"" parameters:final];
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        [self dismissViewControllerAnimated:YES completion:^{
            if (self.delegate != nil) {
                [self.delegate Return];
                [self.delegate setBackFromCart:YES];
            }

        }];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        
        [[[UIAlertView alloc] initWithTitle:@"Order Error!" message:[NSString stringWithFormat:@"Error message:%@",error.localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];

    }];
    
    [operation start];
    
//    __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:url]];
//    [request addRequestHeader:@"Accept" value:@"application/json"];
//    [request addRequestHeader:@"Content-Type" value:@"application/json"];
//    //[request appendPostData:[dataContent dataUsingEncoding:NSUTF8StringEncoding]];
//    [request setRequestMethod:@"POST"];
//    
//    //[request addRequestHeader:@"Content-Type" value:@"application/json; charset=utf-8"];
//    
//    //[request setPostValue:self.authToken forKey:kAuthToken];
//    
//    //[request.postBody appendData:[final JSONData]];
//    [request appendPostData:[[final JSONString] dataUsingEncoding:NSUTF8StringEncoding]];
//    
//    //DLog(@"pure:%@",[request postBody]);
//    
//    [request setCompletionBlock:^{
//        //DLog(@"Order complete:%@",[request responseString]);
//        dispatch_async(dispatch_get_main_queue(), ^{
//            if (self.delegate != nil) {
//                [self.delegate Return];
//                //[self.delegate performSelector:@selector(Return) withObject:nil afterDelay:0.0f];
//                [self.delegate setBackFromCart:YES];
//            }
//            [self dismissViewControllerAnimated:YES completion:nil];
//        });
//    }];
//    
//    [request setFailedBlock:^{
//        //DLog(@"Order Error:%@",[request error]);
//        [[[UIAlertView alloc] initWithTitle:@"Order Error!" message:[NSString stringWithFormat:@"Error message:%@",request.error] delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
//    }];
//    
//    DLog(@"request content-type:%@",request.requestHeaders);
//    
//    [request startAsynchronous];
    
    
    //    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)finishOrder:(id)sender {
    if ([[self.productCart allKeys] count] <= 0) {
        [[[UIAlertView alloc] initWithTitle:@"Cart Empty." message:@"You don't have anything in your cart!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
        return;
    }
    //    CIFinalCustomerInfoViewController* ci = [[CIFinalCustomerInfoViewController alloc] initWithNibName:@"CIFinalCustomerInfoViewController" bundle:nil];
    //    ci.modalPresentationStyle = UIModalPresentationFormSheet;
    //    ci.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    //    ci.delegate = self.delegate;
    //    //    [ci setCustomerData:self.customerDB];
    //    [self presentModalViewController:ci animated:NO];
    
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
    //    else if(self.finishTheOrder){
    //        self.finishTheOrder();
    //    }
    [self dismissViewControllerAnimated:NO completion:nil];
}

//-(void) getCustomers{
//    NSString* url = [NSString stringWithFormat:@"%@?%@=%@",kDBGETCUSTOMERS,kAuthToken,self.authToken];
//    DLog(@"Sending %@", url);
//    
//    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
//    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
//        
//        DLog(@"JSON: %@", JSON);
//        
////        self.customerDB = [
//        
//    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
//        self.customerDB = nil;
//        [self dismissViewControllerAnimated:YES completion:nil];
//    }];
//    
//    [operation start];
//    
////    DLog(@"Sending %@",url);
////    __block ASIHTTPRequest* request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:url]];
////    
////    [request setCompletionBlock:^{
////        self.customerDB = [[request responseString] objectFromJSONString];
////        // DLog(@"Json:%@",self.customerDB);
////        customersReady = YES;
////    }];
////    
////    [request setFailedBlock:^{
////        self.customerDB = nil;
////        [self dismissViewControllerAnimated:YES completion:nil];
////        //DLog(@"error:%@", [request error]);
////    }];
////    
////    [request startAsynchronous];
//}

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
