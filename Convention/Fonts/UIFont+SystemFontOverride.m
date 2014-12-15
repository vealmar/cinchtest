//
//  UIFont+SystemFontOverride.m
//  triptap
//
//  Created by Bogdan Covaci on 19.08.2014.
//  Copyright (c) 2014 Alex Bogdan Covaci. All rights reserved.
//

#import "UIFont+SystemFontOverride.h"


@implementation UIFont (SystemFontOverride)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"

+ (UIFont*)iconFontOfSize:(CGFloat)fontSize {
    return [UIFont fontWithName:@"FontAwesome" size:fontSize];
}

+ (UIFont*)iconAltFontOfSize:(CGFloat)fontSize {
    return [UIFont fontWithName:@"GLYPHICONS-Regular" size:fontSize];
}

+ (UIFont*)regularFontOfSize:(CGFloat)fontSize {
    return [UIFont fontWithName:@"OpenSans" size:fontSize];
}

+ (UIFont*)semiboldFontOfSize:(CGFloat)fontSize {
    return [UIFont fontWithName:@"OpenSans-Semibold" size:fontSize];
}

+ (UIFont*)boldFontOfSize:(CGFloat)fontSize {
    return [UIFont fontWithName:@"OpenSans-Bold" size:fontSize];
}

+ (UIFont*)lightFontOfSize:(CGFloat)fontSize {
    return [UIFont fontWithName:@"OpenSans-Light" size:fontSize];
}

#pragma clang diagnostic pop

@end
