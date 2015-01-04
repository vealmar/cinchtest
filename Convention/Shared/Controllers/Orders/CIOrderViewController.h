//
//  CIOrderViewController.h
//  Convention
//
//  Created by Matthew Clark on 12/8/11.
//  Copyright (c) 2011 MotionMobs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CIProductViewController.h"
#import "PullToRefreshView.h"
#import "CINavViewManager.h"

@interface CIOrderViewController : UIViewController <
        UITableViewDataSource,
        UITableViewDelegate,
        UITextViewDelegate,
        UIAlertViewDelegate,
        CIProductViewDelegate,
        ReachabilityDelegate,
        CICustomerDelegate,
        CINavViewManagerDelegate> {
}

@property(nonatomic, strong) NSString *authToken;
@property(weak, nonatomic) IBOutlet UILabel *NoOrdersLabel;

// Order Detail
@property(weak, nonatomic) IBOutlet UITextView *customer;
@property(weak, nonatomic) IBOutlet UITextView *authorizer;
@property(weak, nonatomic) IBOutlet UITextView *notes;

- (void)logout;

@end
