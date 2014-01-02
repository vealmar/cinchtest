//
// Created by septerr on 1/1/14.
// Copyright (c) 2014 Convention Innovations. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MBProgressHUD;


@interface HudUtil : NSObject
+ (MBProgressHUD *)showGlobalProgressHUDWithTitle:(NSString *)title;

+ (void)dismissGlobalHUD;
@end