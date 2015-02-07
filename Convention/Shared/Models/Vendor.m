//
//  Vendor.m
//  Convention
//
//  Created by septerr on 9/9/13.
//  Copyright (c) 2013 Convention Innovations. All rights reserved.
//

#import "Vendor.h"
#import "NilUtil.h"
#import "config.h"

@implementation Vendor

@dynamic groupName;
@dynamic vendorId;
@dynamic email;
@dynamic company;
@dynamic vendid;
@dynamic name;
@dynamic season;
@dynamic hidewsprice;
@dynamic hideshprice;
@dynamic commodity;
@dynamic owner;
@dynamic complete;
@dynamic dlybill;
@dynamic lines;
@dynamic username;
@dynamic vendorgroup_id;
@dynamic initial_show;
@dynamic isle;
@dynamic booth;
@dynamic dept;
@dynamic broker_id;
@dynamic status;

- (id)initWithVendorFromServer:(NSDictionary *)vendorFromServer context:(NSManagedObjectContext *)context {
    self = [super initWithEntity:[NSEntityDescription entityForName:@"Vendor" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
    if (self) {
        self.groupName = (NSString *) vendorFromServer[kVendorGroupName];
        self.vendorId = (NSNumber *) [NilUtil nilOrObject:[vendorFromServer objectForKey:kVendorID]];
        self.email = (NSString *) [NilUtil nilOrObject:[vendorFromServer objectForKey:kVendorEmail]];
        self.company = (NSString *) [NilUtil nilOrObject:[vendorFromServer objectForKey:kVendorCompany]];
        self.vendid = (NSString *) [NilUtil nilOrObject:[vendorFromServer objectForKey:kVendorVendID]];
        self.name = (NSString *) [NilUtil nilOrObject:[vendorFromServer objectForKey:kVendorName]];
        self.season = (NSString *) [NilUtil nilOrObject:[vendorFromServer objectForKey:kVendorSeason]];
        self.hidewsprice = (NSNumber *) [NilUtil nilOrObject:[vendorFromServer objectForKey:kVendorHideWSPrice]];
        self.hideshprice = (NSNumber *) [NilUtil nilOrObject:[vendorFromServer objectForKey:kVendorHideSHPrice]];
        self.commodity = (NSNumber *) [NilUtil nilOrObject:[vendorFromServer objectForKey:kVendorCommodity]];
        self.owner = (NSString *) [NilUtil nilOrObject:[vendorFromServer objectForKey:kVendorOwner]];
        self.complete = (NSNumber *) [NilUtil nilOrObject:[vendorFromServer objectForKey:kVendorComplete]];
        self.dlybill = (NSString *) [NilUtil nilOrObject:[vendorFromServer objectForKey:kVendorDlybill]];
        self.lines = (NSNumber *) [NilUtil nilOrObject:[vendorFromServer objectForKey:kVendorLines]];
        self.username = (NSString *) [NilUtil nilOrObject:[vendorFromServer objectForKey:kVendorUsername]];
        self.vendorgroup_id = (NSNumber *) [NilUtil nilOrObject:[vendorFromServer objectForKey:kVendorVendorGroupId]];
        self.initial_show = (NSNumber *) [NilUtil nilOrObject:[vendorFromServer objectForKey:kVendorInitialShow]];
        self.isle = (NSString *) [NilUtil nilOrObject:[vendorFromServer objectForKey:kVendorIsle]];
        self.booth = (NSString *) [NilUtil nilOrObject:[vendorFromServer objectForKey:kVendorBooth]];
        self.dept = (NSString *) [NilUtil nilOrObject:[vendorFromServer objectForKey:kVendorDept]];
        self.broker_id = (NSNumber *) [NilUtil nilOrObject:[vendorFromServer objectForKey:kVendorBrokerId]];
        self.status = (NSString *) [NilUtil nilOrObject:[vendorFromServer objectForKey:kVendorStatus]];
    }
    return self;
}

- (NSDictionary *)asDictionary {
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    if (self.vendorId)
        [dictionary setObject:self.vendorId forKey:kVendorID];
    if (self.email)
        [dictionary setObject:self.email forKey:kVendorEmail];
    if (self.company)
        [dictionary setObject:self.company forKey:kVendorCompany];
    if (self.vendid)
        [dictionary setObject:self.vendid forKey:kVendorVendID];
    if (self.name)
        [dictionary setObject:self.name forKey:kVendorName];
    if (self.season)
        [dictionary setObject:self.season forKey:kVendorSeason];
    if (self.hidewsprice)
        [dictionary setObject:self.hidewsprice forKey:kVendorHideWSPrice];
    if (self.hideshprice)
        [dictionary setObject:self.hideshprice forKey:kVendorHideSHPrice];
    if (self.commodity)
        [dictionary setObject:self.commodity forKey:kVendorCommodity];
    if (self.owner)
        [dictionary setObject:self.owner forKey:kVendorOwner];
    if (self.complete)
        [dictionary setObject:self.complete forKey:kVendorComplete];
    if (self.dlybill)
        [dictionary setObject:self.dlybill forKey:kVendorDlybill];
    if (self.lines)
        [dictionary setObject:self.lines forKey:kVendorLines];
    if (self.username)
        [dictionary setObject:self.username forKey:kVendorUsername];
    if (self.vendorgroup_id)
        [dictionary setObject:self.vendorgroup_id forKey:kVendorVendorGroupId];
    if (self.initial_show)
        [dictionary setObject:self.initial_show forKey:kVendorInitialShow];
    if (self.isle)
        [dictionary setObject:self.isle forKey:kVendorIsle];
    if (self.booth)
        [dictionary setObject:self.booth forKey:kVendorBooth];
    if (self.dept)
        [dictionary setObject:self.dept forKey:kVendorDept];
    if (self.broker_id)
        [dictionary setObject:self.broker_id forKey:kVendorBrokerId];
    if (self.status)
        [dictionary setObject:self.status forKey:kVendorStatus];
    return dictionary;
}
@end
