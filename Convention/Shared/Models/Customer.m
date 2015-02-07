//
//  Customer.m
//  Convention
//
//  Created by septerr on 9/6/13.
//  Copyright (c) 2013 Convention Innovations. All rights reserved.
//

#import "Customer.h"
#import "NilUtil.h"
#import "config.h"


@implementation Customer

@dynamic customer_id;
@dynamic billname;
@dynamic email;
@dynamic custid;
@dynamic defaultShippingAddressSummary;

- (id)initWithCustomerFromServer:(NSDictionary *)customerFromServer context:(NSManagedObjectContext *)context {
    self = [super initWithEntity:[NSEntityDescription entityForName:@"Customer" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
    if (self) {
        self.customer_id = (NSNumber *) [NilUtil nilOrObject:[customerFromServer objectForKey:kCustomerId]];
        self.custid = (NSString *) [NilUtil nilOrObject:[customerFromServer objectForKey:kCustomerCustId]];
        self.billname = (NSString *) [NilUtil nilOrObject:[customerFromServer objectForKey:kCustomerBillName]];
        self.email = (NSString *) [NilUtil nilOrObject:[customerFromServer objectForKey:kCustomerEmail]];
        self.defaultShippingAddressSummary = (NSString *) [NilUtil nilOrObject:customerFromServer[kCustomerDefaultShippingAddressSummary]];
    }
    return self;
}

- (NSDictionary *)asDictionary {
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    if (self.customer_id)
        [dictionary setObject:self.customer_id forKey:kCustomerId];
    if (self.custid)
        [dictionary setObject:self.custid forKey:kCustomerCustId];
    if (self.billname)
        [dictionary setObject:self.billname forKey:kCustomerBillName];
    if (self.email)
        [dictionary setObject:self.email forKey:kCustomerEmail];
    return dictionary;
}

@end
