//
// Created by David Jafari on 12/14/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CINavViewManagerDelegate <NSObject>

- (UINavigationController *)navigationControllerForNavViewManager;
- (UINavigationItem *)navigationItemForNavViewManager;

@optional

- (NSArray *)leftActionItems;
/**
* Construct a set of UIBarButtonItem for the nav bar.
*/
- (NSArray *)rightActionItems;

- (void)navViewDidSearch:(NSString *)searchTerm inputCompleted:(BOOL)inputCompleted;

- (BOOL)navViewWillSearch;

- (void)navViewDidEndSearch;

@end


@interface CINavViewManager : NSObject <UITextFieldDelegate>

@property (nonatomic, weak) id <CINavViewManagerDelegate> delegate;
@property NSAttributedString *title;
@property BOOL inSearchMode;

- (id)init:(BOOL)searchable;

- (void)setupNavBar;

- (void)clearSearch;

@end