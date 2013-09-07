//
//  Product.h
//  Convention
//
//  Created by septerr on 9/7/13.
//  Copyright (c) 2013 Convention Innovations. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Product : NSManagedObject

@property(nonatomic, retain) NSNumber *productId;
@property(nonatomic, retain) NSString *unique_product_id;
@property(nonatomic, retain) NSNumber *idx;
@property(nonatomic, retain) NSString *vendid;
@property(nonatomic, retain) NSString *invtid;
@property(nonatomic, retain) NSString *company;
@property(nonatomic, retain) NSString *descr;
@property(nonatomic, retain) NSString *partnbr;
@property(nonatomic, retain) NSString *uom;
@property(nonatomic, retain) NSString *regprc; //todo change type to number, json contains decimal string, convert it to number before storing. check usages to make sure nothing breaks.
@property(nonatomic, retain) NSString *showprc;
@property(nonatomic, retain) NSString *caseqty;
@property(nonatomic, retain) NSNumber *dirship;
@property(nonatomic, retain) NSString *linenbr;
@property(nonatomic, retain) NSNumber *new;
@property(nonatomic, retain) NSNumber *adv;
@property(nonatomic, retain) NSString *discount;
@property(nonatomic, retain) NSNumber *vendor_id;
@property(nonatomic, retain) NSNumber *import_id;
@property(nonatomic, retain) NSNumber *initial_show;
@property(nonatomic, retain) NSDate *shipdate1;
@property(nonatomic, retain) NSDate *shipdate2;
@property(nonatomic, retain) NSString *voucher;
@property(nonatomic, retain) NSNumber *bulletin;
@property(nonatomic, retain) NSNumber *bulletin_id;
@property(nonatomic, retain) NSString *descr2;
@property(nonatomic, retain) NSNumber *min;
@property(nonatomic, retain) NSString *status;
@property(nonatomic, retain) NSString *category;

- (id)initWithProductFromServer:(NSDictionary *)productFromServer context:(NSManagedObjectContext *)context;

- (NSDictionary *)asDictionary;
@end
