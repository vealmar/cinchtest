//
// Created by David Jafari on 1/29/15.
// Copyright (c) 2015 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    KeyPressTypeAlphanumeric,
    KeyPressTypeArrow,
    KeyPressTypeEscape,
    KeyPressTypeEnter
} KeyPressType;

@interface CIApplication : UIApplication

@property (nonatomic,readonly) NSArray *keyCommands;
+ (NSArray *)allKeys;

@end