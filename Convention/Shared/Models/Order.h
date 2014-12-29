//
// Created by David Jafari on 12/24/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EditableEntity.h"

@class LineItem;


@interface Order : EditableEntity

// in sync with server - this property is manually managed by code updating the order
// should default to false
@property BOOL inSync;

@property NSNumber *orderId;
@property NSNumber *customerId;
@property NSNumber *shippingAddressId;
@property NSNumber *billingAddressId;
@property NSNumber *vendorId;
@property NSNumber *showId;
@property BOOL shipFlag; // contact before shipping?
@property NSString *authorizedBy;
@property NSString *notes;
@property NSString *purchaseOrderNumber;
@property NSArray  *shipDates; // NSArray[NSDate]
@property NSDate *updatedAt;

// Order statuses:
// Partial - Intermediary status when order has been created on the client but
// not yet submitted to the server. Orders should NEVER be submitted in this status.
// Pending - Order has been changed, but not reverified (completed) by the vendor
// or customer.
// Complete - Order has been completed.
// Deleted - Order was deleted on the server. The server archives these records but the
// client should never receive orders in this status.
// Submitted - Order was submitted to the Host for distribution and is locked. The client
// should never receive orders in this status.
@property NSString *status;

// (not implemented by server, here for future)
// Specifies where the order should be emailed if sendEmail is YES,
// this should default to the customer's email address.
@property NSString *email;
// (not implemented by server, here for future)
// Specifies whether this order should be emailed to the customer on
// its next transition to the 'complete' status
@property BOOL sendEmail;

// inlined values from the customer to improve search & rendering speed
@property NSString *custId; // customer's custid (host's id for the customer)
@property NSString *customerName; // customer's billname

// totals are 'lazy calculated' on demand and cached here. These
// attributes should not be read directly, instead get them from calculateTotals.
@property NSNumber *grossTotal;
@property NSNumber *voucherTotal;
@property NSNumber *discountTotal;

@property NSSet *lineItems; //NSSet[LineItem]
@property NSArray *customFields; //NSArray[NSDictionary[kCustomFieldFieldName, kCustomFieldValue]]

@end

@interface Order (CoreDataGeneratedAccessors)

- (void)addLineItemsObject:(LineItem *)value;
- (void)removeLineItemsObject:(LineItem *)value;
- (void)addLineItems:(NSSet *)values;
- (void)removeLineItems:(NSSet *)values;

@end




