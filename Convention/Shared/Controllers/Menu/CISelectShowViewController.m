//
// Created by septerr on 3/26/15.
// Copyright (c) 2015 Urban Coding. All rights reserved.
//

#import "CISelectShowViewController.h"
#import "Vendor.h"
#import "ThemeUtil.h"
#import "Show.h"
#import "DateUtil.h"
#import "NilUtil.h"
#import "CISelectShowTableViewController.h"
#import "CurrentSession.h"
#import "SettingsManager.h"


@implementation CISelectShowViewController {

}
- (void)viewDidLoad {
    [super viewDidLoad];
    [self registerTableViewController:[[CISelectShowTableViewController alloc] initWithStyle:UITableViewStylePlain]];
    self.selectTitle.text = @"Select Sales Period";
    self.selectSubtitle.text = @"Switch to a different Sales Period\n and take orders for that Sales Period.";
}

- (void)recordSelected:(NSManagedObject *)selectedRecord {
    Show *selectedShow = (Show *) selectedRecord;
    [self.searchText resignFirstResponder];
    if (selectedShow) {
        [self.view.window removeGestureRecognizer:self.outsideTapRecognizer];
        self.outsideTapRecognizer = nil;
        [[CurrentSession instance] setShow:selectedShow];
        [[SettingsManager sharedManager] setShowId:selectedShow.showId];
        [[CurrentSession instance] dispatchSessionDidChange];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

@end