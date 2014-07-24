//
//  DiscountLineItem.h
//  Convention
//
//  Created by septerr on 1/1/14.
//  Copyright (c) 2014 Convention Innovations. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Order, Product;

@interface DiscountLineItem : NSManagedObject

@property(nonatomic, retain) NSNumber *lineItemId;
@property(nonatomic, retain) NSNumber *price;
@property(nonatomic, retain) NSNumber *productId;
@property(nonatomic, retain) NSNumber *quantity;
@property(nonatomic, retain) NSNumber *voucherPrice;
@property(nonatomic, retain) NSString *description1;
@property(nonatomic, retain) NSString *description2;
@property(nonatomic, retain) Order *order;
@property(nonatomic, retain) Product *product;

@end
