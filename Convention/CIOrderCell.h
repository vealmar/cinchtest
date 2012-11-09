//
//  CIOrderCell.h
//  Convention
//
//  Created by Matthew Clark on 12/9/11.
//  Copyright (c) 2011 MotionMobs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CIOrderCell : UITableViewCell
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *Customer;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *auth;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *numItems;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *total;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *vouchers;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *lblSC;

@end
