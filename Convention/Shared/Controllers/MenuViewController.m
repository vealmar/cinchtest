//
//  MenuViewController.m
//  Convention
//
//  Created by Bogdan Covaci on 18.11.2014.
//  Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import "MenuViewController.h"
#import "ShowConfigurations.h"
#import "CIAppDelegate.h"
#import "FXBlurView.h"


@interface MenuViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *logoImageView;
@property (weak, nonatomic) IBOutlet UIButton *orderButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet UIView *topContentView;
@property (weak, nonatomic) IBOutlet UIImageView *vendorLogo;
@property (weak, nonatomic) IBOutlet UIImageView *vendorBackgroundImageView;
@property (weak, nonatomic) IBOutlet FXBlurView *blurView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;

@property (weak, nonatomic) IBOutlet UIButton *helpButton;
@property (weak, nonatomic) IBOutlet UIButton *logoutButton;
@end

@implementation MenuViewController

- (void)viewDidLoad {
    self.view.backgroundColor = [UIColor colorWithRed:0.235 green:0.247 blue:0.251 alpha:1];

    self.topContentView.backgroundColor = [UIColor clearColor];

    self.logoImageView.backgroundColor = [UIColor colorWithRed:0.161 green:0.169 blue:0.169 alpha:1];
    self.logoImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.logoImageView.image = [ShowConfigurations instance].logo;

    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 5)];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];

    self.orderButton.titleEdgeInsets = UIEdgeInsetsMake(0, -90, 0, 0);
    self.orderButton.titleLabel.font = [UIFont regularFontOfSize:18];
    [self.orderButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.orderButton setTitle:@"Order Writer" forState:UIControlStateNormal];

    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.font = [UIFont semiboldFontOfSize:24];
    self.titleLabel.text = @"VND-ALL 100";

    self.subtitleLabel.textColor = [UIColor whiteColor];
    self.subtitleLabel.font = [UIFont regularFontOfSize:18];
    self.subtitleLabel.text = @"Elletr Brothers January 2015";

    [self.logoutButton bk_addEventHandler:^(id sender) {
        CIAppDelegate *appDelegate = (CIAppDelegate*)[UIApplication sharedApplication].delegate;
        [appDelegate.slideMenu hideMenu:YES];

        [self.orderViewController logout:nil];
    } forControlEvents:UIControlEventTouchUpInside];

    [self.orderButton bk_addEventHandler:^(id sender) {
        CIAppDelegate *appDelegate = (CIAppDelegate*)[UIApplication sharedApplication].delegate;
        [appDelegate.slideMenu hideMenu:YES];

        [self.orderViewController AddNewOrder:nil];
    } forControlEvents:UIControlEventTouchUpInside];
}

#pragma mark - tableview
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return 2;
        case 1:
            return 3;
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *c = [tableView dequeueReusableCellWithIdentifier:@"cell"];

    UILabel *leftLabel = (UILabel*)[c.contentView viewWithTag:100];
    UILabel *rightLabel = (UILabel*)[c.contentView viewWithTag:101];

    if (!leftLabel) {
        leftLabel = [[UILabel alloc] initWithFrame:CGRectMake(18, 0, 20, c.bounds.size.height)];
        leftLabel.font = [UIFont iconAltFontOfSize:16];
        leftLabel.textColor = [UIColor colorWithRed:0.576 green:0.592 blue:0.600 alpha:1];
        [c.contentView addSubview:leftLabel];
    }

    if (!rightLabel) {
        rightLabel = [[UILabel alloc] initWithFrame:CGRectMake(18 + 25, 0, c.bounds.size.width - 18 - 25, c.bounds.size.height)];
        rightLabel.font = [UIFont regularFontOfSize:16];
        rightLabel.textColor = [UIColor whiteColor];
        [c.contentView addSubview:rightLabel];
    }

    switch (indexPath.section) {
        case 0: {
            switch (indexPath.row) {
                case 0: {
                    leftLabel.text = @"\ue203";
                    rightLabel.text = @"N Products";
                    break;
                }
                case 1: {
                    leftLabel.text = @"\ue453";
                        rightLabel.text = @"N Customers";
                    break;
                }
            }
            break;
        }
        case 1: {
            switch (indexPath.row) {
                case 0: {
                    leftLabel.text = @"\ue063";
                    rightLabel.text = @"Sales by Brand";
                    break;
                }
                case 1: {
                    leftLabel.text = @"\ue203";
                    rightLabel.text = @"Sales by Product";
                    break;
                }
                case 2: {
                    leftLabel.text = @"\ue453";
                    rightLabel.text = @"Sales by Customer";
                    break;
                }
            }
            break;
        }
    }

    c.backgroundColor = [UIColor clearColor];
    c.selectionStyle = UITableViewCellSeparatorStyleNone;

    return c;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 35;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 50)];
    v.backgroundColor = [UIColor clearColor];

    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, 90, 40)];
    l.backgroundColor = [UIColor clearColor];
    l.textColor = [UIColor colorWithRed:0.612 green:0.620 blue:0.624 alpha:1];
    l.font = [UIFont regularFontOfSize:12];
    l.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [v addSubview:l];

    switch (section) {
        case 0: {
            l.text = @"GENERAL INFORMATION";
            break;
        }
        case 1: {
            l.text = @"PERFORMANCE REPORTS";
            break;
        }
    }

    return v;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"%d %d", indexPath.section, indexPath.row);
}

@end
