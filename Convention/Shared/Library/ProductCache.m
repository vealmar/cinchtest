//
// Created by septerr on 1/21/14.
// Copyright (c) 2014 Convention Innovations. All rights reserved.
//

#import "ProductCache.h"
#import "Product.h"
#import "AProduct.h"
#import "CoreDataUtil.h"


@interface ProductCache () {
}
@property NSCache *products;
@end

@implementation ProductCache {

}

+ (id)sharedCache {
    static ProductCache *sharedCache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedCache = [[self alloc] init];
    });
    return sharedCache;
}

- (id)init {
    if (self = [super init]) {
        self.products = [[NSCache alloc] init];
    }
    return self;
}


- (AProduct *)getProduct:(NSNumber *)productId {
    AProduct *product = [self.products objectForKey:productId];
    if (!product) {
        CoreDataUtil *coreDataUtil = [CoreDataUtil sharedManager];
        Product *coreDataProduct = (Product *) [coreDataUtil fetchObject:@"Product" withPredicate:[NSPredicate predicateWithFormat:@"(productId == %@)", productId]];
        if (coreDataProduct) {
            product = [[AProduct alloc] initWithCoreDataProduct:coreDataProduct];
            [self.products setObject:product forKey:productId];
        }
    }
    return product;
}

- (void)addRecentlyQueriedProducts:(NSArray *)array {
    //todo: only send the predicates or fetch request and let ProductCache query the products and update itself in the background.
    if (array) {
        [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            AProduct *product = [[AProduct alloc] initWithCoreDataProduct:(Product *) obj];
            [self.products setObject:product forKey:product.productId];
        }];
    }
}
@end