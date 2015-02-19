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
#import "StringManipulation.h"
#import "Underscore.h"
#import "APLNormalizedStringTransformer.h"


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

        NSArray *productPrices = [NilUtil objectOrEmptyArray:[productFromServer objectForKey:kProductPrices]];
        NSMutableArray *pricesArrayMutable = [NSMutableArray arrayWithCapacity:productPrices.count];
        for (NSString *obj in productPrices) {
            [pricesArrayMutable addObject:[NumberUtil convertStringToDollars:obj]];
        }
        NSArray *pricesArray = [NSArray arrayWithArray:pricesArrayMutable];
        self.prices = pricesArray;
        self.showprc = pricesArray && pricesArray.count > 0 ? (NSNumber *) pricesArray[0] : [NumberUtil zeroIntNSNumber];
        self.regprc = pricesArray && pricesArray.count > 1 ? (NSNumber *) pricesArray[1] : [NumberUtil zeroIntNSNumber];

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
        NSArray *tagsArray = [NilUtil objectOrEmptyArray:[productFromServer objectForKey:kProductTags]];
        self.tags = tagsArray.count > 0 ? [tagsArray componentsJoinedByString:@","] : nil;

        if ([self.tags contains:@"Write-In"]) {
            self.section = @1;
        } else {
            self.section = @0;
        }

        NSString *value = [NSString stringWithFormat:@"%@ %@ %@ %@ %@",
                        [NilUtil objectOrEmptyString:self.invtid],
                        [NilUtil objectOrEmptyString:self.descr],
                        [NilUtil objectOrEmptyString:self.descr2],
                        [NilUtil objectOrEmptyString:self.tags],
                        [NilUtil objectOrEmptyString:self.partnbr]];
        self.normalizedSearchText = [APLNormalizedStringTransformer normalizeString:value];
    }
    return self;
}

- (BOOL)isWriteIn {
    return [self.tags contains:@"Write-In"];
}

- (NSNumber *)priceAtTier:(int)index {
    if (self.prices.count == 0) {
        return @(0);
    } else if (index >= self.prices.count) {
        return self.prices.lastObject;
    } else {
        return self.prices[(NSUInteger) index];
    }
}

+ (Product *)findProduct:(NSNumber *)productId {
    CoreDataUtil *coreDataUtil = [CoreDataUtil sharedManager];
    return (Product *) [coreDataUtil fetchObject:@"Product" withPredicate:[NSPredicate predicateWithFormat:@"(productId == %@)", productId]];
}
@end