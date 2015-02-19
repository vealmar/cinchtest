//
// Created by David Jafari on 2/15/15.
// Copyright (c) 2015 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Order;


@interface CIOrderTotalTableViewCell : UITableViewCell

-(void)prepareForDisplay:(NSArray *)selectedLines;

@end