//
//  MyProductCell.h
//  Convention
//
//  Created by Kerry Sanders on 11/17/12.
//  Copyright (c) 2012 MotionMobs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MyProductCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *inventoryId;
@property (weak, nonatomic) IBOutlet UILabel *description;
@property (weak, nonatomic) IBOutlet UILabel *shipDate1;
@property (weak, nonatomic) IBOutlet UILabel *shipDate2;
@property (weak, nonatomic) IBOutlet UILabel *caseQty;
@property (weak, nonatomic) IBOutlet UITextField *quantity;
@property (weak, nonatomic) IBOutlet UILabel *shipDateCount;
@property (weak, nonatomic) IBOutlet UILabel *price;
@property (weak, nonatomic) IBOutlet UILabel *voucher;

@end
