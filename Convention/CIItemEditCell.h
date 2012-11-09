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

@end

@interface CIItemEditCell : UITableViewCell <UITextFieldDelegate>
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *desc;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *lblQuantity;
@property (unsafe_unretained, nonatomic) IBOutlet UITextField *voucher;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *lblPrice;
@property (unsafe_unretained, nonatomic) IBOutlet UITextField *qty;
@property (unsafe_unretained, nonatomic) IBOutlet UITextField *price;
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *btnShipdates;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *total;
@property (nonatomic, assign) id<CIItemEditDelegate> delegate;
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *qtyBtn;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *priceLbl;
- (IBAction)voucherEdit:(id)sender;
- (IBAction)qtyEdit:(id)sender;
- (IBAction)priceEdit:(id)sender;
- (IBAction)qtyTouch:(id)sender;
- (IBAction)shipdates:(id)sender;

@end
