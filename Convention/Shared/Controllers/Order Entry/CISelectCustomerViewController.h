//
//  CISelectCustomerViewController.h
//  Convention
//
//  Created by Matthew Clark on 11/2/11.
//  Copyright (c) 2011 MotionMobs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PullToRefreshView.h"
#import "CISelectRecordViewController.h"

@protocol CICustomerDelegate <NSObject>

- (void)customerSelected:(NSDictionary *)info;

@end

@interface CISelectCustomerViewController : CISelectRecordViewController

@property(nonatomic, assign) id <CICustomerDelegate> delegate;

@end
