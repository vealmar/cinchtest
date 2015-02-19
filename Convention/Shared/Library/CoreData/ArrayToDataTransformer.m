//
// Created by David Jafari on 2/13/15.
// Copyright (c) 2015 Urban Coding. All rights reserved.
//

#import "ArrayToDataTransformer.h"

@implementation ArrayToDataTransformer

+ (BOOL)allowsReverseTransformation {
    return YES;
}

+ (Class)transformedValueClass {
    return [NSData class];
}

- (id)transformedValue:(id)value {
    //Take an NSArray archive to NSData
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:value];
    return data;
}

- (id)reverseTransformedValue:(id)value {
    //Take NSData unarchive to NSArray
    NSArray *array = (NSArray*)[NSKeyedUnarchiver unarchiveObjectWithData:value];
    return array;
}

@end