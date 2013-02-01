//
//  FarrisItemEditCell.h
//  Convention
//
//  Created by Kerry Sanders on 1/21/13.
//  Copyright (c) 2013 MotionMobs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ItemEditDelegate.h"

@interface FarrisItemEditCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *descr1;
@property (weak, nonatomic) IBOutlet UILabel *descr2;
@property (weak, nonatomic) IBOutlet UITextField *qty;
@property (weak, nonatomic) IBOutlet UILabel *price;
@property (weak, nonatomic) IBOutlet UILabel *total;

@property (nonatomic, assign) id<ItemEditDelegate> delegate;

- (IBAction)qtyChanged:(id)sender;

@end
