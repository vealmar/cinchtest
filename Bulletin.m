//
//  Bulletin.m
//  Convention
//
//  Created by septerr on 9/9/13.
//  Copyright (c) 2013 Convention Innovations. All rights reserved.
//

#import "Bulletin.h"
#import "NilUtil.h"
#import "config.h"
#import "DateUtil.h"


@implementation Bulletin

@dynamic bulletinId;
@dynamic number;
@dynamic name;
@dynamic note1;
@dynamic note2;
@dynamic shipdate1;
@dynamic shipdate2;
@dynamic vendor_id;
@dynamic show_id;
@dynamic status;
@dynamic import_id;

- (id)initWithBulletinFromServer:(NSDictionary *)bulletinFromServer context:(NSManagedObjectContext *)context {
    self = [super initWithEntity:[NSEntityDescription entityForName:@"Bulletin" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
    if (self) {
        self.bulletinId = (NSNumber *) [NilUtil nilOrObject:[bulletinFromServer objectForKey:kBulletinId]];
        self.number = (NSNumber *) [NilUtil nilOrObject:[bulletinFromServer objectForKey:kBulletinNumber]];
        self.name = (NSString *) [NilUtil nilOrObject:[bulletinFromServer objectForKey:kBulletinName]];
        self.note1 = (NSString *) [NilUtil nilOrObject:[bulletinFromServer objectForKey:kBulletinNote1]];
        self.note2 = (NSString *) [NilUtil nilOrObject:[bulletinFromServer objectForKey:kBulletinNote2]];
        NSString *datestr = (NSString *) [NilUtil nilOrObject:[bulletinFromServer objectForKey:kBulletinShipDate1]];
        self.shipdate1 = datestr ? [DateUtil convertYyyymmddthhmmsszToDate:datestr] : nil;
        datestr = (NSString *) [NilUtil nilOrObject:[bulletinFromServer objectForKey:kBulletinShipDate2]];
        self.shipdate2 = datestr ? [DateUtil convertYyyymmddthhmmsszToDate:datestr] : nil;
        self.vendor_id = (NSNumber *) [NilUtil nilOrObject:[bulletinFromServer objectForKey:kBulletinVendorId]];
        self.show_id = (NSNumber *) [NilUtil nilOrObject:[bulletinFromServer objectForKey:kBulletinShowId]];
        self.status = (NSString *) [NilUtil nilOrObject:[bulletinFromServer objectForKey:kBulletinStatus]];
        self.import_id = (NSNumber *) [NilUtil nilOrObject:[bulletinFromServer objectForKey:kBulletinImportId]];
    }
    return self;
}

- (NSDictionary *)asDictionary {
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    if (self.bulletinId)
        [dictionary setObject:self.bulletinId forKey:kBulletinId];
    if (self.number)
        [dictionary setObject:self.number forKey:kBulletinNumber];
    if (self.name)
        [dictionary setObject:self.name forKey:kBulletinName];
    if (self.note1)
        [dictionary setObject:self.note1 forKey:kBulletinNote1];
    if (self.note2)
        [dictionary setObject:self.note2 forKey:kBulletinNote2];
    if (self.shipdate1)
        [dictionary setObject:[DateUtil convertDateToYyyymmddthhmmssz:self.shipdate1] forKey:kBulletinShipDate1];
    if (self.shipdate2)
        [dictionary setObject:[DateUtil convertDateToYyyymmddthhmmssz:self.shipdate2] forKey:kBulletinShipDate2];
    if (self.vendor_id)
        [dictionary setObject:self.vendor_id forKey:kBulletinVendorId];
    if (self.show_id)
        [dictionary setObject:self.show_id forKey:kBulletinShowId];
    if (self.status)
        [dictionary setObject:self.status forKey:kBulletinStatus];
    if (self.import_id)
        [dictionary setObject:self.import_id forKey:kBulletinImportId];
    return dictionary;
}
@end
