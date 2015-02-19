//
//  ProductCellDelegate.h
//  Convention
//
//  Created by Kerry Sanders on 1/20/13.
//  Copyright (c) 2013 MotionMobs. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Order;
@class LineItem;

@protocol ProductCellDelegate <NSObject>
@required

// farris product cell
- (void)showPriceChanged:(double)price productId:(NSNumber *)productId lineItem:(LineItem *)lineItem;

// farris product cell
- (void)toggleProductDetail:(NSNumber *)productId lineItem:(LineItem *)lineItem;

- (Order *)currentOrderForCell;

- (BOOL)isLineSelected:(LineItem *)lineItem;

- (void)setEditingMode:(BOOL)isEditing;

@end
