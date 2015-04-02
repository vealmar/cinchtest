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
#import "Configurations.h"
#import "NotificationConstants.h"
#import "CICustomerRecordViewController.h"

@implementation CISelectCustomerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self registerTableViewController:[[CISelectCustomerTableViewController alloc] initWithStyle:UITableViewStylePlain]];
    self.selectTitle.text = @"Create New Order";
    self.selectSubtitle.text = @"Select from your buyers, or\nstart fresh with a new customer.";

}

- (void)viewWillAppear:(BOOL)animated {
    [self.tableViewController prepareForDisplay];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(customerCreated:) name:CustomerCreatedNotification object:nil];
}

- (BOOL)allowAddAction {
    return [Configurations instance].vendorMode;
}

- (IBAction)buttonAddTapped:(id)sender {
    CICustomerRecordViewController *customerRecordViewController = [[CICustomerRecordViewController alloc] init];
    customerRecordViewController.modalPresentationStyle = UIModalPresentationFormSheet;
    customerRecordViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [customerRecordViewController prepareForDisplay:nil];
    [self presentViewController:customerRecordViewController animated:YES completion:nil];
}

- (void)customerCreated:(NSNotification *)notification {
    Customer *customer = notification.object;
    if (customer) {
        self.searchText.text = customer.billname;
        [self.tableViewController query:customer.billname];
    }
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
