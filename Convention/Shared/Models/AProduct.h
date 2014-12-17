//
// Created by septerr on 1/1/14.
// Copyright (c) 2014 Convention Innovations. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Product;


@interface AProduct : NSObject
@property(nonatomic, retain) NSNumber *adv;
@property(nonatomic, retain) NSNumber *bulletin;
@property(nonatomic, retain) NSNumber *bulletin_id;
@property(nonatomic, retain) NSString *caseqty;
@property(nonatomic, retain) NSString *category;
@property(nonatomic, retain) NSString *company;
@property(nonatomic, retain) NSString *descr;
@property(nonatomic, retain) NSString *descr2;
@property(nonatomic, retain) NSNumber *dirship;
@property(nonatomic, retain) NSString *discount;
@property(nonatomic, retain) NSNumber *idx;
@property(nonatomic, retain) NSNumber *initial_show;
@property(nonatomic, retain) NSString *invtid;
@property(nonatomic, retain) NSString *linenbr;
@property(nonatomic, retain) NSNumber *min;
@property(nonatomic, retain) NSString *partnbr;
@property(nonatomic, retain) NSNumber *productId;
@property(nonatomic, retain) NSNumber *regprc;
@property(nonatomic, retain) NSDate *shipdate1;
@property(nonatomic, retain) NSDate *shipdate2;
@property(nonatomic, retain) NSNumber *showprc;
@property(nonatomic, retain) NSString *status;
@property(nonatomic, retain) NSString *unique_product_id;
@property(nonatomic, retain) NSString *uom;
@property(nonatomic, retain) NSString *vendid;
@property(nonatomic, retain) NSNumber *vendor_id;
@property(nonatomic, retain) NSNumber *voucher;
@property(nonatomic, retain) NSSet *carts;
@property(nonatomic, retain) NSSet *discountLineItems;
@property(nonatomic, retain) NSNumber *editable;


- (id)initWithCoreDataProduct:(Product *)product;
@end