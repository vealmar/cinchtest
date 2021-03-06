//
//  Product.h
//  Convention
//
//  Created by septerr on 3/22/14.
//  Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface Product : NSManagedObject

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
@property(nonatomic, retain) NSString *invtid;
@property(nonatomic, retain) NSNumber *sequence;
@property(nonatomic, retain) NSNumber *min;
@property(nonatomic, retain) NSString *partnbr; // used for manufacturer_no
@property(nonatomic, retain) NSNumber *productId;
@property(nonatomic, retain) NSDate *shipdate1;
@property(nonatomic, retain) NSDate *shipdate2;
@property(nonatomic, retain) NSString *status;
@property(nonatomic, retain) NSString *unique_product_id;
@property(nonatomic, retain) NSString *uom;
@property(nonatomic, retain) NSString *vendid;
@property(nonatomic, retain) NSNumber *vendor_id;
@property(nonatomic, retain) NSNumber *voucher;
@property(nonatomic, retain) NSNumber *editable;
@property(nonatomic, retain) NSNumber *section; // meta-property used to order products by sections
@property(nonatomic, retain) NSString *tags; // tags are stored in the form "Tag1, Tag2, Tag3" to enable easier querying

@property(nonatomic, retain) NSNumber *regprc;
@property(nonatomic, retain) NSNumber *showprc;
@property(nonatomic, retain) NSArray *prices;

@property(nonatomic, retain) NSSet *lineItems;

@property(nonatomic, retain) NSString *normalizedSearchText;

@end

@interface Product (CoreDataGeneratedAccessors)

@end
