//
//  CICustomerInfoViewController.m
//  Convention
//
//  Created by Matthew Clark on 11/2/11.
//  Copyright (c) 2011 MotionMobs. All rights reserved.
//

#import "CICustomerInfoViewController.h"
#import "MBProgressHUD.h"
#import "Macros.h"
#import "config.h"
#import "SettingsManager.h"
#import "CoreDataManager.h"
#import "Customer.h"
#import "CoreDataUtil.h"
#import "NotificationConstants.h"
#import "CinchJSONAPIClient.h"


@interface CICustomerInfoViewController ()
@property (strong, nonatomic) UITapGestureRecognizer *outsideTapRecognizer;
@end

@implementation CICustomerInfoViewController {
    NSString *selectedCustomer;
    PullToRefreshView *pull;
}
@synthesize tablelayer;
@synthesize custTable;
@synthesize custView;
@synthesize searchText;
@synthesize delegate;
@synthesize tableData;
@synthesize filteredtableData;
@synthesize authToken;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.tableData = [NSArray array];
    }
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.custTable reloadData];
    self.tablelayer.layer.masksToBounds = YES;
    pull = [[PullToRefreshView alloc] initWithScrollView:self.custTable];
    [pull setDelegate:self];
    [self.custTable addSubview:pull];

    UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    self.searchText.leftView = paddingView;
    self.searchText.leftViewMode = UITextFieldViewModeAlways;
    self.searchText.layer.borderColor = [UIColor colorWithRed:0.820 green:0.816 blue:0.835 alpha:1].CGColor;
    self.searchText.layer.borderWidth = 1.0;

    self.custTable.separatorColor = [UIColor colorWithRed:0.820 green:0.816 blue:0.835 alpha:1];
    self.custTable.rowHeight = 56.0;
}

- (void)handleTapBehind:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        CGPoint l = [sender locationInView:self.view];

        if (![self.view pointInside:l withEvent:nil]) {
            [self.view.window removeGestureRecognizer:self.outsideTapRecognizer];
            self.outsideTapRecognizer = nil;

            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self dismissViewControllerAnimated:YES completion:nil];
            });
        }
    }
}

- (IBAction)buttonAddTapped:(id)sender {
}

- (void)viewDidAppear:(BOOL)animated {
    [self.view.window removeGestureRecognizer:self.outsideTapRecognizer];
    self.outsideTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapBehind:)];
    [self.outsideTapRecognizer setNumberOfTapsRequired:1];
    self.outsideTapRecognizer.cancelsTouchesInView = NO;
    self.outsideTapRecognizer.delegate = self;
    [self.view.window addGestureRecognizer:self.outsideTapRecognizer];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    if ([self.custTable respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.custTable setSeparatorInset:UIEdgeInsetsZero];
    }

    if ([self.custTable respondsToSelector:@selector(setLayoutMargins:)]) {
        [self.custTable setLayoutMargins:UIEdgeInsetsZero];
    }
}

- (void)setCustomerData:(NSArray *)customerData {
    NSMutableArray *arr = [NSMutableArray array];
    for (int i = 0; i < [customerData count]; i++) {//todo: is this second conversion necessary?
        [arr addObject:[customerData objectAtIndex:(NSUInteger) i]];
    }
    if (self.tableData) {
        self.tableData = nil;
    }
    self.tableData = [arr copy];
    self.filteredtableData = [arr mutableCopy];
    [self.custTable reloadData];
}

- (IBAction)back:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)handleTap:(UITapGestureRecognizer *)sender {
    if ([searchText isFirstResponder])
        [searchText resignFirstResponder];
}

- (BOOL)disablesAutomaticKeyboardDismissal {
    return NO;
}

- (void)viewDidUnload {
    [self setCustTable:nil];
    [self setCustView:nil];
    [self setTablelayer:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (IBAction)submit:(id)sender {
    if (!IS_EMPTY_STRING(selectedCustomer)) {
        if (self.delegate) {
            __block int custid = 0;
            __block NSDictionary *results = nil;
            [self.tableData enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                if ([obj isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *dict = (NSDictionary *) obj;

                    if ([[dict objectForKey:kCustID] isEqualToString:selectedCustomer]) {
                        custid = [[dict objectForKey:kID] intValue];
                        results = [dict copy];
                        *stop = YES;
                    }
                }
            }];

            if (custid == 0) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Incorrect CustomerID" message:@"Please select an entry from the table of known customers or select \"New Customer\"." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alert show];
            }
            else {
                [self.view.window removeGestureRecognizer:self.outsideTapRecognizer];
                self.outsideTapRecognizer = nil;

                [self dismissViewControllerAnimated:YES completion:^{
                    [self.delegate customerSelected:results];
                }];
            }
        }
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Required Fields Missing!" message:@"Please finish filling out all required fields before submitting!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}

#pragma mark - UIGestureRecognizer Delegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return YES;
}

