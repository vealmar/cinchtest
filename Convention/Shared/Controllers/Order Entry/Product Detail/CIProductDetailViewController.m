//
// Created by David Jafari on 2/13/15.
// Copyright (c) 2015 Urban Coding. All rights reserved.
//

#import "CIProductDetailViewController.h"
#import "Order.h"
#import "LineItem.h"
#import "CIProductDetailTableViewController.h"
#import "ThemeUtil.h"
#import "CISlidingProductDetailViewController.h"
#import "CIProductViewController.h"
#import "CIButton.h"
#import "View+MASAdditions.h"
#import "CIKeyboardUtil.h"

@interface CIProductDetailViewController()

@property NSLayoutConstraint *keyboardHeightFooter;
@property UIView *titleView;
@property CIProductDetailTableViewController *tableViewController;
@property UIView *actionsView;
@property UIButton *saveButton;
@property UIButton *cancelButton;
@property UIButton *removeButton;

@end

@implementation CIProductDetailViewController

- (id)init {
    self = [super init];
    if (self) {
        self.view.frame = CGRectMake(0,0,400,768);
        self.view.backgroundColor = [UIColor colorWithWhite:1.0F alpha:0.92F];

        [self initializeTitleView];
        [self initializeTableViewController];
        [self initializeActionsView];

        [self.titleView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.view.mas_top);
            make.width.equalTo(self.view.mas_width);
            make.left.equalTo(self.view.mas_left);
            make.height.mas_equalTo(44.0F + 44.0F);
        }];

        [self.tableViewController.view mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.titleView.mas_bottom);
            make.width.equalTo(self.view.mas_width);
            make.left.equalTo(self.view.mas_left);
            make.right.equalTo(self.view.mas_right);
        }];
        self.keyboardHeightFooter = [NSLayoutConstraint constraintWithItem:self.tableViewController.view
                                                                 attribute:NSLayoutAttributeBottom
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.actionsView
                                                                 attribute:NSLayoutAttributeTop
                                                                multiplier:1
                                                                  constant:0];

        [self.actionsView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.tableViewController.view.mas_bottom);
            make.bottom.equalTo(self.view.mas_bottom);
            make.width.equalTo(self.view.mas_width);
            make.height.mas_equalTo(50.0F);
        }];
    }
    return self;
}

#pragma mark - Lifecycle

- (void)viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardWillHideNotification object:nil];
    [super viewWillAppear:animated];
    [self.view setNeedsUpdateConstraints];
}

- (void)viewDidDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [super viewDidDisappear:animated];
}

- (void)keyboardWillShow:(NSNotification *)note {
    [CIKeyboardUtil keyboardWillShow:note adjustConstraint:self.keyboardHeightFooter in:self.view];
}

- (void)keyboardDidHide:(NSNotification *)note {
    [CIKeyboardUtil keyboardWillHide:note adjustConstraint:self.keyboardHeightFooter in:self.view];
}


#pragma mark - Public

- (void)prepareForDisplay:(Order *)order lineItem:(LineItem *)lineItem {
    [self.tableViewController prepareForDisplay:order lineItem:lineItem];
}

#pragma mark - Initialization

- (UIView *)initializeTitleView {
    UIView *titleView = [[UIView alloc] init];
    titleView.backgroundColor = [ThemeUtil themeBackgroundColor];
    [self.view addSubview:titleView];
    self.titleView = titleView;

    UIImageView *iconView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 10.0F, 70, 70)];
    iconView.contentMode = UIViewContentModeCenter;
    iconView.image = [UIImage imageNamed:@"ico-cell-header-icon"];
    [titleView addSubview:iconView];

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.font = [UIFont semiboldFontOfSize:26];
    titleLabel.textAlignment = NSTextAlignmentRight;
    titleLabel.textColor = [UIColor orangeColor];
    titleLabel.text = @"Edit Line Item";
    [titleView addSubview:titleLabel];
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(titleView.mas_centerY);
        make.right.equalTo(@-10);
    }];

    return titleView;
}

- (CIProductDetailTableViewController *)initializeTableViewController {
    CIProductDetailTableViewController *tableViewController = [[CIProductDetailTableViewController alloc] init];
    self.tableViewController = tableViewController;
    [self addChildViewController:tableViewController];
    [self.view addSubview:tableViewController.view];
    tableViewController.view.frame = CGRectMake(0.0, 35.0F, self.view.frame.size.width, 768.0F - 35.0F - 50.0F);

    return tableViewController;
}

- (UIView *)initializeActionsView {
    UIView *actionsView = [[UIView alloc] init];
    actionsView.backgroundColor = [ThemeUtil grayBackgroundColor];
    [self.view addSubview:actionsView];
    self.actionsView = actionsView;

    self.saveButton = [[CIButton alloc] initWithOrigin:CGPointMake(self.view.frame.size.width - 100.0F - CIBUTTON_MARGIN, 5.0F)
                                                 title:@"Save"
                                                  size:CIButtonSizeLarge
                                                 style:CIButtonStyleCreate];
    [actionsView addSubview:self.saveButton];

    [self.saveButton bk_whenTapped:^{
        [self.presenterDelegate close];
    }];

//    self.cancelButton = [[CIButton alloc] initWithOrigin:CGPointMake(self.view.frame.size.width - 200.0F - (2 * CIBUTTON_MARGIN), 5.0F)
//                                                 title:@"Cancel"
//                                                  size:CIButtonSizeLarge
//                                                 style:CIButtonStyleCancel];
//    self.removeButton = [[CIButton alloc] initWithOrigin:CGPointMake(CIBUTTON_MARGIN, 5.0F)
//                                                 title:@"Delete"
//                                                  size:CIButtonSizeLarge
//                                                 style:CIButtonStyleDestroy];
//    [actionsView addSubview:self.cancelButton];
//    [actionsView addSubview:self.removeButton];


    return actionsView;
}

@end