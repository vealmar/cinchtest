//
// Created by David Jafari on 6/29/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OrderCustomFieldView.h"
#import "OrderShipDateViewController.h"

@class ShowCustomField;


@interface DateOrderCustomFieldView : UIView<OrderCustomFieldView, OrderShipDateViewControllerDelegate, UITextFieldDelegate>

@property(strong, nonatomic) ShowCustomField *showCustomField;

-(id)init:(ShowCustomField *)showCustomField at:(CGPoint)cgPoint withElementWidth:(CGFloat)elementWidth;

@end