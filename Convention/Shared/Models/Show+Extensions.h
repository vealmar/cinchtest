//
// Created by septerr on 3/27/15.
// Copyright (c) 2015 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Show.h"

@interface Show (Extensions)
- (id)initWithShowFromServer:(NSDictionary *)showFromServer context:(NSManagedObjectContext *)context;

- (NSDictionary *)asDictionary;
@end