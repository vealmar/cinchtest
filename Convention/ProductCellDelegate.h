//
//  ProductCellDelegate.h
//  Convention
//
//  Created by Kerry Sanders on 1/20/13.
//  Copyright (c) 2013 MotionMobs. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ProductCellDelegate <NSObject>
@required
-(void)VoucherChange:(double)price forIndex:(int)idx;
-(void)PriceChange:(double)price forIndex:(int)idx;
-(void)QtyChange:(double)qty forIndex:(int)idx;
-(void)AddToCartForIndex:(int)idx;
-(void)QtyTouchForIndex:(int)idx;
-(void)setSelectedRow:(NSUInteger)index;

@end
