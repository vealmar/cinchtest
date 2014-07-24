//
// Created by septerr on 12/28/13.
// Copyright (c) 2013 Convention Innovations. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Error.h"

@interface Error (Extensions)
- (id)initWithMessage:(NSString *)message andContext:(NSManagedObjectContext *)context;
@end