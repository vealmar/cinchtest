//
//  CIProductCell.h
//  Convention
//
//  Created by Matthew Clark on 11/2/11.
//  Copyright (c) 2011 MotionMobs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JSONKit.h"
#import "ProductCellDelegate.h"

//@protocol CIProductCellDelegate <NSObject>
//@required
//-(void)VoucherChange:(double)price forIndex:(int)idx;
//-(void)PriceChange:(double)price forIndex:(int)idx;
//-(void)QtyChange:(double)qty forIndex:(int)idx;
//-(void)AddToCartForIndex:(int)idx;
////-(void)textEditBeginWithFrame:(CGRect)frame;
////-(void)textEditEndWithFrame:(CGRect)frame;
//-(void)QtyTouchForIndex:(int)idx;
//
//@end

@interface CIProductCell : UITableViewCell <UITextFieldDelegate>

@property (unsafe_unretained, nonatomic) IBOutlet UILabel *numShipDates;
@property (unsafe_unretained, nonatomic) IBOutlet UITextField *quantity;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *qtyLbl;
@property (unsafe_unretained, nonatomic) IBOutlet UITextField *price;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *voucherLbl;
@property (unsafe_unretained, nonatomic) IBOutlet UITextField *voucher;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *priceLbl;
//@property (unsafe_unretained, nonatomic) IBOutlet UILabel *ridx;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *InvtID;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *descr;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *shipDate1;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *shipDate2;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *CaseQty;
//@property (unsafe_unretained, nonatomic) IBOutlet UILabel *DirShip;
//@property (unsafe_unretained, nonatomic) IBOutlet UILabel *LineNbr;
//@property (unsafe_unretained, nonatomic) IBOutlet UILabel *New;
//@property (unsafe_unretained, nonatomic) IBOutlet UILabel *Adv;
//@property (unsafe_unretained, nonatomic) IBOutlet UIButton *cartBtn;
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *qtyBtn;
//@property (weak, nonatomic) IBOutlet UILabel *hyphenBetweenShipDates;

@property (nonatomic, assign) id<ProductCellDelegate> delegate;

- (IBAction)priceDidEnd:(id)sender;
- (IBAction)priceDidChange:(id)sender;

- (IBAction)voucherDidEnd:(id)sender;
- (IBAction)voucherDidChange:(id)sender;

- (IBAction)qtyDidEnd:(id)sender;
- (IBAction)addToCart:(id)sender;
- (IBAction)qtyTouch:(id)sender;
- (IBAction)qtyChanged:(id)sender;

@end
