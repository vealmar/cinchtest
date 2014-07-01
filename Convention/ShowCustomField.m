//
// Created by David Jafari on 6/29/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import "ShowCustomField.h"

@implementation ShowCustomField

- (id)init:(NSDictionary *)json {
    self = [self init];
    if (self) {
        self.ownerType = [json objectForKey:@"ownerType"];
        self.fieldName = [json objectForKey:@"fieldName"];
        self.label = [json objectForKey:@"label"];
        self.valueType = [json objectForKey:@"valueType"];
        self.enumValues = [(![[NSNull null] isEqual:[json objectForKey:@"enumValues"]] ? [json objectForKey:@"enumValues"] : @"") componentsSeparatedByString:@","];
        self.sequence = [[json objectForKey:@"sequence"] intValue];
    }

    return self;
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