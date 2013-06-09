//
//  CICustomerInfoViewController.m
//  Convention
//
//  Created by Matthew Clark on 11/2/11.
//  Copyright (c) 2011 MotionMobs. All rights reserved.
//

#import "CICustomerInfoViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "JSONKit.h"
#import "MBProgressHUD.h"
#import "Macros.h"
#import "config.h"
#import "SettingsManager.h"
#import "CustomerDataController.h"

@implementation CICustomerInfoViewController {
    MBProgressHUD* refreshing;
    NSString *selectedCustomer;
}
@synthesize tablelayer;
@synthesize custTable;
@synthesize custView;
@synthesize searchText;
@synthesize delegate;
@synthesize tableData;
@synthesize filteredtableData;
@synthesize authToken;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(customersLoaded:) name:kNotificationCustomersLoaded object:nil];
        
        // Custom initialization
        self.tableData = [NSArray array];
        //DLog(@"CI init'd");
    }
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.custTable reloadData];
//    if ([self.tableData count] > 0) {
//        self.search.text = [[self.tableData objectAtIndex:0] objectForKey:kCustID];
//        [self.custTable selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionTop];
//    }
    
    self.tablelayer.layer.masksToBounds = YES;
    self.tablelayer.layer.cornerRadius = 10.f;
    //for testing
    //WARNING!!!
    //self.Authorizer.text = @"testing";
    // Do any additional setup after loading the view from its nib.
}

-(void) customersLoaded:(NSNotification*)notif {
    if (notif.userInfo){
        NSArray* customerData = [notif.userInfo objectForKey:kCustomerNotificationKey];
        [self setCustomerData:customerData];
    }
}

-(void) setCustomerData:(NSArray *)customerData
{
    DLog(@"Load customer data");

    NSMutableArray* arr = [NSMutableArray array];
    for (int i=0; i<[customerData count]; i++) {
//        if (i==0) {
//            DLog(@"search before:%@",self.search.text);
//            self.search.text = [[customerData objectAtIndex:0] objectForKey:kCustID];
//            DLog(@"search after:%@, %@",self.search.text,[[customerData objectAtIndex:0] objectForKey:kCustID]);
//        }
        NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:[[customerData objectAtIndex:i] objectForKey:kCustID],kCustID,[[customerData objectAtIndex:i] objectForKey:kBillName],kBillName,[[customerData objectAtIndex:i] objectForKey:kID],kID,[[customerData objectAtIndex:i] objectForKey:kEmail],kEmail,[[customerData objectAtIndex:i] objectForKey:kStores],kStores, nil];
        [arr addObject:dict];
    }
    if (self.tableData) {
        self.tableData = nil;
    }
    self.tableData = [arr copy];
    self.filteredtableData = [arr mutableCopy];
    [self.custTable reloadData];
    
//    if ([self.tableData count] > 0)
//        [self.custTable selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionTop];
    
    if (refreshing) {
        [refreshing hide:YES];
        refreshing = nil;
    }
}

- (IBAction)back:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        if (self.delegate) {
            [self.delegate Cancel];
        }
    }];
}

- (IBAction)refresh:(id)sender {
    refreshing = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    refreshing.labelText = @"Refreshing";
    [refreshing show:YES];
    [CustomerDataController loadCustomers:self.authToken];
}

- (IBAction)handleTap:(UITapGestureRecognizer *)sender {
    if ([searchText isFirstResponder])
        [searchText resignFirstResponder];
}

-(BOOL)disablesAutomaticKeyboardDismissal {
    return NO;
}

