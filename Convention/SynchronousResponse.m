//
// Created by septerr on 12/30/13.
// Copyright (c) 2013 Convention Innovations. All rights reserved.
//

#import "SynchronousResponse.h"


@implementation SynchronousResponse {

}
- (id)initWithStatusCode:(NSInteger)statusCode andJson:(NSDictionary *)json {
    self = [super init];
    if (self) {
        self.statusCode = statusCode;
        self.json = json;
    }
    return self;
}

- (BOOL)successful {
    return self.statusCode > 199 && self.statusCode < 300;
}

- (BOOL)unprocessibleEntity {
    return self.statusCode == 422;
}
@end