//
//  CIOrderCell.h
//  Convention
//
//  Created by Matthew Clark on 12/9/11.
//  Copyright (c) 2011 MotionMobs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CIOrderCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *Customer;
@property (weak, nonatomic) IBOutlet UILabel *auth;
@property (weak, nonatomic) IBOutlet UILabel *numItems;
@property (weak, nonatomic) IBOutlet UILabel *total;
@property (weak, nonatomic) IBOutlet UILabel *vouchers;
@property (weak, nonatomic) IBOutlet UILabel *orderStatus;
@property (weak, nonatomic) IBOutlet UILabel *orderId;
@property (weak, nonatomic) IBOutlet UILabel *vouchersLabel;

@end
