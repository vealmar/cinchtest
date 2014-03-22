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
- (void)VoucherChange:(double)price forIndex:(int)idx;

- (void)QtyChange:(int)qty forIndex:(int)idx;

- (void)ShowPriceChange:(double)price forIndex:(int)idx;

- (void)QtyTouchForIndex:(int)idx;

- (void)setSelectedRow:(NSIndexPath *)index;

@end
