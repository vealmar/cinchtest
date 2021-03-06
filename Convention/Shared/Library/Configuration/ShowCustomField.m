//
// Created by David Jafari on 6/29/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import "ShowCustomField.h"

@implementation ShowCustomField

- (id)init:(NSDictionary *)json {
    self = [self init];
    if (self) {
        self.id = [NSNumber numberWithInt:[[json objectForKey:@"id"] intValue]];
        self.ownerType = [json objectForKey:@"ownerType"];
        self.fieldName = [json objectForKey:@"fieldName"];
        self.label = [json objectForKey:@"label"];
        self.valueType = [json objectForKey:@"valueType"];
        self.enumValues = [(![[NSNull null] isEqual:[json objectForKey:@"enumValues"]] ? [json objectForKey:@"enumValues"] : @"") componentsSeparatedByString:@","];
        self.sequence = [[json objectForKey:@"sequence"] intValue];
    }

    return self;
}

- (NSString *)fieldKey {
    return [NSString stringWithFormat:@"%@.%@", self.ownerType, self.fieldName];
}

- (BOOL)isStringValueType {
    return [self.valueType isEqualToString:@"String"];
}

- (BOOL)isEnumValueType {
    return [self.valueType isEqualToString:@"Enum"];
}

- (BOOL)isDateValueType {
    return [self.valueType isEqualToString:@"Date"];
}

- (BOOL)isBooleanValueType {
    return [self.valueType isEqualToString:@"Boolean"];
}

@end