- (void)viewDidUnload
{
    [self setCustTable:nil];
    [self setCustView:nil];
    [self setTablelayer:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

- (IBAction)submit:(id)sender {
    //if (IS_EMPTY_STRING(self.customerID.text)||[self.customerID.text isEqualToString:@"New Customer"]) {
        if (!IS_EMPTY_STRING(selectedCustomer)) {
        //if (self.delegate) {
            //NSDictionary* arr = [[NSDictionary alloc] initWithObjectsAndKeys:customerName.text,kCustName,storeName.text,kStoreName,city.text,kCity, nil];
            //[self.delegate setCustomerInfo:arr];
        //}
            if (self.delegate) {
                __block int custid = 0;
                __block NSDictionary* results= nil;
                [self.tableData enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop){
                    if ([obj isKindOfClass:[NSDictionary class]]) {
                        NSDictionary* dict = (NSDictionary*)obj;
                        
//                        if ([[dict objectForKey:kCustID]isEqualToString:self.search.text]){//self.customerID.text]) {
                        if ([[dict objectForKey:kCustID] isEqualToString:selectedCustomer]) {
                            custid = [[dict objectForKey:kID] intValue];
                            results = [dict copy];
                            *stop = YES;
                        }
                    }
                }];
                
                if (custid == 0) {
                    UIAlertView* alert =[[UIAlertView alloc] initWithTitle:@"Incorrect CustomerID" message:@"Please select an entry from the table of known customers or select \"New Customer\"." delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
                    [alert show];
                }
                else
                {
//                    if (self.sendEmail.on) {
//                        if (IS_EMPTY_STRING(self.email.text)) {
//                            UIAlertView* alert =[[UIAlertView alloc] initWithTitle:@"Missing Recipt Email!" message:@"You have selected to send an email recipt, but not provided an email." delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
//                            [alert show];
//                        }
//                        else
//                        {
//                            NSDictionary* arr = [[NSDictionary alloc] initWithObjectsAndKeys:[NSString stringWithFormat:@"%d",custid],kOrderCustID, self.shippingNotes.text,kShipNotes,self.Notes.text,kNotes,self.Authorizer.text,kAuthorizedBy,@"1",kSendEmail,self.email.text,kEmail, nil];
//                            DLog(@"info to send:%@",arr);
//                            [self.delegate setCustomerInfo:arr];
//                            [self dismissModalViewControllerAnimated:YES];
//                        }
//                    }
//                    else
//                    {
//                        NSDictionary* arr = [[NSDictionary alloc] initWithObjectsAndKeys:[NSString stringWithFormat:@"%d",custid],kOrderCustID, nil];//, self.shippingNotes.text,kShipNotes,self.Notes.text,kNotes,self.Authorizer.text,kAuthorizedBy,@"0",kSendEmail,@"",kEmail
                        DLog(@"info to send:%@",results);
                        [self.delegate setCustomerInfo:results];
                        [self dismissViewControllerAnimated:YES completion:nil];
//                    }
                }
            }
        }
        else{
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Required Fields Missing!" message:@"Please finish filling out all required fields before submitting!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
    //}
    //else
    //{
        
    //}
}

#pragma mark - Table stuff
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)myTableView numberOfRowsInSection:(NSInteger)section {
    
    return self.filteredtableData != nil ? [self.filteredtableData count] : 0;
}

- (UITableViewCell *)tableView:(UITableView *)myTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (!self.filteredtableData) {
        return nil;
    }
    
    static NSString *CellIdentifier = @"CustCell";
    UITableViewCell *cell = [myTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    //cell.detailTextLabel.text = [[self.tableData objectAtIndex:[indexPath row]] objectForKey:kCustID];
    cell.textLabel.text = [NSString stringWithFormat:@"%@ - %@", [[self.filteredtableData objectAtIndex:[indexPath row]] objectForKey:kBillName],[[self.filteredtableData objectAtIndex:[indexPath row]] objectForKey:kCustID]];
    cell.tag = [[[self.filteredtableData objectAtIndex:[indexPath row]] objectForKey:kID] intValue];
    //cell.subtitle.text = [[[self.productData objectAtIndex:[indexPath row]] objectForKey:@"id"] stringValue];
    
    return (UITableViewCell *)cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    DLog(@"customer details:%@",[self.filteredtableData objectAtIndex:[indexPath row]]);
    //self.customerID.text = [[self.filteredtableData objectAtIndex:[indexPath row]] objectForKey:kCustID];

//    self.search.text = [[self.filteredtableData objectAtIndex:[indexPath row]] objectForKey:kCustID];
    selectedCustomer = [[self.filteredtableData objectAtIndex:[indexPath row]] objectForKey:kCustID];

//    [tableView becomeFirstResponder];
//    [tableView resignFirstResponder];
    [searchText resignFirstResponder];
}

////method to move the view up/down whenever the keyboard is shown/dismissed
////method to move the view up/down whenever the keyboard is shown/dismissed
//-(void)setViewMovedUp:(BOOL)movedUp
//{
//    [UIView beginAnimations:nil context:NULL];
//    [UIView setAnimationDuration:0.5]; // if you want to slide up the view
//    
//    CGRect rect = self.scroll.frame;
//    if (movedUp)
//    {
//        // 1. move the view's origin up so that the text field that will be hidden come above the keyboard 
//        // 2. increase the size of the view so that the area behind the keyboard is covered up.
//        rect.origin.y += kOFFSET_FOR_KEYBOARD;//was -
//        //rect.size.height += kOFFSET_FOR_KEYBOARD;
//    }
//    else
//    {
//        // revert back to the normal state.
//        rect.origin.y -= (kOFFSET_FOR_KEYBOARD-15);//was +
//        //rect.size.height -= kOFFSET_FOR_KEYBOARD;
//    }
//    self.scroll.contentOffset = rect.origin;
//    
//    [UIView commitAnimations];
//}
//
//-(void)setViewMovedUpDouble:(BOOL)movedUp
//{
//    [UIView beginAnimations:nil context:NULL];
//    [UIView setAnimationDuration:0.5]; // if you want to slide up the view
//    
//    CGRect rect = self.scroll.frame;
//    if (movedUp)
//    {
//        // 1. move the view's origin up so that the text field that will be hidden come above the keyboard 
//        // 2. increase the size of the view so that the area behind the keyboard is covered up.
//        rect.origin.y += kOFFSET_FOR_KEYBOARD*2;//was -
//        //rect.size.height += kOFFSET_FOR_KEYBOARD;
//    }
//    else
//    {
//        // revert back to the normal state.
//        rect.origin.y -= (kOFFSET_FOR_KEYBOARD-7);//was +
//        //rect.size.height -= kOFFSET_FOR_KEYBOARD;
//    }
//    self.scroll.contentOffset = rect.origin;
//    
//    [UIView commitAnimations];
//}

- (void)viewWillAppear:(BOOL)animated
{
    // register for keyboard notifications
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) 
//                                                 name:UIKeyboardWillShowNotification object:self.view.window]; 
}

- (void)viewWillDisappear:(BOOL)animated
{
    // unregister for keyboard notifications while not visible.
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil]; 
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNotificationCustomersLoaded object:nil];
}

