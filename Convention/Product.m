//
//  Product.m
//  Convention
//
//  Created by septerr on 9/7/13.
//  Copyright (c) 2013 Convention Innovations. All rights reserved.
//

#import "Product.h"
#import "NilUtil.h"
#import "config.h"
#import "DateUtil.h"


@implementation Product

@dynamic productId;
@dynamic idx;
@dynamic vendid;
@dynamic invtid;
@dynamic company;
@dynamic descr;
@dynamic partnbr;
@dynamic uom;
@dynamic regprc;
@dynamic showprc;
@dynamic caseqty;
@dynamic dirship;
@dynamic linenbr;
@dynamic new;
@dynamic adv;
@dynamic discount;
@dynamic vendor_id;
@dynamic import_id;
@dynamic initial_show;
@dynamic shipdate1;
@dynamic shipdate2;
@dynamic voucher;
@dynamic bulletin;
@dynamic bulletin_id;
@dynamic descr2;
@dynamic min;
@dynamic status;
@dynamic category;

- (id)initWithProductFromServer:(NSDictionary *)productFromServer context:(NSManagedObjectContext *)context {
    self = [super initWithEntity:[NSEntityDescription entityForName:@"Product" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
    if (self) {
        self.productId = (NSNumber *) [NilUtil nilOrObject:[productFromServer objectForKey:kProductId]];
        self.unique_product_id = (NSString *) [NilUtil nilOrObject:[productFromServer objectForKey:kProductUniqueId]];
        self.company = (NSString *) [NilUtil nilOrObject:[productFromServer objectForKey:kProductCompany]];
        self.idx = (NSNumber *) [NilUtil nilOrObject:[productFromServer objectForKey:kProductIdx]];
        self.vendid = (NSString *) [NilUtil nilOrObject:[productFromServer objectForKey:kProductVendID]];
        self.invtid = (NSString *) [NilUtil nilOrObject:[productFromServer objectForKey:kProductInvtid]];
        self.descr = (NSString *) [NilUtil nilOrObject:[productFromServer objectForKey:kProductDescr]];
        self.descr2 = (NSString *) [NilUtil nilOrObject:[productFromServer objectForKey:kProductDescr2]];
        self.partnbr = (NSString *) [NilUtil nilOrObject:[productFromServer objectForKey:kProductPartNbr]];
        self.uom = (NSString *) [NilUtil nilOrObject:[productFromServer objectForKey:kProductUom]];
        self.regprc = (NSString *) [NilUtil nilOrObject:[productFromServer objectForKey:kProductRegPrc]];//todo decimal types are being sent over by ruby app as strings. That is why NumberUtil formatDollarAmount has to first call doubleValue on the passed object. Since the object can actually be a string. Both number and string implement doubleValue.
        self.showprc = (NSString *) [NilUtil nilOrObject:[productFromServer objectForKey:kProductShowPrice]];//for now store these decimals as strings, but after the show refactor to store and use them as actual numbers.
        self.caseqty = (NSString *) [NilUtil nilOrObject:[productFromServer objectForKey:kProductCaseQty]];
        self.dirship = (NSNumber *) [NilUtil nilOrObject:[productFromServer objectForKey:kProductDirShip]];
        self.linenbr = (NSString *) [NilUtil nilOrObject:[productFromServer objectForKey:kProductLineNbr]];
        self.new = (NSNumber *) [NilUtil nilOrObject:[productFromServer objectForKey:kProductNew]];
        self.adv = (NSNumber *) [NilUtil nilOrObject:[productFromServer objectForKey:kProductAdv]];
        self.discount = (NSString *) [NilUtil nilOrObject:[productFromServer objectForKey:kProductDiscount]];
        self.vendor_id = (NSNumber *) [NilUtil nilOrObject:[productFromServer objectForKey:kProductVendorID]];
        self.import_id = (NSNumber *) [NilUtil nilOrObject:[productFromServer objectForKey:kProductImportID]];
        self.initial_show = (NSNumber *) [NilUtil nilOrObject:[productFromServer objectForKey:kProductInitialShow]];
        self.bulletin = (NSNumber *) [NilUtil nilOrObject:[productFromServer objectForKey:kProductBulletin]];
        self.bulletin_id = (NSNumber *) [NilUtil nilOrObject:[productFromServer objectForKey:kProductBulletinId]];
        self.voucher = (NSString *) [NilUtil nilOrObject:[productFromServer objectForKey:kProductVoucher]];
        self.min = (NSNumber *) [NilUtil nilOrObject:[productFromServer objectForKey:kProductMin]];
        self.status = (NSString *) [NilUtil nilOrObject:[productFromServer objectForKey:kProductStatus]];
        self.category = (NSString *) [NilUtil nilOrObject:[productFromServer objectForKey:kProductCategory]];
        NSString *shipdate1Str = (NSString *) [NilUtil nilOrObject:[productFromServer objectForKey:kProductShipDate1]];
        if (shipdate1Str)
            self.shipdate1 = [DateUtil convertYyyymmddthhmmsszToDate:shipdate1Str];
        NSString *shipdate2Str = (NSString *) [NilUtil nilOrObject:[productFromServer objectForKey:kProductShipDate2]];
        if (shipdate2Str)
            self.shipdate2 = [DateUtil convertYyyymmddthhmmsszToDate:shipdate2Str];

    }
    return self;
}

- (NSDictionary *)asDictionary {
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    if (self.productId)
        [dictionary setObject:self.productId forKey:kProductId];
    if (self.unique_product_id)
        [dictionary setObject:self.unique_product_id forKey:kProductUniqueId];
    if (self.company)
        [dictionary setObject:self.company forKey:kProductCompany];
    if (self.idx)
        [dictionary setObject:self.idx forKey:kProductIdx];
    if (self.vendid)
        [dictionary setObject:self.vendid forKey:kProductVendID];
    if (self.invtid)
        [dictionary setObject:self.invtid forKey:kProductInvtid];
    if (self.descr)
        [dictionary setObject:self.descr forKey:kProductDescr];
    if (self.descr2)
        [dictionary setObject:self.descr2 forKey:kProductDescr2];
    if (self.partnbr)
        [dictionary setObject:self.partnbr forKey:kProductPartNbr];
    if (self.uom)
        [dictionary setObject:self.uom forKey:kProductUom];
    if (self.regprc)
        [dictionary setObject:self.regprc forKey:kProductRegPrc];
    if (self.showprc)
        [dictionary setObject:self.showprc forKey:kProductShowPrice];
    if (self.caseqty)
        [dictionary setObject:self.caseqty forKey:kProductCaseQty];
    if (self.dirship)
        [dictionary setObject:self.dirship forKey:kProductDirShip];
    if (self.linenbr)
        [dictionary setObject:self.linenbr forKey:kProductLineNbr];
    if (self.new)
        [dictionary setObject:self.new forKey:kProductNew];
    if (self.adv)
        [dictionary setObject:self.adv forKey:kProductAdv];
    if (self.discount)
        [dictionary setObject:self.discount forKey:kProductDiscount];
    if (self.vendor_id)
        [dictionary setObject:self.vendor_id forKey:kProductVendorID];
    if (self.import_id)
        [dictionary setObject:self.import_id forKey:kProductImportID];
    if (self.initial_show)
        [dictionary setObject:self.initial_show forKey:kProductInitialShow];
    if (self.bulletin)
        [dictionary setObject:self.bulletin forKey:kProductBulletin];
    if (self.bulletin_id)
        [dictionary setObject:self.bulletin_id forKey:kProductBulletinId];
    if (self.voucher)
        [dictionary setObject:self.voucher forKey:kProductVoucher];
    if (self.min)
        [dictionary setObject:self.min forKey:kProductMin];
    if (self.status)
        [dictionary setObject:self.status forKey:kProductStatus];
    if (self.category)
        [dictionary setObject:self.category forKey:kProductCategory];
    if (self.shipdate1)
        [dictionary setObject:[DateUtil convertDateToYyyymmddthhmmssz:self.shipdate1] forKey:kProductShipDate1];
    if (self.shipdate2)
        [dictionary setObject:[DateUtil convertDateToYyyymmddthhmmssz:self.shipdate2] forKey:kProductShipDate2];

    return dictionary;
}
@end