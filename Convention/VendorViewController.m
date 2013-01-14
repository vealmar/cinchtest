//
//  VendorViewController.m
//  Convention
//
//  Created by Kerry Sanders on 1/12/13.
//  Copyright (c) 2013 MotionMobs. All rights reserved.
//

#import "VendorViewController.h"
#import "BulletinViewController.h"
#import "config.h"

@interface VendorViewController ()

@end

@implementation VendorViewController

@synthesize vendors;
@synthesize bulletins;
@synthesize parentPopover;
@synthesize delegate;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.tableView reloadData];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.title = @"Vendors";
    //self.navigationItem.leftBarButtonItem = nil;
    self.navigationItem.backBarButtonItem = nil;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return vendors.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    NSDictionary *details = [vendors objectAtIndex:indexPath.row];
    if ([details objectForKey:kVendorVendID] != nil)
        cell.textLabel.text = [NSString stringWithFormat:@"%@ - %@", [details objectForKey:kVendorVendID] != nil ? [details objectForKey:kVendorVendID] : @"", [details objectForKey:kVendorUsername]];
    else
        cell.textLabel.text = [NSString stringWithFormat:@"%@", [details objectForKey:kVendorUsername]];
    
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.tag = [[details objectForKey:@"id"] intValue];
    
    NSNumber *vendId = [NSNumber numberWithInt:0];
    if (cell.tag > 0)
        vendId = [NSNumber numberWithInt:[[details objectForKey:@"vendid"] intValue]];
    
    if (cell.tag > 0 && bulletins != nil && [bulletins objectForKey:vendId]) {
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        UIView* accessoryView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 24, 50)];
        UIImageView* accessoryViewImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"AccDisclosure.png"]];
        accessoryViewImage.center = CGPointMake(12, 25);
        [accessoryView addSubview:accessoryViewImage];
        [cell setAccessoryView:accessoryView];
    } else {
        [cell setAccessoryType:UITableViewCellAccessoryNone];
    }
    
    UIView* bg = [[UIView alloc] init];
    bg.backgroundColor = [UIColor colorWithRed:.94 green:.74 blue:.36 alpha:1.0];
    cell.selectedBackgroundView = bg;
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.delegate respondsToSelector:@selector(setVendor:)]) {
        UITableViewCell* cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
        int currentVendor = cell.tag;
        [self.delegate setVendor:currentVendor];
        if (currentVendor != 0) {
            int currentVendId = 0;
            NSUInteger index = [vendors indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
                int _id = [[obj objectForKey:@"id"] intValue];
                *stop = currentVendor == _id;
                return *stop;
            }];
            
            if (index != NSNotFound)
                currentVendId = [[[vendors objectAtIndex:index] objectForKey:@"vendid"] intValue];
            
            if (bulletins != nil && bulletins.count > 0) {
                BulletinViewController *bulletinViewController = [[BulletinViewController alloc] initWithNibName:@"BulletinViewController" bundle:nil];
                bulletinViewController.bulletins = [NSDictionary dictionaryWithDictionary:bulletins];
                bulletinViewController.currentVendId = currentVendId;
                bulletinViewController.delegate = self.delegate;
                [self.navigationController pushViewController:bulletinViewController animated:YES];
            } else
                [self.delegate dismissVendorPopover];
            
        } else {
            [self.delegate setBulletin:0];
            [self.delegate dismissVendorPopover];
        }
    }
}

@end
