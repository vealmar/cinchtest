//
// Created by septerr on 12/31/13.
// Copyright (c) 2013 Convention Innovations. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DiscountLineItem.h"

@class ALineItem;

@interface DiscountLineItem (Extensions)
- (id)initWithLineItem:(ALineItem *)lineItem context:(NSManagedObjectContext *)context;
@end