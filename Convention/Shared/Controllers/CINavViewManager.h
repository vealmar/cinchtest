//
// Created by David Jafari on 12/14/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CINavViewManagerDelegate <NSObject>

- (UINavigationController *)navigationController;
- (UINavigationItem *)navigationItem;

@optional

/**
* Construct a set of UIBarButtonItem for the nav bar.
*/
- (NSArray *)actionItems;
- (void)navViewDidSearch:(NSString *)searchTerm;

@end


@interface CINavViewManager : NSObject

@property (nonatomic, weak) id <CINavViewManagerDelegate> delegate;
@property NSAttributedString *title;

- (void)setupNavBar;

@end