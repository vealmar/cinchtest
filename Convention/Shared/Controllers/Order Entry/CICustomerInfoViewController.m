//
//  CICustomerInfoViewController.m
//  Convention
//
//  Created by Matthew Clark on 11/2/11.
//  Copyright (c) 2011 MotionMobs. All rights reserved.
//

#import "CICustomerInfoViewController.h"
#import "Customer.h"
#import "NotificationConstants.h"
#import "CICoreDataTableViewController.h"
#import "CICustomerTableViewController.h"


@interface CICustomerInfoViewController ()
@property (strong, nonatomic) UITapGestureRecognizer *outsideTapRecognizer;
@property (strong, nonatomic) IBOutlet CICustomerTableViewController *customerTableViewController;
@end

@implementation CICustomerInfoViewController {
    NSString *selectedCustomer;
}
@synthesize tablelayer;
@synthesize custView;
@synthesize searchText;
@synthesize delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tablelayer.layer.masksToBounds = YES;

    UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    self.searchText.leftView = paddingView;
    self.searchText.leftViewMode = UITextFieldViewModeAlways;
    self.searchText.layer.borderColor = [UIColor colorWithRed:0.820 green:0.816 blue:0.835 alpha:1].CGColor;
    self.searchText.layer.borderWidth = 1.0;

    self.customerTableViewController.tableView.separatorColor = [UIColor colorWithRed:0.820 green:0.816 blue:0.835 alpha:1];
    self.customerTableViewController.tableView.rowHeight = 56.0;
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

    [self.customerTableViewController queryCustomers:@""];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    if ([self.customerTableViewController.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.customerTableViewController.tableView setSeparatorInset:UIEdgeInsetsZero];
    }

    if ([self.customerTableViewController.tableView respondsToSelector:@selector(setLayoutMargins:)]) {
        [self.customerTableViewController.tableView setLayoutMargins:UIEdgeInsetsZero];
    }
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
    [self setCustView:nil];
    [self setTablelayer:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)submit:(NSNotification *)notification {

    Customer *selectedCustomer = (Customer *) notification.object;

    [searchText resignFirstResponder];

    if (selectedCustomer && self.delegate) {
        [self.view.window removeGestureRecognizer:self.outsideTapRecognizer];
        self.outsideTapRecognizer = nil;

        [self dismissViewControllerAnimated:YES completion:^{
            [self.delegate customerSelected:selectedCustomer.asDictionary];
        }];
    } else {
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Required Fields Missing!" message:@"Please finish filling out all required fields before submitting!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
//        [alert show];
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

- (void)viewWillAppear:(BOOL)animated {
    [self.customerTableViewController prepareForDisplay];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(submit:) name:CustomerSelectionNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:CustomersLoadedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:CustomerSelectionNotification object:nil];
}

#pragma mark search methods

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {

    NSString *search = [[textField.text stringByAppendingString:string] stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];//SG: if the character is newline, remove it. there was an issue where tapping return in the empty search box caused the logic below to search for customer with a new line in their id. When none was found, the list would display no customers. This is confusing to the users because they think of return as the submit action and not as a search term.
    if ([string isEqualToString:@""]) {
        search = [search substringToIndex:range.location];
    }
    [self.customerTableViewController queryCustomers:search];
    return YES;
}

@end
