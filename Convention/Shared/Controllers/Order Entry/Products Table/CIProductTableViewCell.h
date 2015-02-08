//
// Created by David Jafari on 12/21/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CITableViewCell.h"

@protocol ProductCellDelegate;


@interface CIProductTableViewCell : CITableViewCell

@property LineItem *lineItem;

-(id)prepareForDisplay:(CITableViewColumns *)columns delegate:(id<ProductCellDelegate>)delegate;
-(id)render:(id)rowData lineItem:lineItem;

@end