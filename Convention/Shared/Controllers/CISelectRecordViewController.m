//
// Created by David Jafari on 2/6/15.
// Copyright (c) 2015 Urban Coding. All rights reserved.
//

#import "CISelectRecordViewController.h"

@interface CISelectRecordViewController ()
@property (strong, nonatomic) CISelectRecordTableViewController *tableViewController;
@end

@implementation CISelectRecordViewController

@synthesize tablelayer;
@synthesize custView;
@synthesize searchText;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.modalPresentationStyle = UIModalPresentationFormSheet;
        self.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    }
    return self;
}

- (void)registerTableViewController:(CISelectRecordTableViewController *)controller {
    controller.view = self.tableView;
    self.tableView.delegate = controller;
    self.tableView.dataSource = controller;
    self.tableViewController = controller;
    controller.delegate = self;
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

    self.tableViewController.tableView.separatorColor = [UIColor colorWithRed:0.820 green:0.816 blue:0.835 alpha:1];
    self.tableViewController.tableView.rowHeight = 56.0;
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

    [self.tableViewController query:@""];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    if ([self.tableViewController.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.tableViewController.tableView setSeparatorInset:UIEdgeInsetsZero];
    }

    if ([self.tableViewController.tableView respondsToSelector:@selector(setLayoutMargins:)]) {
        [self.tableViewController.tableView setLayoutMargins:UIEdgeInsetsZero];
    }
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

- (void)viewWillAppear:(BOOL)animated {
    [self.tableViewController prepareForDisplay];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
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

#pragma mark search methods

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {

    NSString *search = [[textField.text stringByAppendingString:string] stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    if ([string isEqualToString:@""]) {
        search = [search substringToIndex:range.location];
    }
    [self.tableViewController query:search];
    return YES;
}

@end