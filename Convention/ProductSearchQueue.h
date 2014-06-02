//
// Created by David Jafari on 5/31/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ProductSearch;
@class CIProductViewController;

@interface ProductSearchQueue : NSObject

- (id)initWithProductController:(CIProductViewController *)productController;
- (void)search:(ProductSearch *)search;

@end