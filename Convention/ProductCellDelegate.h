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
// deprecated, was part of voucher handling for PWProductCell
- (void)VoucherChange:(double)price forIndex:(int)idx;

// farris product cell
- (void)ShowPriceChange:(double)price forIndex:(int)idx;

// farris product cell
- (void)QtyTouchForIndex:(int)idx;

// CartViewCell, triggered off textFieldShouldBeginEditing
// FarrisProductCell, triggered off textFieldShouldBeginEditing
- (void)setSelectedRow:(NSIndexPath *)index;

@end
