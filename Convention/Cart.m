//
//  Cart.m
//  Convention
//
//  Created by Kerry Sanders on 1/21/13.
//  Copyright (c) 2013 MotionMobs. All rights reserved.
//

#import "Cart.h"
#import "ShipDate.h"
#import "ALineItem.h"
#import "NilUtil.h"
#import "config.h"
#import "DateUtil.h"


@implementation Cart

@dynamic adv;
@dynamic cartId;
@dynamic caseqty;
@dynamic category;
@dynamic company;
@dynamic created_at;
@dynamic descr;
@dynamic descr2;
@dynamic dirship;
@dynamic discount;
@dynamic editablePrice;
@dynamic editableQty;
@dynamic editableVoucher;
@dynamic idx;
@dynamic import_id;
@dynamic initial_show;
@dynamic invtid;
@dynamic linenbr;
@dynamic new;
@dynamic orderLineItem_id;
@dynamic partnbr;
@dynamic regprc;
@dynamic shipdate1;
@dynamic shipdate2;
@dynamic showprc;
@dynamic unique_product_id;
@dynamic uom;
@dynamic updated_at;
@dynamic vendid;
@dynamic vendor_id;
@dynamic voucher;
@dynamic order;
@dynamic shipdates;

- (id)initWithLineItem:(ALineItem *)lineItem forProduct:(NSDictionary *)product andCustomer:(NSDictionary *)customer context:(NSManagedObjectContext *)context {
    self = [super initWithEntity:[NSEntityDescription entityForName:@"Cart" inManagedObjectContext:context] insertIntoManagedObjectContext:context];

    if (self) {
        self.adv = (BOOL) [NilUtil nilOrObject:[product objectForKey:kProductAdv]];
        self.cartId = [(NSNumber *) [NilUtil nilOrObject:[product objectForKey:kProductId]] intValue];
        self.caseqty = (NSString *) [NilUtil nilOrObject:[product objectForKey:kProductCaseQty]];
        self.category = lineItem.category;
        self.company = (NSString *) [NilUtil nilOrObject:[product objectForKey:kProductCompany]];
        self.descr = lineItem.desc;
        self.descr2 = lineItem.desc2;
        self.dirship = (BOOL) [NilUtil nilOrObject:[product objectForKey:kProductDirShip]];
        self.discount = [(NSNumber *) [NilUtil nilOrObject:[product objectForKey:kProductDiscount]] floatValue];
        self.editablePrice = [lineItem.price floatValue];
        self.editableQty = lineItem.quantity;
        self.editableVoucher = [lineItem.voucherPrice floatValue];
        self.idx = [(NSNumber *) [NilUtil nilOrObject:[product objectForKey:kProductIdx]] intValue];
        self.import_id = [(NSNumber *) [NilUtil nilOrObject:[product objectForKey:kProductImportID]] intValue];
        self.initial_show = (NSString *) [NilUtil nilOrObject:[product objectForKey:kProductInitialShow]];
        self.invtid = (NSString *) [NilUtil nilOrObject:[product objectForKey:kProductInvtid]];
        self.linenbr = (NSString *) [NilUtil nilOrObject:[product objectForKey:kProductLineNbr]];
        self.new = (BOOL) [NilUtil nilOrObject:[product objectForKey:kProductNew]];
        self.orderLineItem_id = [lineItem.itemId intValue];
        self.partnbr = (NSString *) [NilUtil nilOrObject:[product objectForKey:kProductPartNbr]];
        self.regprc = (NSString *) [NilUtil nilOrObject:[product objectForKey:kProductRegPrc]];
        self.shipdate1 = (NSString *) [NilUtil nilOrObject:[product objectForKey:kProductShipDate1]];
        self.shipdate2 = (NSString *) [NilUtil nilOrObject:[product objectForKey:kProductShipDate2]];
        self.showprc = (NSString *) [NilUtil nilOrObject:[product objectForKey:kProductShowPrice]];
        self.unique_product_id = (NSString *) [NilUtil nilOrObject:[product objectForKey:kProductUniqueId]];
        self.uom = (NSString *) [NilUtil nilOrObject:[product objectForKey:kProductUom]];
        self.created_at = (NSString *) [NilUtil nilOrObject:[product objectForKey:kProductCreatedAt]];
        self.updated_at = (NSString *) [NilUtil nilOrObject:[product objectForKey:kProductUpdatedAt]];
        self.vendid = (NSString *) [NilUtil nilOrObject:[product objectForKey:kProductVendID]];
        self.vendor_id = [(NSNumber *) [NilUtil nilOrObject:[product objectForKey:kProductVendorID]] intValue];
        self.voucher = (NSString *) [NilUtil nilOrObject:[product objectForKey:kProductVoucher]];
        if (lineItem.shipDates && lineItem.shipDates.count > 0) {
            NSMutableOrderedSet *coreDataShipDates = [[NSMutableOrderedSet alloc] init];
            for (NSString *jsonDate in lineItem.shipDates) {
                NSDate *shipDate = [DateUtil convertJsonDateToNSDate:jsonDate];
                ShipDate *coreDataShipDate = [[ShipDate alloc] initWithEntity:[NSEntityDescription entityForName:@"ShipDate" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
                coreDataShipDate.shipdate = shipDate;
                [coreDataShipDates addObject:coreDataShipDate];
            }
            self.shipdates = coreDataShipDates;
        }
    }
    return self;
}
@end
