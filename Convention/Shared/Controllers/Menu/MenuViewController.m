//
//  MenuViewController.m
//  Convention
//
//  Created by Bogdan Covaci on 18.11.2014.
//  Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import "MenuViewController.h"
#import "Configurations.h"
#import "CIAppDelegate.h"
#import "FXBlurView.h"
#import "MenuViewCell.h"
#import "CIMenuWebViewController.h"
#import "NotificationConstants.h"
#import "CurrentSession.h"
#import "NilUtil.h"
#import "config.h"
#import "CinchJSONAPIClient.h"
#import "CISelectVendorViewController.h"
#import "LaunchViewController.h"
#import "CISelectShowViewController.h"


@interface MenuViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *logoImageView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet UIView *topContentView;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView;
@property (weak, nonatomic) IBOutlet UIImageView *vendorBackgroundImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;

@property (weak, nonatomic) IBOutlet UIButton *helpButton;
@property (weak, nonatomic) IBOutlet UIButton *logoutButton;
@property (weak, nonatomic) IBOutlet UIButton *relaunchButton;

@property CIMenuWebViewController *menuWebViewController;
@property MenuLink activeMenuLink;

@end

@implementation MenuViewController

- (void)viewDidLoad {
    self.view.backgroundColor = [UIColor colorWithRed:0.235 green:0.247 blue:0.251 alpha:1];
    self.topContentView.backgroundColor = [UIColor clearColor];
    self.logoImageView.image = [Configurations instance].logo;
    self.backgroundImageView.clipsToBounds = YES;
    self.backgroundImageView.image = [[Configurations instance].loginScreen blurredImageWithRadius:2.5f iterations:1 tintColor:[UIColor blackColor]];
    CAGradientLayer *gradientLayerBottom = [CAGradientLayer layer];
    gradientLayerBottom.frame = CGRectMake(
            self.backgroundImageView.bounds.origin.x,
            self.backgroundImageView.bounds.origin.y + self.backgroundImageView.bounds.size.height - 10.0f,
            self.backgroundImageView.bounds.size.width,
            10.0f
    );
    gradientLayerBottom.colors = @[(id) [[UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.15f] CGColor],
            (id) [[UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.5f] CGColor]];
    [self.vendorBackgroundImageView.layer addSublayer:gradientLayerBottom];
    CAGradientLayer *gradientLayerTop = [CAGradientLayer layer];
    gradientLayerTop.frame = CGRectMake(
            self.backgroundImageView.bounds.origin.x,
            self.backgroundImageView.bounds.origin.y,
            self.backgroundImageView.bounds.size.width,
            10.0f
    );
    gradientLayerTop.colors = @[(id) [[UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.35f] CGColor],
            (id) [[UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.05f] CGColor]];
    [self.vendorBackgroundImageView.layer addSublayer:gradientLayerTop];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    [self handleSessionDidChange:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSessionDidChange:) name:SessionDidChangeNotification object:nil];
    [self.helpButton bk_addEventHandler:^(id sender){
        [self navigateTo:MenuLinkHelp];
    } forControlEvents:UIControlEventTouchUpInside];
    [self.logoutButton bk_addEventHandler:^(id sender) {
        [self closeMenu];
        [self logout];
    } forControlEvents:UIControlEventTouchUpInside];
    [self.relaunchButton bk_addEventHandler:^(id sender) {
        [self closeMenu];
        [self logout];
        [self loadLaunchViewController];
    } forControlEvents:UIControlEventTouchUpInside];
    self.activeMenuLink = MenuLinkOrderWriter;
    self.menuWebViewController = [[CIMenuWebViewController alloc] init];
}

- (void)viewWillAppear:(BOOL)animated {
    NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
    if (!selectedIndexPath) {
        [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionTop];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)logout {
    void (^clearSettings)(void) = ^{
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kUsernameSetting];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kPasswordSetting];
        [[NSUserDefaults standardUserDefaults] synchronize];
    };

    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if ([CurrentSession instance].authToken) parameters[kAuthToken] = [CurrentSession instance].authToken;

    [[CinchJSONAPIClient sharedInstance] DELETE:kDBLOGOUT parameters:parameters success:^(NSURLSessionDataTask *task, id JSON) {
        clearSettings();
        [self dismissViewControllerAnimated:YES completion:nil];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        [[[UIAlertView alloc] initWithTitle:@"Error"
                                    message:[NSString stringWithFormat:@"There was an error logging out please try again! Error:%@", [error localizedDescription]]
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];

    }];
}

