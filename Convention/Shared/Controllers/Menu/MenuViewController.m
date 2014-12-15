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
#import "MenuViewCell.h"
#import "CIMenuWebViewController.h"
#import "NotificationConstants.h"
#import "CurrentSession.h"
#import "NilUtil.h"


@interface MenuViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *logoImageView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet UIView *topContentView;
@property (weak, nonatomic) IBOutlet UIImageView *vendorLogo;
@property (weak, nonatomic) IBOutlet UIImageView *vendorBackgroundImageView;
@property (weak, nonatomic) IBOutlet FXBlurView *blurView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;

@property (weak, nonatomic) IBOutlet UIButton *helpButton;
@property (weak, nonatomic) IBOutlet UIButton *logoutButton;

@property CIMenuWebViewController *menuWebViewController;
@property MenuLink activeMenuLink;

@end

@implementation MenuViewController

- (void)viewDidLoad {
    self.view.backgroundColor = [UIColor colorWithRed:0.235 green:0.247 blue:0.251 alpha:1];

    self.topContentView.backgroundColor = [UIColor clearColor];

    self.logoImageView.backgroundColor = [UIColor colorWithRed:0.161 green:0.169 blue:0.169 alpha:1];
    self.logoImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.logoImageView.image = [NilUtil objectOrDefault:[ShowConfigurations instance].logo defaultObject:[UIImage imageNamed:@"background-brand"]];

    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 5)];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];

    [self updateTitles:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTitles:) name:SessionDidChangeNotification object:nil];

    [self.helpButton bk_addEventHandler:^(id sender){
        [self navigateTo:MenuLinkHelp];
    } forControlEvents:UIControlEventTouchUpInside];

    [self.logoutButton bk_addEventHandler:^(id sender) {
        [self closeMenu];
        [self.orderViewController logout:nil];
    } forControlEvents:UIControlEventTouchUpInside];

    self.activeMenuLink = MenuLinkOrderWriter;
    self.menuWebViewController = [[CIMenuWebViewController alloc] init];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)updateTitles:(NSNotification *)notification {
    CurrentSession *session = [CurrentSession instance];
    NSShadow *shadow = [NSShadow new];
    shadow.shadowColor = [UIColor blackColor];
    shadow.shadowBlurRadius = 5.0f;
    NSString *vendorName = [NilUtil objectOrEmptyString:session.vendorInfo[@"name"]];
    NSString *showName = [NilUtil objectOrEmptyString:session.vendorInfo[@"current_show"][@"title"]];
    self.titleLabel.attributedText = [[NSAttributedString alloc] initWithString:vendorName attributes:@{
            NSFontAttributeName: [UIFont semiboldFontOfSize:18],
            NSForegroundColorAttributeName: [UIColor whiteColor],
            NSShadowAttributeName: shadow,
            NSKernAttributeName: @(-0.5f)
    }];
    self.subtitleLabel.attributedText = [[NSAttributedString alloc] initWithString:showName attributes:@{
            NSFontAttributeName: [UIFont semiboldFontOfSize:14],
            NSForegroundColorAttributeName: [UIColor whiteColor],
            NSShadowAttributeName: shadow,
            NSKernAttributeName: @(-1.0f)
    }];
}

#pragma mark - tableview
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return 1;
        case 1:
            return 2;
        case 2:
            return 3;
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MenuViewCell *cell = (MenuViewCell *)[self.tableView dequeueReusableCellWithIdentifier:@"MenuViewCell"];
    if (nil == cell) {
        cell = [[MenuViewCell alloc] init];
    }
    [cell prepareForDisplay:[self menuLinkFromIndexPath:indexPath]];
    return cell;
}

- (MenuLink)menuLinkFromIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0: {
            return MenuLinkOrderWriter;
        }
        case 1: {
            switch (indexPath.row) {
                case 0: {
                    return MenuLinkProducts;
                }
                case 1: {
                    return MenuLinkCustomers;
                }
            }
            break;
        }
        case 2: {
            switch (indexPath.row) {
                case 0: {
                    return MenuLinkReportSalesByBrand;
                }
                case 1: {
                    return MenuLinkReportSalesByCustomer;
                }
                case 2: {
                    return MenuLinkReportSalesByProduct;
                }
            }
            break;
        }
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (0 == section) {
        return 0;
    } else {
        return 35;
    }
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
            return nil;
        }
        case 1: {
            l.text = @"GENERAL INFORMATION";
            return v;
        }
        case 2: {
            l.text = @"PERFORMANCE REPORTS";
            return v;
        }
    }

    return nil;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"%d %d", indexPath.section, indexPath.row);
    MenuViewCell *cell = (MenuViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    [self navigateTo:cell.menuLink];
}

-(void)navigateTo:(MenuLink)menuLink {
    MenuLinkMetadata *metadata = [[MenuLinkMetadataProvider instance] metadataFor:menuLink];
    NSURL *url = metadata.url;

    if (MenuLinkOrderWriter != menuLink && url) {
        [self.menuWebViewController navigateTo:url titled:metadata.viewTitle];
    }
    if (MenuLinkOrderWriter == menuLink && MenuLinkOrderWriter != self.activeMenuLink) {
        self.menuWebViewController.navigationController.viewControllers = @[self.orderViewController];
    } else if (MenuLinkOrderWriter != menuLink && MenuLinkOrderWriter == self.activeMenuLink) {
        self.orderViewController.navigationController.viewControllers = @[self.menuWebViewController];
    }

    self.activeMenuLink = menuLink;
    [self closeMenu];
}

-(void)closeMenu {
    CIAppDelegate *appDelegate = (CIAppDelegate*)[UIApplication sharedApplication].delegate;
    [appDelegate.slideMenu hideMenu:YES];
}

@end
