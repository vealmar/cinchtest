//
// Created by David Jafari on 12/14/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <Underscore.m/Underscore.h>
#import "CINavViewManager.h"
#import "ThemeUtil.h"
#import "CIAppDelegate.h"

@implementation CINavViewManager

- (void)setupNavBar {
    [self setupNavBar:nil];
}

-(void)setTitle:(NSAttributedString *)title {
    CGRect totalHeightRect = [title boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin context:nil];
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(512.0f - floor(totalHeightRect.size.width / 2.0f), 5.0f, totalHeightRect.size.width, totalHeightRect.size.height)];
    titleLabel.attributedText = title;
    UINavigationItem *navItem = self.delegate.navigationItem;
    navItem.titleView = titleLabel;
}

-(NSAttributedString *)title {
    UINavigationItem *navItem = self.delegate.navigationItem;
    return ((UILabel *) navItem.titleView).attributedText;
}

- (void)setupNavBar:(NSString*)searchText {
    UINavigationController *navController = self.delegate.navigationController;
    UINavigationItem *navItem = self.delegate.navigationItem;

    navController.navigationBar.translucent = NO;
    navController.navigationBar.barTintColor = [ThemeUtil offBlackColor];

    CIAppDelegate *appDelegate = (CIAppDelegate *) [UIApplication sharedApplication].delegate;
    UIBarButtonItem *menuItem = [[UIBarButtonItem alloc] bk_initWithTitle:@"\uf0c9" style:UIBarButtonItemStylePlain handler:^(id sender) {
        [appDelegate.slideMenu showLeftMenu:YES];
    }];
    [menuItem setTitleTextAttributes:[ThemeUtil navigationLeftActionButtonTextAttributes] forState:UIControlStateNormal];

    NSString *term = @"Search...";
    if (searchText && searchText.length) {
        term = searchText;
    }

    UIBarButtonItem *searchItem = [[UIBarButtonItem alloc] bk_initWithTitle:[NSString stringWithFormat:@"   %@", term] style:UIBarButtonItemStylePlain handler:^(id sender) {
        [self setupNavBarSearch:searchText];
    }];
    [searchItem setTitleTextAttributes:[ThemeUtil navigationSearchLabelTextAttributes] forState:UIControlStateNormal];


    NSArray *actionItems = self.constructActionItems;
    Underscore.array(actionItems).each(^(UIBarButtonItem *item) {
        [item setTitleTextAttributes:[ThemeUtil navigationRightActionButtonTextAttributes] forState:UIControlStateNormal];
    });

    navItem.leftBarButtonItems = @[menuItem, searchItem];
    navItem.rightBarButtonItems = actionItems;
}

- (void)setupNavBarSearch:(NSString*)searchText {
    UINavigationController *navController = self.delegate.navigationController;
    UINavigationItem *navItem = self.delegate.navigationItem;

    navItem.titleView = nil;
    [navController.navigationBar setBackgroundImage:nil forBarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
    navController.navigationBar.barTintColor = [UIColor blackColor];

    UITextField *searchTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 800, 40)];
    searchTextField.font = [UIFont regularFontOfSize:24];
    searchTextField.textColor = [UIColor whiteColor];
    searchTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Search..."
                                                                            attributes:@{ NSForegroundColorAttributeName: [UIColor colorWithRed:0.600 green:0.600 blue:0.600 alpha:1] }];
    [searchTextField bk_addEventHandler:^(id sender) {
        [self searchWithString:searchTextField.text];
    } forControlEvents:UIControlEventEditingChanged];

    if (searchText && searchText.length) {
        searchTextField.text = searchText;
    }

    UIBarButtonItem *searchItem = [[UIBarButtonItem alloc] initWithCustomView:searchTextField];

    UIButton *dismissButton = [UIButton buttonWithType:UIButtonTypeCustom];
    dismissButton.frame = self.delegate.navigationController.view.bounds;
    dismissButton.backgroundColor = [UIColor clearColor];
    [self.delegate.navigationController.view addSubview:dismissButton];

    void (^exitSearchMode)() = ^() {
        [dismissButton removeFromSuperview];
        [searchTextField resignFirstResponder];
        [self setupNavBar:searchTextField.text];
    };

    [dismissButton bk_addEventHandler:^(id sender) {
        exitSearchMode();
    } forControlEvents:UIControlEventTouchUpInside];

    UIBarButtonItem *clearItem = [[UIBarButtonItem alloc] bk_initWithTitle:@"Clear" style:UIBarButtonItemStylePlain handler:^(id sender) {
        searchTextField.text = nil;
        [self searchWithString:searchTextField.text];

        exitSearchMode();
    }];
    [clearItem setTitleTextAttributes:@{ NSFontAttributeName: [UIFont regularFontOfSize:18],
            NSForegroundColorAttributeName: [UIColor whiteColor] } forState:UIControlStateNormal];

    navItem.leftBarButtonItems = @[searchItem];
    navItem.rightBarButtonItems = @[clearItem];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [searchTextField becomeFirstResponder];
        [self searchWithString:searchTextField.text];
    });
}

-(void)searchWithString:(NSString *)searchTerm {
    if ([self.delegate respondsToSelector:@selector(navViewDidSearch:)]) {
        [self.delegate navViewDidSearch:searchTerm];
    }
}

-(NSArray *)constructActionItems {
    if ([self.delegate respondsToSelector:@selector(actionItems)]) {
        return [self.delegate actionItems];
    } else {
        return @[ ];
    }
}

@end