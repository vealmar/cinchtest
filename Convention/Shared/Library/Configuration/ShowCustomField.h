//
// Created by David Jafari on 6/29/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ShowCustomField : NSObject

@property NSNumber *id;
@property NSString *ownerType;
@property NSString *fieldName;
@property NSString *label;
@property NSString *valueType;
@property NSArray *enumValues;
@property int sequence;

@property (readonly) NSString *fieldKey;

- (id)init:(NSDictionary *)json;

- (BOOL)isStringValueType;
- (BOOL)isEnumValueType;
- (BOOL)isDateValueType;
- (BOOL)isBooleanValueType;

@end