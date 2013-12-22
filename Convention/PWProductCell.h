//
//  PWProductCell.h
//  Convention
//
//  Created by Matthew Clark on 11/2/11.
//  Copyright (c) 2011 MotionMobs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JSONKit.h"
#import "ProductCellDelegate.h"
#import "ProductCell.h"

@class Cart;


@interface PWProductCell : ProductCell

@property(unsafe_unretained, nonatomic) IBOutlet UILabel *numShipDates;
@property(unsafe_unretained, nonatomic) IBOutlet UITextField *quantity;
@property(unsafe_unretained, nonatomic) IBOutlet UILabel *qtyLbl;
@property(unsafe_unretained, nonatomic) IBOutlet UILabel *voucherLbl;
@property(unsafe_unretained, nonatomic) IBOutlet UILabel *priceLbl;
@property(unsafe_unretained, nonatomic) IBOutlet UILabel *descr;
@property(unsafe_unretained, nonatomic) IBOutlet UILabel *shipDate1;
@property(unsafe_unretained, nonatomic) IBOutlet UILabel *shipDate2;
@property(unsafe_unretained, nonatomic) IBOutlet UILabel *CaseQty;
@property(unsafe_unretained, nonatomic) IBOutlet UIButton *qtyBtn;

@property(nonatomic, assign) id <ProductCellDelegate> delegate;

- (IBAction)qtyTouch:(id)sender;

- (IBAction)qtyChanged:(id)sender;

- (void)initializeWith:(NSDictionary *)customer multiStore:(BOOL)multiStore product:(NSDictionary *)product cart:(Cart *)cart checkmarked:(BOOL)checkmarked tag:(NSInteger)tag productCellDelegate:(id <ProductCellDelegate>)productCellDelegate;

@end
