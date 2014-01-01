//
// Created by septerr on 12/30/13.
// Copyright (c) 2013 Convention Innovations. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface SynchronousResponse : NSObject
@property(strong, nonatomic) NSDictionary *json;
@property(nonatomic) NSInteger statusCode;

- (id)initWithStatusCode:(NSInteger)statusCode andJson:(NSDictionary *)json;

- (BOOL)successful;

- (BOOL)unprocessibleEntity;
@end