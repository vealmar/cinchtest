//
// Created by David Jafari on 2/16/15.
// Copyright (c) 2015 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface CIAlertView : NSObject

+(void)alertSyncEvent:(NSString *)message;
+(void)alertSaveEvent:(NSString *)message;
+(void)alertWarningEvent:(NSString *)message;
+(void)alertErrorEvent:(NSString *)message;

@end

@interface UIColor (CIAlertView)
+(UIColor*)successGreen;
+(UIColor*)errorRed ;
+(UIColor*)warningYellow;
+(UIColor*)messageBlue;
@end