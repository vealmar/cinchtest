//
//  BulletinViewController.m
//  Convention
//
//  Created by Kerry Sanders on 1/13/13.
//  Copyright (c) 2013 MotionMobs. All rights reserved.
//

#import "BulletinViewController.h"
#import "ShowConfigurations.h"
#import "Underscore.h"

@interface BulletinViewController ()

@end

@implementation BulletinViewController

@synthesize bulletins;
@synthesize currentVendId;
@synthesize delegate;

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.title = @"Brands";
    //self.navigationItem.leftBarButtonItem = nil;
    self.navigationItem.backBarButtonItem = nil;
}

- (NSArray *)currentBulletins {
    if ([ShowConfigurations instance].vendorMode) {
        NSMutableArray *combinedBulletins = [Underscore.array([bulletins allValues]).flatten.filter(^BOOL(NSDictionary *dictionary) {
            return ![[dictionary valueForKey:@"id"] isEqual:@(0)];
        }).sort(^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
            return [[a objectForKey:@"name"] compare:[b objectForKey:@"name"]];
        }).unwrap mutableCopy];
        [combinedBulletins insertObject:@{ @"id" : @(0), @"name" : @"Any" } atIndex:0];
        return [NSArray arrayWithArray:combinedBulletins];
    } else {
        return [bulletins objectForKey:[NSNumber numberWithInt:currentVendId]];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *bulls = [self currentBulletins];
    if (bulletins != nil)
        return [bulls count];
    else
        return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }

    NSDictionary *details = [[self currentBulletins] objectAtIndex:[indexPath row]];
    if ([details objectForKey:@"name"] != nil)
        cell.textLabel.text = [details objectForKey:@"name"];
    else
        cell.textLabel.text = [details objectForKey:@"id"];
    cell.tag = [[details objectForKey:@"id"] intValue];
//    cell.textLabel.textColor = [UIColor whiteColor];
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.accessoryView = nil;

//    UIView* bg = [[UIView alloc] init];
//    bg.backgroundColor = [UIColor colorWithRed:.94 green:.74 blue:.36 alpha:1.0];
//    cell.selectedBackgroundView = bg;

    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.delegate respondsToSelector:@selector(setBulletin:)]) {
        UITableViewCell *cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
        [self.delegate setBulletin:cell.tag];
        [self.delegate dismissVendorPopover];
    }
}

@end
