//
// Created by David Jafari on 2/16/15.
// Copyright (c) 2015 Urban Coding. All rights reserved.
//

#import "CIAlertView.h"
#import "GoogleWearAlertObjc.h"
#import "ThemeUtil.h"

@implementation CIAlertView

+(void)alertSyncEvent:(NSString *)message {
    GoogleWearAlertViewObjc *alertView = [[GoogleWearAlertViewObjc alloc] initWithTitle:message
                                                                               andImage:nil
                                                                            andWithType:Success
                                                                        andWithDuration:1.3
                                                                       inViewController:[[GoogleWearAlertObjc getInstance] useDefaultController]
                                                                              atPostion:Center
                                                                   canBeDismissedByUser:YES];
    [[GoogleWearAlertObjc getInstance]prepareNotificationToBeShown:alertView];
}

+(void)alertSaveEvent:(NSString *)message {
    GoogleWearAlertViewObjc *alertView = [[GoogleWearAlertViewObjc alloc] initWithTitle:message
                                                                               andImage:nil
                                                                            andWithType:Message
                                                                        andWithDuration:1.3
                                                                       inViewController:[[GoogleWearAlertObjc getInstance] useDefaultController]
                                                                              atPostion:Center
                                                                   canBeDismissedByUser:YES];
    [[GoogleWearAlertObjc getInstance]prepareNotificationToBeShown:alertView];
}

+(void)alertWarningEvent:(NSString *)message {
    GoogleWearAlertViewObjc *alertView = [[GoogleWearAlertViewObjc alloc] initWithTitle:message
                                                                               andImage:nil
                                                                            andWithType:Warning
                                                                        andWithDuration:1.3
                                                                       inViewController:[[GoogleWearAlertObjc getInstance] useDefaultController]
                                                                              atPostion:Center
                                                                   canBeDismissedByUser:YES];
    [[GoogleWearAlertObjc getInstance]prepareNotificationToBeShown:alertView];
}

+(void)alertErrorEvent:(NSString *)message {
    GoogleWearAlertViewObjc *alertView = [[GoogleWearAlertViewObjc alloc] initWithTitle:[NSString stringWithFormat:@"Error\n%@", message]
                                                                               andImage:nil
                                                                            andWithType:Error
                                                                        andWithDuration:1.5
                                                                       inViewController:[[GoogleWearAlertObjc getInstance] useDefaultController]
                                                                              atPostion:Center
                                                                   canBeDismissedByUser:YES];
    [[GoogleWearAlertObjc getInstance]prepareNotificationToBeShown:alertView];
}

@end

@implementation UIColor (CIAlertView)
+(UIColor*)successGreen{
    return  [UIColor colorWithRed:69.0/255.0 green:181.0/255.0 blue:38.0/255.0 alpha:1];

}
+(UIColor*)errorRed  {
    return  [UIColor colorWithRed:255.0/255.0 green:82.0/255.0 blue:82.0/255.0 alpha:1];
}
+(UIColor*)warningYellow  {
    return  [UIColor colorWithRed:255.0/255.0 green:205.0/255.0 blue:64.0/255.0 alpha:1];


}
+(UIColor*)messageBlue  {
//    return  [UIColor colorWithRed:2.0/255.0 green:169.0/255.0 blue:244.0/255.0 alpha:1];
    return [ThemeUtil darkBlueColor];
}

@end