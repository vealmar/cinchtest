//
// Created by David Jafari on 12/20/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import "CITableViewColumn.h"

NSString *const ColumnOptionCustomTypeClass = @"ColumnOptionCustomTypeClass";
NSString *const ColumnOptionTextAlignment = @"ColumnOptionTextAlignment";
NSString *const ColumnOptionContentKey = @"ColumnOptionContentKey";
NSString *const ColumnOptionContentKey2 = @"ColumnOptionContentKey2";
NSString *const ColumnOptionDesiredWidth = @"ColumnOptionDesiredWidth";
NSString *const ColumnOptionHorizontalPadding = @"ColumnOptionHorizontalPadding";
NSString *const ColumnOptionHorizontalInset = @"ColumnOptionHorizontalInset";
NSString *const ColumnOptionTitleTextAttributes = @"ColumnOptionTitleTextAttributes";
@implementation CITableViewColumn

static int instanceIdCounter = 1;

-(id)init {
    self = [super init];
    if (self) {
        _instanceId = [NSNumber numberWithInt:instanceIdCounter++];
    }
    return self;
}

-(NSTextAlignment)alignment {
    return [[self.options valueForKey:ColumnOptionTextAlignment] intValue];
}

-(NSArray *)valuesFor:(id)rowData {
    NSMutableArray *array = [NSMutableArray array];

    id value1 = [self objectForKey:ColumnOptionContentKey in:rowData];
    if ([self valuePresent:value1]) [array addObject:value1];

    id value2 = [self objectForKey:ColumnOptionContentKey2 in:rowData];
    if ([self valuePresent:value2]) [array addObject:value2];

    return [NSArray arrayWithArray:array];
}

- (id)objectForKey:(NSString *)key in:(id)rowData {
    id key1 = [self.options valueForKey:key];
    id value1 = nil;
    if (key1) {
        SEL key1Selector = NSSelectorFromString(key1);
        if ([rowData respondsToSelector:key1Selector]) {
            value1 = [rowData performSelector:key1Selector];
        }
    }
    return value1;
}

- (BOOL)valuePresent:(id)value {
    if (value) {
        if ([value isKindOfClass:[NSString class]]) {
            return [((NSString *)value) length] > 0;
        } else {
            return YES;
        }
    } else {
        return NO;
    }
}

@end