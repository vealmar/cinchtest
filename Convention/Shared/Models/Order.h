//
//  Order.h
//  Convention
//
//  Created by septerr on 2/5/14.
//  Copyright (c) 2014 Convention Innovations. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "EditableEntity.h"

@class Cart, DiscountLineItem;

@interface Order : EditableEntity

@property(nonatomic, retain) NSString *authorized;
@property(nonatomic, retain) NSString *billname;
@property(nonatomic, retain) NSNumber *cancelByDays;
@property(nonatomic, retain) NSDate *created_at;
@property(nonatomic, retain) NSString *custid;
@property(nonatomic, retain) NSString *customer_id;
@property(nonatomic, retain) NSString *notes;
@property(nonatomic, retain) NSNumber *orderId;
@property(nonatomic, retain) NSString *payment_terms;
@property(nonatomic, retain) NSString *po_number;
@property(nonatomic, retain) NSNumber *print;
@property(nonatomic, retain) NSNumber *printer;
@property(nonatomic, retain) NSArray *ship_dates; //NSArray[NSDate]
@property(nonatomic, retain) NSNumber *ship_flag;
@property(nonatomic, retain) NSString *ship_notes;
@property(nonatomic, retain) NSString *status;
@property(nonatomic, retain) NSString *vendorGroup;
@property(nonatomic, retain) NSString *vendorGroupId;
@property(nonatomic, retain) NSSet *carts;
@property(nonatomic, retain) NSSet *discountLineItems;
@property(nonatomic, retain) NSArray *customFields; //NSArray[NSDictionary[kCustomFieldFieldName, kCustomFieldValue]]

@end

@interface Order (CoreDataGeneratedAccessors)

- (void)addCartsObject:(Cart *)value;
- (void)removeCartsObject:(Cart *)value;
- (void)addCarts:(NSSet *)values;
- (void)removeCarts:(NSSet *)values;

- (void)addDiscountLineItemsObject:(DiscountLineItem *)value;
- (void)removeDiscountLineItemsObject:(DiscountLineItem *)value;
- (void)addDiscountLineItems:(NSSet *)values;
- (void)removeDiscountLineItems:(NSSet *)values;

@end
