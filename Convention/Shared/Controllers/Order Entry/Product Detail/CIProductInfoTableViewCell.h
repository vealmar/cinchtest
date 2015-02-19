//
// Created by David Jafari on 2/12/15.
// Copyright (c) 2015 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Product;
@class LineItem;

@interface CIProductInfoTableViewCell : UITableViewCell

- (void)prepareForDisplay:(LineItem *)line;

@end