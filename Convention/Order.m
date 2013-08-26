//
//  Order.m
//  Convention
//
//  Created by Kerry Sanders on 1/21/13.
//  Copyright (c) 2013 MotionMobs. All rights reserved.
//

#import "Order.h"
#import "AnOrder.h"
#import "config.h"


@implementation Order

@dynamic billname;
@dynamic created_at;
@dynamic multiStore;
@dynamic orderId;
@dynamic status;
@dynamic totalCost;
@dynamic vendor_id;
@dynamic vendorGroup;
@dynamic vendorGroupId;
@dynamic customer_id;
@dynamic custid;
@dynamic carts;

- (id)initWithOrder:(AnOrder *)orderFromServer forCustomer:(NSDictionary *)customer vendorId:(NSNumber *)vendorId vendorGroup:(NSString *)vendorGroup andVendorGroupId:(NSString *)vendorGroupId context:(NSManagedObjectContext *)context {
    self = [super initWithEntity:[NSEntityDescription entityForName:@"Order" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
    if (self) {
        self.billname = [customer objectForKey:kBillName];
        self.customer_id = [orderFromServer.customerId stringValue];
        self.custid = [orderFromServer.customer objectForKey:@"custid"];
        self.multiStore = [[customer objectForKey:kStores] isKindOfClass:[NSArray class]] && [((NSArray *) [customer objectForKey:kStores]) count] > 0;
        self.status = orderFromServer.status;
        self.created_at = [NSDate date]; //the time this core data entry was created. It is later used by ciroderviewcontroller to sort the partial orders.
        self.vendorGroup = vendorGroup;
        self.vendorGroupId = vendorGroupId;
        self.vendor_id = [vendorId intValue];
        self.orderId = [orderFromServer.orderId intValue];
        self.totalCost = [orderFromServer.total doubleValue];
    }
    return self;
}


@end