#pragma mark search methods

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    NSString *search = [[textField.text stringByAppendingString:string] stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];//SG: if the character is newline, remove it. there was an issue where tapping return in the empty search box caused the logic below to search for customer with a new line in their id. When none was found, the list would display no customers. This is confusing to the users because they think of return as the submit action and not as a search term.
    if ([string isEqualToString:@""]) {
        search = [search substringToIndex:range.location];
    }
    [self.filteredtableData removeAllObjects];// remove all data that belongs to previous search
    if([search isEqualToString:@""]){
        self.filteredtableData = [tableData mutableCopy];
        [self.custTable reloadData];
        return YES;
    }
    for(NSDictionary *dict in tableData)
    {
        NSRange r = [[dict objectForKey:kCustID] rangeOfString:search options:NSCaseInsensitiveSearch];
        if(r.location != NSNotFound)
        {
            if(r.location== 0)//that is we are checking only the start of the names.
            {
                [self.filteredtableData addObject:dict];
            }
        }else{
            NSRange r = [[dict objectForKey:kBillName] rangeOfString:search options:NSCaseInsensitiveSearch];
            if(r.location != NSNotFound)
            {
                [self.filteredtableData addObject:dict];
            }
        }
    }
    if([self.filteredtableData count] == 0){
        //nothing matched the search, load all customers.

    }
    [self.custTable reloadData];
    return YES;
}

//- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
//{
//    // only show the status bar’s cancel button while in edit mode
//    searchBar.showsCancelButton = YES;
//    searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
//    // flush the previous search content
////    [self.filteredtableData removeAllObjects];
////    self.filteredtableData = [tableData mutableCopy];
//}
//
//- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
//{
////    searchBar.showsCancelButton = NO;
//    if ([searchBar isFirstResponder])
//        [searchBar resignFirstResponder];
//    if (searchBar.text.length == 0) {
//        self.filteredtableData = [tableData mutableCopy];
//        [self.custTable reloadData];
//    }
//}
//
//- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
//{
//    [self.filteredtableData removeAllObjects];// remove all data that belongs to previous search
//    if([searchText isEqualToString:@""]||searchText==nil){
//        self.filteredtableData = [tableData mutableCopy];
//        [self.custTable reloadData];
//        return;
//    }
//    for(NSDictionary *dict in tableData)
//    {
//        NSRange r = [[dict objectForKey:kCustID] rangeOfString:searchText options:NSCaseInsensitiveSearch];
//        if(r.location != NSNotFound)
//        {
//            if(r.location== 0)//that is we are checking only the start of the names.
//            {
//                [self.filteredtableData addObject:dict];
//            }
//        }else{
//            NSRange r = [[dict objectForKey:kBillName] rangeOfString:searchText options:NSCaseInsensitiveSearch];
//            if(r.location != NSNotFound)
//            {
//                [self.filteredtableData addObject:dict];
//            }
//        }
//    }
//    [self.custTable reloadData];
//}
//
//- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
//{
//    // if a valid search was entered but the user wanted to cancel, bring back the main list content
//    searchBar.showsCancelButton = NO;
//    [self.filteredtableData removeAllObjects];
////    [self.filteredtableData addObjectsFromArray:tableData];
//    self.filteredtableData = [tableData mutableCopy];
//    @try{
//        [self.custTable reloadData];
////        self.search.text = [[self.filteredtableData objectAtIndex:0] objectForKey:kCustID];
//    }
//    @catch(NSException *e){
//        DLog(@"Exception:%@",e);
//    }
//    [searchBar resignFirstResponder];
//    //searchBar.text = @"";
//}

//// called when Search (in our case “Done”) button pressed
//- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
//{
//    [searchBar resignFirstResponder];
//}

@end
