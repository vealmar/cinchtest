//
// Created by septerr on 1/21/14.
// Copyright (c) 2014 Convention Innovations. All rights reserved.
//

#import "ProductCache.h"
#import "Product.h"
#import "CoreDataUtil.h"

@interface ProductCache ()

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


- (Product *)getProduct:(NSNumber *)productId {
    Product *product = [self.products objectForKey:productId];
    if (!product) {
        CoreDataUtil *coreDataUtil = [CoreDataUtil sharedManager];
        product = (Product *) [coreDataUtil fetchObject:@"Product" withPredicate:[NSPredicate predicateWithFormat:@"(productId == %@)", productId]];
        if (product) {
            [self.products setObject:product forKey:productId];
        }
    }
    return product;
}

- (void)addRecentlyQueriedProducts:(NSArray *)array {
    //todo: only send the predicates or fetch request and let ProductCache query the products and update itself in the background.
    if (array) {
        [array enumerateObjectsUsingBlock:^(Product *product, NSUInteger idx, BOOL *stop) {
            [self.products setObject:product forKey:product.productId];
        }];
    }
}
@end