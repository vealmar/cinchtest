//
//  VendorViewController.h
//  Convention
//
//  Created by Kerry Sanders on 1/12/13.
//  Copyright (c) 2013 MotionMobs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VendorViewDelegate.h"

@interface VendorViewController : UITableViewController

@property (nonatomic, strong) NSArray *vendors;
@property (nonatomic, strong) NSDictionary *bulletins;
@property (nonatomic, strong) NSString *vendorGroupId;

@property (nonatomic, assign) id<VendorViewDelegate> delegate;

@property (nonatomic, weak) UIPopoverController *parentPopover;

@end
