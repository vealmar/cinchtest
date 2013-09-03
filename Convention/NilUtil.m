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
    if (object == nil || [object isKindOfClass:[NSNull class]]) {
        return nil;
    } else {
        return object;
    }
}
@end