#pragma mark - Table stuff
-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }

    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)myTableView numberOfRowsInSection:(NSInteger)section {

    return self.filteredtableData != nil ? [self.filteredtableData count] : 0;
}

- (UITableViewCell *)tableView:(UITableView *)myTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"CustCell";
    UITableViewCell *cell = [myTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    cell.textLabel.font = [UIFont regularFontOfSize:16];
    cell.textLabel.textColor = [UIColor colorWithRed:0.086 green:0.082 blue:0.086 alpha:1];
    cell.textLabel.text = [NSString stringWithFormat:@"%@ - %@", [[self.filteredtableData objectAtIndex:(NSUInteger) [indexPath row]] objectForKey:kBillName], [[self.filteredtableData objectAtIndex:(NSUInteger) [indexPath row]] objectForKey:kCustID]];
    cell.tag = [[[self.filteredtableData objectAtIndex:(NSUInteger) [indexPath row]] objectForKey:kID] intValue];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    selectedCustomer = [[self.filteredtableData objectAtIndex:(NSUInteger) [indexPath row]] objectForKey:kCustID];
    [searchText resignFirstResponder];
    [self submit:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    NSArray *customers = [CoreDataManager getCustomers:self.managedObjectContext];
    if (customers && customers.count > 0) {//todo use ACustomer objects
        NSMutableArray *customerData = [[NSMutableArray alloc] init];
        for (Customer *customer in customers) {
            [customerData addObject:[customer asDictionary]];
        }
        self.customerData = customerData;
    } else {
        [self reLoadCustomers:NO];
    }
}

- (void)pullToRefreshViewShouldRefresh:(PullToRefreshView *)view; {
    [self reLoadCustomers:YES];
}

- (void)reLoadCustomers:(BOOL)triggeredByPullToRefresh {
    [[CoreDataUtil sharedManager] deleteAllObjects:@"Customer"];
    MBProgressHUD *hud;
    if (!triggeredByPullToRefresh) {
        hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.removeFromSuperViewOnHide = YES;
        hud.labelText = @"Loading customers";
        [hud show:NO];
    }

    [[CinchJSONAPIClient sharedInstance] GET:kDBGETCUSTOMERS parameters:@{ kAuthToken: authToken } success:^(NSURLSessionDataTask *task, id JSON) {
        if (JSON && ([(NSArray *) JSON count] > 0)) {
            NSArray *customers = (NSArray *) JSON;
            for (NSDictionary *customer in customers) {
                [self.managedObjectContext insertObject:[[Customer alloc] initWithCustomerFromServer:customer context:self.managedObjectContext]];
            }
            [[CoreDataUtil sharedManager] saveObjects];
        }
        [self setCustomerData:(NSArray *) JSON];
        if (triggeredByPullToRefresh)
            [pull finishedLoading];
        else
            [hud hide:NO];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        [self setCustomerData:nil];
        if (triggeredByPullToRefresh)
            [pull finishedLoading];
        else
            [hud hide:NO];
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:CustomersLoadedNotification object:nil];
}

#pragma mark search methods

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {

    NSString *search = [[textField.text stringByAppendingString:string] stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];//SG: if the character is newline, remove it. there was an issue where tapping return in the empty search box caused the logic below to search for customer with a new line in their id. When none was found, the list would display no customers. This is confusing to the users because they think of return as the submit action and not as a search term.
    if ([string isEqualToString:@""]) {
        search = [search substringToIndex:range.location];
    }
    [self.filteredtableData removeAllObjects];// remove all data that belongs to previous search
    if ([search isEqualToString:@""]) {
        self.filteredtableData = [tableData mutableCopy];
        [self.custTable reloadData];
        return YES;
    }
    for (NSDictionary *dict in tableData) {
        NSRange r = [[dict objectForKey:kCustID] rangeOfString:search options:NSCaseInsensitiveSearch];
        if (r.location != NSNotFound) {
            if (r.location == 0)//that is we are checking only the start of the names.
            {
                [self.filteredtableData addObject:dict];
            }
        } else {
            NSRange r = [[dict objectForKey:kBillName] rangeOfString:search options:NSCaseInsensitiveSearch];
            if (r.location != NSNotFound) {
                [self.filteredtableData addObject:dict];
            }
        }
    }
    [self.custTable reloadData];
    return YES;
}

@end
