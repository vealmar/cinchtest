//
// Created by David Jafari on 12/14/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <Underscore.m/Underscore.h>
#import "CINavViewManager.h"
#import "ThemeUtil.h"
#import "CIAppDelegate.h"
#import "CIBarButton.h"

@interface CINavViewManager()

@property UITextField *searchTextField;
@property BOOL searchable;
@property UIBarButtonItem *clearSearchItem;
@property UILabel *clearSearchItemLabel;
@property UIBarButtonItem *searchItem;
@property UIButton *dismissButton;

@property BOOL inSearchMode;

@end

@implementation CINavViewManager

- (id)init:(BOOL)searchable {
    self = [super init];
    if (self) {
        self.searchable = searchable;
        [self initClearSearchButton];
        [self initSearchTextField];
        [self initDismissButton];
        [self initSearchItem];
        self.inSearchMode = NO;
    }
    return self;
}

- (void)initSearchItem {
    __weak CINavViewManager *weakSelf = self;
    self.searchItem = [[UIBarButtonItem alloc] bk_initWithTitle:@"Search..." style:UIBarButtonItemStylePlain handler:^(id sender) {
        if ([weakSelf allowSearch]) {
            NSString *searchText = nil;
            if (weakSelf && [weakSelf hasSearchText]) {
                searchText = weakSelf.searchItem.title;
            }
            [weakSelf setupNavBarSearch:searchText];
        }
    }];
}

- (void)initDismissButton {
    self.dismissButton = [UIButton buttonWithType: UIButtonTypeCustom];
    self.dismissButton.backgroundColor = [UIColor clearColor];

    __weak CINavViewManager *weakSelf = self;
    [self.dismissButton bk_addEventHandler:^(id sender) {
        [weakSelf exitSearchMode];
    } forControlEvents:UIControlEventTouchUpInside];
}

- (void)initClearSearchButton {
    __weak CINavViewManager *weakSelf = self;

    UILabel *label = self.clearSearchItemLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 22, 44)];
    label.attributedText = [[NSAttributedString alloc] initWithString:@"\uf057" attributes:[ThemeUtil navigationLeftActionButtonTextAttributes]];
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 22, 44)];
    [button addSubview:label];
    [button bk_addEventHandler:^(id sender) {
        weakSelf.searchTextField.text = @"";
        [weakSelf searchWithString:weakSelf.searchTextField.text inputCompleted:YES];
        if (weakSelf.inSearchMode || [weakSelf hasSearchText]) {
            [weakSelf exitSearchMode];
        }
    } forControlEvents:UIControlEventTouchUpInside];
    self.clearSearchItem = [[UIBarButtonItem alloc] initWithCustomView:button];
}

- (void)initSearchTextField {
    self.searchTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 800, 40)];
    self.searchTextField.defaultTextAttributes = [ThemeUtil navigationTitleTextAttributes:22];
    self.searchTextField.textColor = [UIColor whiteColor];
    self.searchTextField.font = [UIFont regularFontOfSize:22];
    self.searchTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Search..." attributes:@{ NSForegroundColorAttributeName: [UIColor colorWithRed:0.600 green:0.600 blue:0.600 alpha:1] }];
    self.searchTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.searchTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.searchTextField.delegate = self;
    [self.searchTextField bk_addEventHandler:^(id sender) {
        [self searchWithString:self.searchTextField.text inputCompleted:NO];
        } forControlEvents:UIControlEventEditingChanged];
    [self.searchTextField bk_addEventHandler:^(id sender) {
        [self searchWithString:self.searchTextField.text inputCompleted:YES];
        } forControlEvents:UIControlEventEditingDidEnd];
}

- (void)setupNavBar {
    [self setupNavBar:nil];
}

- (BOOL)hasSearchText {
    return self.searchItem && ![self.searchItem.title isEqualToString:@"Search..."];
}

-(void)setTitle:(NSAttributedString *)title {
    CGRect totalHeightRect = [title boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin context:nil];
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(
            512.0f - (int)floor(totalHeightRect.size.width / 2.0f),
            5.0f,
            totalHeightRect.size.width,
            totalHeightRect.size.height
    )];
    titleLabel.attributedText = title;
    UINavigationItem *navItem = self.delegate.navigationItemForNavViewManager;
    navItem.titleView = titleLabel;
}

-(NSAttributedString *)title {
    UINavigationItem *navItem = self.delegate.navigationItemForNavViewManager;
    return ((UILabel *) navItem.titleView).attributedText;
}

