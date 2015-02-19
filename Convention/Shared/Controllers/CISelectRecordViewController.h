//
// Created by David Jafari on 2/6/15.
// Copyright (c) 2015 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CISelectRecordTableViewController.h"

@class CISelectRecordTableViewController;

@interface CISelectRecordViewController : UIViewController <CISelectRecordDelegate, UITextFieldDelegate, UIGestureRecognizerDelegate>

@property(unsafe_unretained, nonatomic) IBOutlet UIView *tablelayer;
@property(strong, nonatomic) IBOutlet UITableView *tableView;
@property(strong, nonatomic) IBOutlet UIView *custView;
@property(strong, nonatomic) IBOutlet UILabel *selectTitle;
@property(strong, nonatomic) IBOutlet UILabel *selectSubtitle;
@property(weak, nonatomic) IBOutlet UITextField *searchText;
@property (strong, nonatomic) CISelectRecordTableViewController *tableViewController;

@property (strong, nonatomic) UITapGestureRecognizer *outsideTapRecognizer;

- (BOOL)allowAddAction;

- (IBAction)buttonAddTapped:(id)sender;

- (IBAction)handleTap:(UITapGestureRecognizer *)sender;

- (void)registerTableViewController:(CISelectRecordTableViewController *)controller;

@end