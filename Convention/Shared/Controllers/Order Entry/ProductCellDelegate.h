//
//  ProductCellDelegate.h
//  Convention
//
//  Created by Kerry Sanders on 1/20/13.
//  Copyright (c) 2013 MotionMobs. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Order;

@protocol ProductCellDelegate <NSObject>
@required

// farris product cell
- (void)ShowPriceChange:(double)price productId:(NSNumber *)productId;

// farris product cell
- (void)QtyTouchForIndex:(NSNumber *)productId;

- (Order *)currentOrderForCell;

@end
