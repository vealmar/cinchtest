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
NSArray *storesArray;
@dynamic customer_id;
@dynamic billname;
@dynamic import_id;
@dynamic email;
@dynamic initial_show;
@dynamic stores;
@dynamic custid;

- (id)initWithCustomerFromServer:(NSDictionary *)customerFromServer context:(NSManagedObjectContext *)context {
    self = [super initWithEntity:[NSEntityDescription entityForName:@"Customer" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
    if (self) {
        self.customer_id = (NSNumber *) [NilUtil nilOrObject:[customerFromServer objectForKey:kCustomerId]];
        self.custid = (NSString *) [NilUtil nilOrObject:[customerFromServer objectForKey:kCustomerCustId]];
        self.billname = (NSString *) [NilUtil nilOrObject:[customerFromServer objectForKey:kCustomerBillName]];
        self.import_id = (NSNumber *) [NilUtil nilOrObject:[customerFromServer objectForKey:kCustomerImportId]];
        self.email = (NSString *) [NilUtil nilOrObject:[customerFromServer objectForKey:kCustomerEmail]];
        self.initial_show = (NSNumber *) [NilUtil nilOrObject:[customerFromServer objectForKey:kCustomerInitialShow]];
        storesArray = (NSArray *) [NilUtil nilOrObject:[customerFromServer objectForKey:kCustomerStores]];
        if (storesArray == nil)storesArray = [[NSArray alloc] init];
        self.stores = storesArray ? [storesArray componentsJoinedByString:@","] : nil;
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
    if (self.import_id)
        [dictionary setObject:self.import_id forKey:kCustomerImportId];
    if (self.email)
        [dictionary setObject:self.email forKey:kCustomerEmail];
    if (self.initial_show)
        [dictionary setObject:self.initial_show forKey:kCustomerInitialShow];
    if (storesArray)
        [dictionary setObject:storesArray forKey:kCustomerStores];
    return dictionary;
}

@end
