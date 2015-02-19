//
// Created by David Jafari on 12/24/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EditableEntity.h"

@class Product;
@class Order;

@interface LineItem : EditableEntity

@property NSNumber *lineItemId;
@property NSNumber *orderId;
@property NSNumber *productId;
@property NSNumber *price;
@property NSOrderedSet *shipDates;

// Categories:
// standard - product-based line items
// discount - a generated line item for a discount
@property NSString *category;

// These descriptions will match the product for standard LineItems, but
// will be different for discounts.
@property NSString *description1;
@property NSString *description2;

// When using the 'lineitem' SHIP_DATES_TYPE configuration option, this
// will be a JSON map of the form { shipDate: quantity }. Otherwise, this
// is an integer value.
@property NSString *quantity;

@property Order *order;
@property Product *product;

@property BOOL initializing; // transient

@end