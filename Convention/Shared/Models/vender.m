//
//  vender.m
//  Convention
//
//  Created by Matthew Clark on 4/18/12.
//  Copyright (c) 2012 MotionMobs. All rights reserved.
//

#import "vender.h"
#import "config.h"

@implementation vender

@synthesize commodity;
@synthesize company;
@synthesize complete;
@synthesize created_at;
@synthesize dlybill;
@synthesize email;
@synthesize hideshprice;
@synthesize hidewsprice;
@synthesize ID;
@synthesize import_id;
@synthesize initial_show;
@synthesize lines;
@synthesize name;
@synthesize owner;
@synthesize season;
@synthesize updated_at;
@synthesize username;
@synthesize vendid;

-(id)copyWithZone:(NSZone *)zone{
    vender* them = [[vender alloc] init];
    them.commodity = commodity;
    them.company = [company copy];
    them.complete = [complete copy];
    them.created_at = [created_at copy];
    them.dlybill = [dlybill copy];
    them.email = [email copy];
    them.hideshprice = hideshprice;
    them.hidewsprice = hidewsprice;
    them.ID = ID;
    them.import_id = import_id;
    them.initial_show = [initial_show copy];
    them.name = [name copy];
    them.owner = [owner copy];
    them.season = [season copy];
    them.updated_at = [updated_at copy];
    them.username = [username copy];
    them.vendid = [vendid copy];
    return them;
}

-(void)loadDictionary:(NSDictionary*)dict{
    if ([dict objectForKey:kVendorCommodity]&&![[dict objectForKey:kVendorCommodity] isKindOfClass:[NSNull class]]) {
        self.commodity = [[dict objectForKey:kVendorCommodity] boolValue];
    }
    if ([dict objectForKey:kVendorCompany]&&![[dict objectForKey:kVendorCompany] isKindOfClass:[NSNull class]]) {
        self.company = [dict objectForKey:kVendorCompany];
    }
    if ([dict objectForKey:kVendorComplete]&&![[dict objectForKey:kVendorComplete] isKindOfClass:[NSNull class]]) {
        self.complete = [dict objectForKey:kVendorComplete];
    }
    if ([dict objectForKey:kVendorCreatedAt]&&![[dict objectForKey:kVendorCreatedAt] isKindOfClass:[NSNull class]]) {
        self.created_at = [dict objectForKey:kVendorCreatedAt];
    }
    if ([dict objectForKey:kVendorDlybill]&&![[dict objectForKey:kVendorDlybill] isKindOfClass:[NSNull class]]) {
        self.dlybill = [dict objectForKey:kVendorDlybill];
    }
    if ([dict objectForKey:kVendorEmail]&&![[dict objectForKey:kVendorEmail] isKindOfClass:[NSNull class]]) {
        self.email = [dict objectForKey:kVendorEmail];
    }
    if ([dict objectForKey:kVenderHidePrice]) {
        self.hideshprice = [[dict objectForKey:kVenderHidePrice] boolValue];
    }
    if ([dict objectForKey:kVendorHideWSPrice]) {
        self.hidewsprice = [[dict objectForKey:kVendorHideWSPrice] boolValue];
    }
    if ([dict objectForKey:kID]) {
        self.ID = [[dict objectForKey:kID] longValue];
    }
    if ([dict objectForKey:kVendorImportID]) {
        self.import_id = [[dict objectForKey:kVendorImportID] longValue];
    }
    if ([dict objectForKey:kVendorInitialShow]&&![[dict objectForKey:kVendorInitialShow] isKindOfClass:[NSNull class]]) {
        self.initial_show = [dict objectForKey:kVendorInitialShow];
    }
    if ([dict objectForKey:kVendorName]&&![[dict objectForKey:kVendorName] isKindOfClass:[NSNull class]]) {
        self.name = [dict objectForKey:kVendorName];
    }
    if ([dict objectForKey:kVendorOwner]&&![[dict objectForKey:kVendorOwner] isKindOfClass:[NSNull class]]) {
        self.owner = [dict objectForKey:kVendorOwner];
    }
    if ([dict objectForKey:kVendorSeason]&&![[dict objectForKey:kVendorSeason] isKindOfClass:[NSNull class]]) {
        self.season = [dict objectForKey:kVendorSeason];
    }
    if ([dict objectForKey:kVendorUpdatedAt]&&![[dict objectForKey:kVendorUpdatedAt] isKindOfClass:[NSNull class]]) {
        self.updated_at = [dict objectForKey:kVendorUpdatedAt];
    }
    if ([dict objectForKey:kVendorUsername]&&![[dict objectForKey:kVendorUsername] isKindOfClass:[NSNull class]]) {
        self.username = [dict objectForKey:kVendorUsername];
    }
    if ([dict objectForKey:kVendorVendID]&&![[dict objectForKey:kVendorVendID] isKindOfClass:[NSNull class]]) {
        self.vendid = [dict objectForKey:kVendorVendID];
    }
}

-(NSString*) description{
    return [NSString stringWithFormat:@"%@%@%@%@",username,email,created_at,company];
}

@end
