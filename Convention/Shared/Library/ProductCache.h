//
// Created by septerr on 1/21/14.
// Copyright (c) 2014 Convention Innovations. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AProduct;


@interface ProductCache : NSObject
+ (id)sharedCache;

- (AProduct *)getProduct:(NSNumber *)productId;

- (void)addRecentlyQueriedProducts:(NSArray *)array;
@end