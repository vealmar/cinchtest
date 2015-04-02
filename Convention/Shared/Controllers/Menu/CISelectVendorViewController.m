//
// Created by David Jafari on 2/6/15.
// Copyright (c) 2015 Urban Coding. All rights reserved.
//

#import "CISelectVendorViewController.h"
#import "CISelectVendorTableViewController.h"
#import "Vendor.h"
#import "CurrentSession.h"
#import "VendorDataLoader.h"


@implementation CISelectVendorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self registerTableViewController:[[CISelectVendorTableViewController alloc] initWithStyle:UITableViewStylePlain]];
    self.selectTitle.text = @"Select Vendor";
    self.selectSubtitle.text = @"Switch to a different vendor\n and take orders as them.";
}

- (void)recordSelected:(NSManagedObject *)selectedRecord {
    Vendor *selectedVendor = (Vendor *) selectedRecord;

    [self.searchText resignFirstResponder];

    if (selectedVendor) {
        [self.view.window removeGestureRecognizer:self.outsideTapRecognizer];
        self.outsideTapRecognizer = nil;

        void (^complete)() = ^{
            [[CurrentSession instance] dispatchSessionDidChange];
            [self dismissViewControllerAnimated:YES completion:self.onComplete];
        };

        [[CurrentSession instance] setVendor:selectedVendor];

        [VendorDataLoader load:@[ @(VendorDataTypeProducts), @(VendorDataTypeBulletins) ] inView:self.view onComplete:complete];
    }
}

@end