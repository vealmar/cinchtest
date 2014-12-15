//
//  UIFont+SystemFontOverride.h
//  triptap
//
//  Created by Bogdan Covaci on 19.08.2014.
//  Copyright (c) 2014 Alex Bogdan Covaci. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface UIFont (SystemFontOverride)

+ (UIFont*)iconFontOfSize:(CGFloat)fontSize;
+ (UIFont*)iconAltFontOfSize:(CGFloat)fontSize;

+ (UIFont*)regularFontOfSize:(CGFloat)fontSize;
+ (UIFont*)semiboldFontOfSize:(CGFloat)fontSize;
+ (UIFont*)boldFontOfSize:(CGFloat)fontSize;
+ (UIFont*)lightFontOfSize:(CGFloat)fontSize;

@end
