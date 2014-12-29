//
// Created by David Jafari on 12/24/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Order.h"

@class LineItem;
@class OrderTotals;
@class OrderSubtotalsByDate;
@class ShowCustomField;

@interface Order (Extensions)

@property (readonly) BOOL isPartial;
@property (readonly) BOOL isPending;
@property (readonly) BOOL isComplete;
@property (readonly) BOOL isSubmitted;
// has this order been changed since the last sync to the server?
@property (readonly) BOOL hasNontransientChanges;

+ (id)newOrderForCustomer:(NSDictionary *)customer;

- (NSString *)getCustomerDisplayName;

/**
* Calculate totals immediately. When requesting for multiple orders, consider
* using the asynchronous version. This version WILL NOT save updated totals.
*/
- (OrderTotals *)calculateTotals;

/**
* Calculates totals asynchronously unless they are already up to date. The resulting
* values will be saved to the store.
*/
- (void)calculateTotals:(void(^)(OrderTotals *totals, NSManagedObjectID *totalledOrderId))completion;

- (OrderSubtotalsByDate *)calculateShipDateSubtotals;

#pragma mark - LineItems

- (NSArray *)productIds;

- (NSArray *)discountLineItemIds;

- (LineItem *)findLineById:(NSNumber *)lineItemId;

- (LineItem *)findLineByProductId:(NSNumber *)productId;

- (LineItem *)findOrCreateLineForProductId:(NSNumber *)productId context:(NSManagedObjectContext *)context;

- (void)updateItemShowPrice:(NSNumber *)price productId:(NSNumber *)productId context:(NSManagedObjectContext *)context;

- (void)removeZeroQuantityLines;

#pragma mark - CustomFields

- (NSString *)customFieldValueFor:(ShowCustomField *)showCustomField;

- (void)setCustomFieldValueFor:(ShowCustomField *)showCustomField value:(NSString *)value;

#pragma mark - Syncing

- (id)initWithJsonFromServer:(NSDictionary *)JSON insertInto:(NSManagedObjectContext *)managedObjectContext;

- (Order *)updateWithJsonFromServer:(NSDictionary *)JSON;

- (NSDictionary *)asJsonReqParameter;

@end