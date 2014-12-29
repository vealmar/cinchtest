//
// Created by septerr on 12/30/13.
// Copyright (c) 2013 Convention Innovations. All rights reserved.
//

#import "Product+Extensions.h"
#import "NilUtil.h"
#import "config.h"
#import "DateUtil.h"
#import "CoreDataUtil.h"
#import "NumberUtil.h"


@implementation Product (Extensions)
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
        NSString *regPriceStr = (NSString *) [NilUtil nilOrObject:[productFromServer objectForKey:kProductRegPrc]];
        if (regPriceStr) {
            NSNumber *decimalRegPrice = [NumberUtil convertStringToDollars:regPriceStr];
            self.regprc = decimalRegPrice;
        } else {
            self.regprc = [NumberUtil zeroIntNSNumber];
        }
        NSString *showPriceStr = (NSString *) [NilUtil nilOrObject:[productFromServer objectForKey:kProductShowPrice]];
        if (showPriceStr) {
            NSNumber *decimalShowPrice = [NumberUtil convertStringToDollars:showPriceStr];
            self.showprc = decimalShowPrice;
        } else {
            self.showprc = [NumberUtil zeroIntNSNumber];
        }
        self.caseqty = (NSString *) [NilUtil nilOrObject:[productFromServer objectForKey:kProductCaseQty]];
        self.dirship = (NSNumber *) [NilUtil nilOrObject:[productFromServer objectForKey:kProductDirShip]];
        self.sequence = (NSNumber *) [NilUtil nilOrObject:[productFromServer objectForKey:kProductSequence]];
        self.adv = (NSNumber *) [NilUtil nilOrObject:[productFromServer objectForKey:kProductAdv]];
        self.discount = (NSString *) [NilUtil nilOrObject:[productFromServer objectForKey:kProductDiscount]];
        self.vendor_id = (NSNumber *) [NilUtil nilOrObject:[productFromServer objectForKey:kProductVendorID]];
        self.initial_show = (NSNumber *) [NilUtil nilOrObject:[productFromServer objectForKey:kProductInitialShow]];
        self.bulletin = (NSNumber *) [NilUtil nilOrObject:[productFromServer objectForKey:kProductBulletin]];
        self.bulletin_id = (NSNumber *) [NilUtil nilOrObject:[productFromServer objectForKey:kProductBulletinId]];
        NSString *voucherStr = (NSString *) [NilUtil nilOrObject:[productFromServer objectForKey:kProductVoucher]];
        if (voucherStr) {
            NSDecimalNumber *decimalVoucher = [NSDecimalNumber decimalNumberWithString:voucherStr];
            self.voucher = [NumberUtil convertDollarsToCents:decimalVoucher];
        } else {
            self.voucher = [NumberUtil zeroIntNSNumber];
        }
        self.min = (NSNumber *) [NilUtil nilOrObject:[productFromServer objectForKey:kProductMin]];
        self.partnbr = (NSString *) [NilUtil nilOrObject:[productFromServer objectForKey:kProductManufacturerNo]];
        self.status = (NSString *) [NilUtil nilOrObject:[productFromServer objectForKey:kProductStatus]];
        self.category = (NSString *) [NilUtil nilOrObject:[productFromServer objectForKey:kProductCategory]];
        NSString *shipdate1Str = (NSString *) [NilUtil nilOrObject:[productFromServer objectForKey:kProductShipDate1]];
        if (shipdate1Str)
            self.shipdate1 = [DateUtil convertApiDateTimeToNSDate:shipdate1Str];
        NSString *shipdate2Str = (NSString *) [NilUtil nilOrObject:[productFromServer objectForKey:kProductShipDate2]];
        if (shipdate2Str)
            self.shipdate2 = [DateUtil convertApiDateTimeToNSDate:shipdate2Str];
        self.editable = (NSNumber *) [NilUtil nilOrObject:[productFromServer objectForKey:kProductEditable]];
    }
    return self;
}

+ (Product *)findProduct:(NSNumber *)productId {
    CoreDataUtil *coreDataUtil = [CoreDataUtil sharedManager];
    return (Product *) [coreDataUtil fetchObject:@"Product" withPredicate:[NSPredicate predicateWithFormat:@"(productId == %@)", productId]];
}
@end