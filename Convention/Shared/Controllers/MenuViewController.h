//
//  MenuViewController.h
//  Convention
//
//  Created by Bogdan Covaci on 18.11.2014.
//  Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CIOrderViewController.h"


@interface MenuViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) CIOrderViewController *orderViewController;

@end
