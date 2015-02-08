//
// Created by David Jafari on 2/6/15.
// Copyright (c) 2015 Urban Coding. All rights reserved.
//

#import "CISelectVendorViewController.h"
#import "CISelectVendorTableViewController.h"
#import "Vendor.h"
#import "CurrentSession.h"
#import "VendorDataLoader.h"
#import "config.h"


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

        NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:[CurrentSession instance].userInfo];
        userInfo[kID] = selectedVendor.vendorId;
        userInfo[kVendorGroupID] = selectedVendor.vendorgroup_id;
        userInfo[kName] = selectedVendor.name;
        [CurrentSession instance].userInfo = [NSDictionary dictionaryWithDictionary:userInfo];

        [VendorDataLoader load:@[ @(VendorDataTypeProducts), @(VendorDataTypeBulletins) ] inView:self.view onComplete:complete];
    }
}

@end