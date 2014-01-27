//
// Created by septerr on 8/21/13.
// Copyright (c) 2013 Convention Innovations. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "NilUtil.h"


@implementation NilUtil {
}
+ (NSObject *)nilOrObject:(NSObject *)object {
    return [NilUtil objectOrDefault:object defaultObject:nil];
}

+ (NSString *)objectOrDefaultString:(NSObject *)object defaultObject:(NSString *)defaultString {
    return (NSString *) [NilUtil objectOrDefault:object defaultObject:defaultString];
}

+ (NSString *)objectOrEmptyString:(NSObject *)object {
    return (NSString *) [NilUtil objectOrDefault:object defaultObject:@""];
}

+ (NSArray *)objectOrEmptyArray:(NSObject *)object {
    return (NSArray *) [NilUtil objectOrDefault:object defaultObject:[[NSArray alloc] init]];
}

+ (NSObject *)objectOrNSNull:(NSObject *)object {
    return [NilUtil objectOrDefault:object defaultObject:[NSNull null]];

}

+ (NSObject *)objectOrDefault:(NSObject *)object defaultObject:(NSObject *)defaultObject {
    if (object == nil || [object isKindOfClass:[NSNull class]]) {
        return defaultObject;
    } else {
        return object;
    }
}


@end