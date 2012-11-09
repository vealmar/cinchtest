//
//  CIStoreQtyCell.h
//  Convention
//
//  Created by Matthew Clark on 8/16/12.
//  Copyright (c) 2012 MotionMobs. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol CIStoreQtyDelegate <NSObject>
@required
-(void)QtyChange:(double)qty forIndex:(int)idx;
@end


@interface CIStoreQtyCell : UITableViewCell<UITextFieldDelegate>
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *Key;
@property (unsafe_unretained, nonatomic) IBOutlet UITextField *Qty;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *lblQty;

- (IBAction)qtyChanged:(id)sender;
@property (nonatomic, assign) id<CIStoreQtyDelegate> delegate;
@end
