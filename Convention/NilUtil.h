//
// Created by septerr on 8/21/13.
// Copyright (c) 2013 Convention Innovations. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>


@interface NilUtil : NSObject
+ (NSObject *)nilOrObject:(NSObject *)object;

+ (NSString *)objectOrDefaultString:(NSObject *)object defaultObject:(NSString *)defaultString;

+ (NSString *)objectOrEmptyString:(NSObject *)object;

+ (NSArray *)objectOrEmptyArray:(NSObject *)object;

+ (NSObject *)objectOrNSNull:(NSObject *)object;

+ (NSObject *)objectOrDefault:(NSObject *)object defaultObject:(NSObject *)defaultObject;
@end