//
//  CIItemEditCell.h
//  Convention
//
//  Created by Matthew Clark on 12/9/11.
//  Copyright (c) 2011 MotionMobs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ItemEditDelegate.h"

@class ALineItem;

@interface CIItemEditCell : UITableViewCell <UITextFieldDelegate>
@property(weak, nonatomic) IBOutlet UILabel *invtid;
@property(weak, nonatomic) IBOutlet UILabel *desc;
@property(weak, nonatomic) IBOutlet UILabel *desc1;
@property(weak, nonatomic) IBOutlet UILabel *desc2;
@property(weak, nonatomic) IBOutlet UILabel *shipDatesLabel;
@property(weak, nonatomic) IBOutlet UITextField *voucher;
@property(weak, nonatomic) IBOutlet UITextField *qty;
@property(weak, nonatomic) IBOutlet UILabel *qtyLbl;
@property(weak, nonatomic) IBOutlet UIButton *qtyBtn;
@property(weak, nonatomic) IBOutlet UITextField *price;
@property(weak, nonatomic) IBOutlet UILabel *priceLbl;
@property(weak, nonatomic) IBOutlet UILabel *total;
@property(weak, nonatomic) IBOutlet UITextView *errorMessageView;
@property(weak, nonatomic) IBOutlet NSLayoutConstraint *errorMessageHeightConstraint;

@property(nonatomic, assign) id <ItemEditDelegate> delegate;

- (IBAction)voucherEdit:(id)sender;

- (IBAction)qtyEdit:(id)sender;

- (IBAction)priceEdit:(id)sender;

- (IBAction)qtyTouch:(id)sender;

- (void)showLineItem:(ALineItem *)data withTag:(NSInteger *)tag;

@end