- (void)loadLaunchViewController {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"LaunchViewController" bundle:nil];
    LaunchViewController *launchViewController = [storyboard instantiateInitialViewController];
    launchViewController.managedObjectContext = [CurrentSession mainQueueContext];
    [[UIApplication sharedApplication].keyWindow.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];//remove window's subviews before loading new rootviewcontroller.
    [[UIApplication sharedApplication].keyWindow setRootViewController:launchViewController];
}

-(void)handleSessionDidChange:(NSNotification *)notification {
    CurrentSession *session = [CurrentSession instance];
    NSShadow *shadow = [NSShadow new];
    shadow.shadowColor = [UIColor blackColor];
    shadow.shadowBlurRadius = 5.0f;
    NSString *vendorName = session.vendorName;
    NSString *showName = session.showTitle;
    self.titleLabel.attributedText = [[NSAttributedString alloc] initWithString:vendorName attributes:@{
            NSFontAttributeName: [UIFont semiboldFontOfSize:20],
            NSForegroundColorAttributeName: [UIColor whiteColor],
            NSShadowAttributeName: shadow,
            NSKernAttributeName: @(-0.5f)
    }];
    self.subtitleLabel.attributedText = [[NSAttributedString alloc] initWithString:showName attributes:@{
            NSFontAttributeName: [UIFont semiboldFontOfSize:16],
            NSForegroundColorAttributeName: [UIColor whiteColor],
            NSShadowAttributeName: shadow,
            NSKernAttributeName: @(-0.75f)
    }];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionTop];
    [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
    [self.tableView reloadData];
}

#pragma mark - tableview
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return [CurrentSession instance].hasAdminAccess ? 3 : 2;
        case 1:
            return [Configurations instance].discountsGuide ? 3 : 2;
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
    MenuLink menuLink = [self menuLinkFromIndexPath:indexPath];
    [cell prepareForDisplay:menuLink];

    if (menuLink == self.activeMenuLink) {
        cell.selected = YES;
    }
        
    return cell;
}

- (MenuLink)menuLinkFromIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0: {
            switch (indexPath.row) {
                case 0: {
                    return MenuLinkOrderWriter;
                }
                case 1: {
                    return MenuLinkChangeShow;
                }
                case 2: {
                    return  MenuLinkChangeVendor;
                }
            }
            break;
        }
        case 1: {
            switch (indexPath.row) {
                case 0: {
                    return MenuLinkProducts;
                }
                case 1: {
                    return MenuLinkCustomers;
                }
                case 2: {
                    return MenuLinkDiscountGuide;
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
                    return MenuLinkReportSalesByProduct;
                }
                case 2: {
                    return MenuLinkReportSalesByCustomer;
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
    if (0 == section) return nil;

    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 50)];
    v.backgroundColor = [UIColor clearColor];

    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, 90, 40)];
    l.backgroundColor = [UIColor clearColor];
    l.textColor = [UIColor colorWithRed:0.612 green:0.620 blue:0.624 alpha:1];
    l.font = [UIFont regularFontOfSize:12];
    l.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [v addSubview:l];

    switch (section) {
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

    if (MenuLinkChangeVendor == menuLink) {
        CISelectVendorViewController *ci = [[CISelectVendorViewController alloc] initWithNibName:@"CICustomerInfoViewController" bundle:nil];
        [self presentViewController:ci animated:YES completion:nil];
    }else if (MenuLinkChangeShow == menuLink) {
        CISelectShowViewController *ci = [[CISelectShowViewController alloc] initWithNibName:@"CICustomerInfoViewController" bundle:nil];
        [self presentViewController:ci animated:YES completion:nil];
    } else {
        NSURL *url = metadata.url;

        if (MenuLinkOrderWriter != menuLink && url) {
            [self.menuWebViewController navigateTo:url titled:metadata.viewTitle];
        }
        if (MenuLinkOrderWriter == menuLink && MenuLinkOrderWriter != self.activeMenuLink) {
            self.menuWebViewController.navigationController.viewControllers = @[self.orderViewController];
        } else if (MenuLinkOrderWriter != menuLink && MenuLinkOrderWriter == self.activeMenuLink) {
            self.orderViewController.navigationController.viewControllers = @[self.menuWebViewController];
        }
        [self closeMenu];
    }

    self.activeMenuLink = menuLink;
}

-(void)closeMenu {
    CIAppDelegate *appDelegate = (CIAppDelegate*)[UIApplication sharedApplication].delegate;
    [appDelegate.slideMenu hideMenu:YES];
}

@end
