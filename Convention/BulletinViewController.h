//
//  BulletinViewController.h
//  Convention
//
//  Created by Kerry Sanders on 1/13/13.
//  Copyright (c) 2013 MotionMobs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VendorViewDelegate.h"

@interface BulletinViewController : UITableViewController

@property (nonatomic) NSInteger currentVendId;
@property (nonatomic, strong) NSDictionary *bulletins;
@property (nonatomic, assign) id<VendorViewDelegate> delegate;

@end
