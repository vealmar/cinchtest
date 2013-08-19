//
//  FarrisProductCell.h
//  Convention
//
//  Created by Kerry Sanders on 1/20/13.
//  Copyright (c) 2013 MotionMobs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ProductCellDelegate.h"
#import "ProductCell.h"

@interface FarrisProductCell : ProductCell

@property (weak, nonatomic) IBOutlet UILabel *itemNumber;
@property (weak, nonatomic) IBOutlet UILabel *descr1;
@property (weak, nonatomic) IBOutlet UILabel *descr2;
@property (weak, nonatomic) IBOutlet UILabel *min;
@property (weak, nonatomic) IBOutlet UITextField *quantity;
@property (weak, nonatomic) IBOutlet UILabel *regPrice;
@property (weak, nonatomic) IBOutlet UILabel *showPrice;
@property (weak, nonatomic) IBOutlet UILabel *qtyLbl;
@property (weak, nonatomic) IBOutlet UILabel *descr;

- (IBAction)quantityChanged:(id)sender;
- (IBAction)quantyEditDidEnd:(id)sender;

@property (nonatomic, assign) id<ProductCellDelegate> delegate;
-(void)setDescription:(NSString *)description1 withSubtext:(NSString *)description2;
- (void) initializeWith:(NSDictionary *)product item:(NSDictionary *)item tag:(NSInteger) tag ProductCellDelegate:(id <ProductCellDelegate>)productCellDelegate;

@end
