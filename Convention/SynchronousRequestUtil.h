//
// Created by septerr on 12/30/13.
// Copyright (c) 2013 Convention Innovations. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface SynchronousRequestUtil : NSObject
+ (NSDictionary *)sendRequestTo:(NSString *)url error:(NSError **)error;
@end