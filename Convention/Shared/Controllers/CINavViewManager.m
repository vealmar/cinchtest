//
// Created by David Jafari on 12/14/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <Underscore.m/Underscore.h>
#import "CINavViewManager.h"
#import "ThemeUtil.h"
#import "CIAppDelegate.h"

@interface CINavViewManager()

@property UITextField *searchTextField;

@end

@implementation CINavViewManager

- (void)setupNavBar {
    [self setupNavBar:nil];
}

-(void)setTitle:(NSAttributedString *)title {
    CGRect totalHeightRect = [title boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin context:nil];
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(512.0f - floor(totalHeightRect.size.width / 2.0f), 5.0f, totalHeightRect.size.width, totalHeightRect.size.height)];
    titleLabel.attributedText = title;
    UINavigationItem *navItem = self.delegate.navigationItemForNavViewManager;
    navItem.titleView = titleLabel;
}

-(NSAttributedString *)title {
    UINavigationItem *navItem = self.delegate.navigationItemForNavViewManager;
    return ((UILabel *) navItem.titleView).attributedText;
}

- (void)setupNavBar:(NSString*)searchText {
    UINavigationController *navController = self.delegate.navigationControllerForNavViewManager;
    UINavigationItem *navItem = self.delegate.navigationItemForNavViewManager;

    navController.navigationBar.translucent = NO;
    navController.navigationBar.barTintColor = [ThemeUtil offBlackColor];

    NSString *term = @"Search...";
    if (searchText && searchText.length > 0) {
        term = searchText;
    }

    UIBarButtonItem *searchItem = [[UIBarButtonItem alloc] bk_initWithTitle:[NSString stringWithFormat:@"   %@", term] style:UIBarButtonItemStylePlain handler:^(id sender) {
        [self setupNavBarSearch:searchText];
    }];
    [searchItem setTitleTextAttributes:[ThemeUtil navigationSearchLabelTextAttributes] forState:UIControlStateNormal];

    NSArray *leftBarButtonItems = self.leftBarButtonItems;
    Underscore.array(leftBarButtonItems).each(^(UIBarButtonItem *item) {
        [item setTitleTextAttributes:[ThemeUtil navigationLeftActionButtonTextAttributes] forState:UIControlStateNormal];
    });

    NSArray *rightBarButtonItems = self.rightBarButtonItems;
    Underscore.array(rightBarButtonItems).each(^(UIBarButtonItem *item) {
        [item setTitleTextAttributes:[ThemeUtil navigationRightActionButtonTextAttributes] forState:UIControlStateNormal];
    });

    navItem.leftBarButtonItems = [leftBarButtonItems arrayByAddingObject:searchItem];
    navItem.rightBarButtonItems = rightBarButtonItems;
}

- (void)setupNavBarSearch:(NSString*)searchText {
    UINavigationController *navController = self.delegate.navigationControllerForNavViewManager;
    UINavigationItem *navItem = self.delegate.navigationItemForNavViewManager;

    navItem.titleView = nil;
    [navController.navigationBar setBackgroundImage:nil forBarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
    navController.navigationBar.barTintColor = [UIColor blackColor];

    UITextField *searchTextField = self.searchTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 800, 40)];
    searchTextField.font = [UIFont regularFontOfSize:24];
    searchTextField.textColor = [UIColor whiteColor];
    searchTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Search..." attributes:@{ NSForegroundColorAttributeName: [UIColor colorWithRed:0.600 green:0.600 blue:0.600 alpha:1] }];
    searchTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    searchTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    searchTextField.delegate = self;
    [searchTextField bk_addEventHandler:^(id sender) {
        [self searchWithString:searchTextField.text inputCompleted:NO];
    } forControlEvents:UIControlEventEditingChanged];
    [searchTextField bk_addEventHandler:^(id sender) {
        [self searchWithString:searchTextField.text inputCompleted:YES];
    } forControlEvents:UIControlEventEditingDidEnd];
    if (searchText && searchText.length) {
        searchTextField.text = searchText;
    }

    UIBarButtonItem *searchItem = [[UIBarButtonItem alloc] initWithCustomView:searchTextField];

    UIButton *dismissButton = [UIButton buttonWithType:UIButtonTypeCustom];
    dismissButton.frame = CGRectMake(0.0f, 44.0f, self.delegate.navigationControllerForNavViewManager.view.bounds.size.width, self.delegate.navigationControllerForNavViewManager.view.bounds.size.height - 44.0f);
    dismissButton.backgroundColor = [UIColor clearColor];
    [self.delegate.navigationControllerForNavViewManager.view addSubview:dismissButton];

    void (^exitSearchMode)() = ^() {
        [dismissButton removeFromSuperview];
        [searchTextField resignFirstResponder];
        [self setupNavBar:searchTextField.text];
    };

    [dismissButton bk_addEventHandler:^(id sender) {
        exitSearchMode();
    } forControlEvents:UIControlEventTouchUpInside];

    UIBarButtonItem *clearItem = [[UIBarButtonItem alloc] bk_initWithTitle:@"Clear" style:UIBarButtonItemStylePlain handler:^(id sender) {
        searchTextField.text = @"";
        [self searchWithString:searchTextField.text inputCompleted:YES];
        exitSearchMode();
    }];
    [clearItem setTitleTextAttributes:@{ NSFontAttributeName: [UIFont regularFontOfSize:18],
            NSForegroundColorAttributeName: [UIColor whiteColor] } forState:UIControlStateNormal];

    navItem.leftBarButtonItems = @[searchItem];
    navItem.rightBarButtonItems = @[clearItem];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [searchTextField becomeFirstResponder];
        [self searchWithString:searchTextField.text inputCompleted:NO];
    });
}

-(void)searchWithString:(NSString *)searchTerm inputCompleted:(BOOL)inputCompleted {
    if ([self.delegate respondsToSelector:@selector(navViewDidSearch:inputCompleted:)]) {
        [self.delegate navViewDidSearch:searchTerm inputCompleted:inputCompleted];
    }
}

-(NSArray *)leftBarButtonItems {
    if ([self.delegate respondsToSelector:@selector(leftActionItems)]) {
        return [self.delegate leftActionItems];
    } else {
        CIAppDelegate *appDelegate = (CIAppDelegate *) [UIApplication sharedApplication].delegate;
        UIBarButtonItem *menuItem = [[UIBarButtonItem alloc] bk_initWithTitle:@"\uf0c9" style:UIBarButtonItemStylePlain handler:^(id sender) {
            [appDelegate.slideMenu showLeftMenu:YES];
        }];
        [menuItem setTitleTextAttributes:[ThemeUtil navigationLeftActionButtonTextAttributes] forState:UIControlStateNormal];
        return @[ menuItem ];
    }
}

-(NSArray *)rightBarButtonItems {
    if ([self.delegate respondsToSelector:@selector(rightActionItems)]) {
        return [self.delegate rightActionItems];
    } else {
        return @[ ];
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

@end