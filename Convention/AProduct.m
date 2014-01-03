//
// Created by septerr on 1/1/14.
// Copyright (c) 2014 Convention Innovations. All rights reserved.
//

#import "AProduct.h"
#import "Product.h"


@implementation AProduct {

}
- (id)initWithCoreDataProduct:(Product *)product {
    self.adv = product.adv;
    self.bulletin = product.bulletin;
    self.bulletin_id = product.bulletin_id;
    self.caseqty = product.caseqty;
    self.category = product.category;
    self.company = product.company;
    self.descr = product.descr;
    self.descr2 = product.descr2;
    self.dirship = product.dirship;
    self.discount = product.discount;
    self.idx = product.idx;
    self.import_id = product.import_id;
    self.initial_show = product.initial_show;
    self.invtid = product.invtid;
    self.linenbr = product.linenbr;
    self.min = product.min;
    self.partnbr = product.partnbr;
    self.productId = product.productId;
    self.regprc = product.regprc;
    self.shipdate1 = product.shipdate1;
    self.shipdate2 = product.shipdate2;
    self.showprc = product.showprc;
    self.status = product.status;
    self.unique_product_id = product.unique_product_id;
    self.uom = product.uom;
    self.vendid = product.vendid;
    self.vendor_id = product.vendor_id;
    self.voucher = product.voucher;
}
@end