//
//  CIItemEditCell.h
//  Convention
//
//  Created by Matthew Clark on 12/9/11.
//  Copyright (c) 2011 MotionMobs. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CIItemEditDelegate <NSObject>

-(void)UpdateTotal;
-(void)setViewMovedUpDouble:(BOOL)movedUp;
-(void)setPrice:(NSString*)prc atIndex:(int)idx;
-(void)setQuantity:(NSString*)qty atIndex:(int)idx;
-(void)setVoucher:(NSString*)voucher atIndex:(int)idx;
-(void)QtyTouchForIndex:(int)idx;
-(void)ShipDatesTouchForIndex:(int) idx;
-(void)setActiveField:(UITextField *)textField;

@end

@interface CIItemEditCell : UITableViewCell <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UILabel *desc;
@property (weak, nonatomic) IBOutlet UIButton *btnShipdates;
@property (weak, nonatomic) IBOutlet UITextField *voucher;
@property (weak, nonatomic) IBOutlet UITextField *qty;
@property (weak, nonatomic) IBOutlet UIButton *qtyBtn;
@property (weak, nonatomic) IBOutlet UITextField *price;
@property (weak, nonatomic) IBOutlet UILabel *priceLbl;
@property (weak, nonatomic) IBOutlet UILabel *total;

@property (nonatomic, assign) id<CIItemEditDelegate> delegate;

- (IBAction)voucherEdit:(id)sender;
- (IBAction)qtyEdit:(id)sender;
- (IBAction)priceEdit:(id)sender;
- (IBAction)qtyTouch:(id)sender;
- (IBAction)shipdates:(id)sender;

@end
