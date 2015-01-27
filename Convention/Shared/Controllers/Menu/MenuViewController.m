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
#import "config.h"
#import "CinchJSONAPIClient.h"


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

@property CIMenuWebViewController *menuWebViewController;
@property MenuLink activeMenuLink;

@end

@implementation MenuViewController

- (void)viewDidLoad {
    self.view.backgroundColor = [UIColor colorWithRed:0.235 green:0.247 blue:0.251 alpha:1];

    self.topContentView.backgroundColor = [UIColor clearColor];

    self.logoImageView.image = [ShowConfigurations instance].logo;
    self.vendorBackgroundImageView.clipsToBounds = YES;
    self.vendorBackgroundImageView.contentMode = UIViewContentModeTopLeft;
    CGImageRef imageRef = CGImageCreateWithImageInRect([[ShowConfigurations instance].loginScreen CGImage], CGRectMake(0, 0, self.vendorBackgroundImageView.frame.size.width, self.vendorBackgroundImageView.frame.size.height));
    UIImage *croppedLoginImage = [UIImage imageWithCGImage:imageRef];
    self.vendorBackgroundImageView.image = [croppedLoginImage blurredImageWithRadius:2.5f iterations:1 tintColor:[UIColor blackColor]];
    CGImageRelease(imageRef);

    CAGradientLayer *gradientLayerBottom = [CAGradientLayer layer];
    gradientLayerBottom.frame = CGRectMake(
            self.vendorBackgroundImageView.bounds.origin.x,
            self.vendorBackgroundImageView.bounds.origin.y + self.vendorBackgroundImageView.bounds.size.height - 10.0f,
            self.vendorBackgroundImageView.bounds.size.width,
            10.0f
    );
    gradientLayerBottom.colors = [NSArray arrayWithObjects:
            (id) [[UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.1f] CGColor],
            (id) [[UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.7f] CGColor], nil];
    [self.vendorBackgroundImageView.layer addSublayer:gradientLayerBottom];

    CAGradientLayer *gradientLayerTop = [CAGradientLayer layer];
    gradientLayerTop.frame = CGRectMake(
            self.vendorBackgroundImageView.bounds.origin.x,
            self.vendorBackgroundImageView.bounds.origin.y,
            self.vendorBackgroundImageView.bounds.size.width,
            10.0f
    );
    gradientLayerTop.colors = [NSArray arrayWithObjects:
            (id) [[UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.7f] CGColor],
            (id) [[UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.1f] CGColor], nil];
    [self.vendorBackgroundImageView.layer addSublayer:gradientLayerTop];

    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];

    [self updateTitles:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTitles:) name:SessionDidChangeNotification object:nil];

    [self.helpButton bk_addEventHandler:^(id sender){
        [self navigateTo:MenuLinkHelp];
    } forControlEvents:UIControlEventTouchUpInside];

    [self.logoutButton bk_addEventHandler:^(id sender) {
        [self closeMenu];
        [self logout];
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
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kSettingsUsernameKey];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kSettingsPasswordKey];
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

-(void)updateTitles:(NSNotification *)notification {
    CurrentSession *session = [CurrentSession instance];
    NSShadow *shadow = [NSShadow new];
    shadow.shadowColor = [UIColor blackColor];
    shadow.shadowBlurRadius = 5.0f;
    NSString *vendorName = [NilUtil objectOrEmptyString:session.vendorInfo[@"name"]];
    NSString *showName = [NilUtil objectOrEmptyString:session.vendorInfo[@"current_show"][@"title"]];
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
            return [ShowConfigurations instance].discountsGuide ? 3 : 2;
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
