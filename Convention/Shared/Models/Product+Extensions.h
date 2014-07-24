//
// Created by septerr on 12/30/13.
// Copyright (c) 2013 Convention Innovations. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Product.h"

@interface Product (Extensions)
- (id)initWithProductFromServer:(NSDictionary *)productFromServer context:(NSManagedObjectContext *)context;

+ (Product *)findProduct:(NSNumber *)productId;
@end