- (void)setupNavBar:(NSString *)searchText {
    UINavigationController *navController = self.delegate.navigationControllerForNavViewManager;
    UINavigationItem *navItem = self.delegate.navigationItemForNavViewManager;

    navController.navigationBar.translucent = NO;
    navController.navigationBar.barTintColor = [ThemeUtil offBlackColor];

    NSArray *leftBarButtonItems = self.leftBarButtonItems;
    Underscore.array(leftBarButtonItems).each(^(UIBarButtonItem *item) {
        [item setTitleTextAttributes:[ThemeUtil navigationLeftActionButtonTextAttributes] forState:UIControlStateNormal];
    });

    NSArray *rightBarButtonItems = self.rightBarButtonItems;
    Underscore.array(rightBarButtonItems).each(^(UIBarButtonItem *item) {
        [item setTitleTextAttributes:[ThemeUtil navigationRightActionButtonTextAttributes] forState:UIControlStateNormal];
    });

    if (self.searchable) {
        NSString *term = @"Search...";
        if (searchText && searchText.length > 0) {
            //set this again unless we cleared it in the clearSearch method
            self.clearSearchItemLabel.attributedText = [[NSAttributedString alloc] initWithString:@"\uf057" attributes:[ThemeUtil navigationLeftActionButtonTextAttributes]];
            rightBarButtonItems = [rightBarButtonItems arrayByAddingObject:self.clearSearchItem];
            term = searchText;
        }

        self.searchItem.title = term;
        [self.searchItem setTitleTextAttributes:[ThemeUtil navigationSearchLabelTextAttributes] forState:UIControlStateNormal];
        leftBarButtonItems = [leftBarButtonItems arrayByAddingObject:self.searchItem];
    }

    navItem.titleView.hidden = NO;
    navItem.leftBarButtonItems = leftBarButtonItems;
    navItem.rightBarButtonItems = rightBarButtonItems;
    
    self.inSearchMode = NO;
}

- (void)setupNavBarSearch:(NSString*)searchText {
    UINavigationController *navController = self.delegate.navigationControllerForNavViewManager;
    UINavigationItem *navItem = self.delegate.navigationItemForNavViewManager;
    
    navItem.titleView.hidden = YES;
    [navController.navigationBar setBackgroundImage:nil forBarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
    navController.navigationBar.barTintColor = [UIColor blackColor];
    
    if (searchText && searchText.length) {
        self.searchTextField.text = searchText;
    }
    
    UIBarButtonItem *searchItem = [[UIBarButtonItem alloc] initWithCustomView:self.searchTextField];
    
    [self addDismissButtonToViewport];
    
    navItem.leftBarButtonItems = @[searchItem];
    navItem.rightBarButtonItems = @[self.clearSearchItem];
    
    __weak CINavViewManager *weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf.searchTextField becomeFirstResponder];
        [weakSelf searchWithString:weakSelf.searchTextField.text inputCompleted:NO];
    });
    
    self.inSearchMode = YES;
}

- (void)searchWithString:(NSString *)searchTerm inputCompleted:(BOOL)inputCompleted {
    BOOL allowSearch = [self allowSearch];

    if (allowSearch) {
        if ([self.delegate respondsToSelector:@selector(navViewDidSearch:inputCompleted:)]) {
            [self.delegate navViewDidSearch:searchTerm inputCompleted:inputCompleted];
        }
    }
}

- (BOOL)allowSearch {
    BOOL allowSearch = YES;
    if ([self.delegate respondsToSelector:@selector(navViewWillSearch)]) {
        allowSearch = [self.delegate navViewWillSearch];
    }
    return allowSearch;
}

-(void)addDismissButtonToViewport {
    self.dismissButton.frame = CGRectMake(0.0f, 44.0f, self.delegate.navigationControllerForNavViewManager.view.bounds.size.width, self.delegate.navigationControllerForNavViewManager.view.bounds.size.height - 44.0f);
    [self.delegate.navigationControllerForNavViewManager.view addSubview:self.dismissButton];
}

- (void)clearSearch {
    if (self.inSearchMode) {
        NSString *originalSearchQuery = self.searchTextField.text;
        self.searchTextField.text = nil;
        
        if (self.dismissButton) {
            [self.dismissButton removeFromSuperview];
        }
        [self.searchTextField resignFirstResponder];
        [self setupNavBar:self.searchTextField.text];

        if (originalSearchQuery) [self searchWithString:self.searchTextField.text inputCompleted:YES];
        
        [self didEndSearch];
    } else if ([self hasSearchText]) {
        self.clearSearchItemLabel.attributedText = [[NSAttributedString alloc] initWithString:@"" attributes:[ThemeUtil navigationLeftActionButtonTextAttributes]];;
        self.searchItem.title = @"Search...";
    }
}

-(void)exitSearchMode {
    if (self.dismissButton) {
        [self.dismissButton removeFromSuperview];
    }
    [self.searchTextField resignFirstResponder];
    [self setupNavBar:self.searchTextField.text];
    [self didEndSearch];
}

-(void)didEndSearch {
    if ([self.delegate respondsToSelector:@selector(navViewDidEndSearch)]) {
        return [self.delegate navViewDidEndSearch];
    }
}

-(NSArray *)leftBarButtonItems {
    if ([self.delegate respondsToSelector:@selector(leftActionItems)]) {
        return [self.delegate leftActionItems];
    } else {
        CIAppDelegate *appDelegate = (CIAppDelegate *) [UIApplication sharedApplication].delegate;
        UIBarButtonItem *menuItem = [CIBarButton buttonItemWithText:@"\uf0c9" style:CIBarButtonStyleTextButton orientation:CIBarButtonOrientationLeft handler:^(id sender) {
            [appDelegate.slideMenu showLeftMenu:YES];
        }];

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
    [self exitSearchMode];
    return NO;
}

@end