//
// Created by septerr on 12/28/13.
// Copyright (c) 2013 Convention Innovations. All rights reserved.
//

#import "Error+Extensions.h"


@implementation Error (Extensions)

- (id)initWithMessage:(NSString *)message andContext:(NSManagedObjectContext *)context {
    self = [super initWithEntity:[NSEntityDescription entityForName:@"Error" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
    if (self)
        self.message = message;
    return self;
}

@end