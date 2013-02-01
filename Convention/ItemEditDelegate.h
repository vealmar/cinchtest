//
//  ItemEditDelegate.h
//  Convention
//
//  Created by Kerry Sanders on 1/21/13.
//  Copyright (c) 2013 MotionMobs. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ItemEditDelegate <NSObject>

-(void)UpdateTotal;
-(void)setViewMovedUpDouble:(BOOL)movedUp;
-(void)setPrice:(NSString*)prc atIndex:(int)idx;
-(void)setQuantity:(NSString*)qty atIndex:(int)idx;
-(void)setVoucher:(NSString*)voucher atIndex:(int)idx;
-(void)QtyTouchForIndex:(int)idx;
-(void)ShipDatesTouchForIndex:(int) idx;
-(void)setActiveField:(UITextField *)textField;

@end
