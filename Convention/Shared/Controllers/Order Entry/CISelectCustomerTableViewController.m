//
// Created by David Jafari on 1/27/15.
// Copyright (c) 2015 Urban Coding. All rights reserved.
//

#import "CISelectCustomerTableViewController.h"
#import "Customer.h"
#import "CoreDataUtil.h"
#import "CurrentSession.h"
#import "MBProgressHUD.h"
#import "CinchJSONAPIClient.h"
#import "NotificationConstants.h"
#import "ThemeUtil.h"

@interface CISelectCustomerTableViewController ()

@property PullToRefreshView *pull;

@end

@implementation CISelectCustomerTableViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.pull = [[PullToRefreshView alloc] initWithScrollView:self.tableView];
    [self.pull setDelegate:self];
    [self.tableView addSubview:self.pull];
}

- (NSFetchRequest *)query:(NSString *)queryString {
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Customer"];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"billname" ascending:YES]];

    NSMutableArray *predicates = [NSMutableArray arrayWithCapacity:4];
    if (queryString && queryString.length > 0) {
        [predicates addObject:[NSPredicate predicateWithFormat:@"billname CONTAINS[cd] %@", queryString]];
        [predicates addObject:[NSPredicate predicateWithFormat:@"custid CONTAINS[cd] %@", queryString]];
    }
    if (predicates.count > 0) {
        fetchRequest.predicate = [NSCompoundPredicate orPredicateWithSubpredicates:predicates];
    }

    self.fetchRequest = fetchRequest;
    return fetchRequest;
}

- (UITableViewCell *)tableView:(UITableView *)myTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    Customer *customer = [self objectAtIndexPath:indexPath];
    static NSString *CellIdentifier = @"CustCell";
    UITableViewCell *cell = [myTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    cell.textLabel.font = [UIFont regularFontOfSize:16];
    cell.textLabel.textColor = [UIColor colorWithRed:0.086 green:0.082 blue:0.086 alpha:1];
    cell.textLabel.text = [NSString stringWithFormat:@"%@ - %@", customer.billname, customer.custid];
    if (customer.defaultShippingAddressSummary) {
        cell.detailTextLabel.text = customer.defaultShippingAddressSummary;
        cell.detailTextLabel.font = [UIFont regularFontOfSize:12];
        cell.detailTextLabel.textColor = [ThemeUtil noteColor];
    } else {
        cell.detailTextLabel.text = @"";
    }
    return cell;
}

- (void)pullToRefreshViewShouldRefresh:(PullToRefreshView *)view; {
    [self reLoadCustomers:YES];
}

- (void)reLoadCustomers:(BOOL)triggeredByPullToRefresh {

    [[CurrentSession privateQueueContext] performBlockAndWait:^{
        [[CoreDataUtil sharedManager] deleteAllObjectsAndSave:@"Customer" withContext:[CurrentSession privateQueueContext]];
    }];

    MBProgressHUD *hud;
    if (!triggeredByPullToRefresh) {
        hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.removeFromSuperViewOnHide = YES;
        hud.labelText = @"Loading customers";
        [hud show:NO];
    }

    __weak CISelectCustomerTableViewController *weakSelf = self;
    [[CinchJSONAPIClient sharedInstance] getCustomersWithSession:[CurrentSession instance]
                                                          success:^(NSURLSessionDataTask *task, id JSON) {
                                                              [[CurrentSession privateQueueContext] performBlock:^{
                                                                  if (JSON && ([(NSArray *) JSON count] > 0)) {
                                                                      NSArray *customers = (NSArray *) JSON;
                                                                      for (NSDictionary *customer in customers) {
                                                                          [[CurrentSession privateQueueContext] insertObject:[[Customer alloc] initWithCustomerFromServer:customer context:[CurrentSession privateQueueContext]]];
                                                                      }
                                                                      [[CurrentSession privateQueueContext] save:nil];
                                                                  }
                                                                  [[CurrentSession mainQueueContext] performBlock:^{
                                                                      if (triggeredByPullToRefresh) {
                                                                          [weakSelf.pull finishedLoading];
                                                                      } else {
                                                                          [hud hide:NO];
                                                                      }
                                                                      [[NSNotificationCenter defaultCenter] postNotificationName:CustomersLoadedNotification object:nil];
                                                                      [weakSelf.tableView reloadData];
                                                                  }];
                                                              }];
                                                          } failure:^(NSURLSessionDataTask *task, NSError *error) {
                if (triggeredByPullToRefresh)
                    [weakSelf.pull finishedLoading];
                else
                    [hud hide:NO];
            }];
}


@end