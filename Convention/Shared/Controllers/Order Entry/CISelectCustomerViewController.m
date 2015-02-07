//
//  CISelectCustomerViewController.m
//  Convention
//
//  Created by Matthew Clark on 11/2/11.
//  Copyright (c) 2011 MotionMobs. All rights reserved.
//

#import "CISelectCustomerViewController.h"
#import "Customer.h"
#import "CISelectCustomerTableViewController.h"

@implementation CISelectCustomerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self registerTableViewController:[[CISelectCustomerTableViewController alloc] initWithStyle:UITableViewStylePlain]];
    self.selectTitle.text = @"Create New Order";
    self.selectSubtitle.text = @"Select from your buyers, or\nstart fresh with a new customer.";
}

- (void)recordSelected:(NSManagedObject *)selectedRecord {

    Customer *selectedCustomer = (Customer *) selectedRecord;

    [self.searchText resignFirstResponder];

    if (selectedCustomer && self.delegate) {
        [self.view.window removeGestureRecognizer:self.outsideTapRecognizer];
        self.outsideTapRecognizer = nil;

        [self dismissViewControllerAnimated:YES completion:^{
            [self.delegate customerSelected:selectedCustomer.asDictionary];
        }];
    }
}

@end
