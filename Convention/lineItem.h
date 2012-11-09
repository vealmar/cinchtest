//
//  lineItem.h
//  Convention
//
//  Created by Matthew Clark on 4/18/12.
//  Copyright (c) 2012 MotionMobs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "product.h"

@interface lineItem : NSObject
@property (nonatomic, strong) product* item_product;
@property long product_id;
@property long order_id;
@property float quantity;
@property float price;
@property (nonatomic, strong) NSDate* shipDate;
@property (nonatomic, strong) NSString* shipNotes;
@property BOOL dropShip;

@end
