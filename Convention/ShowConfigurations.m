//
// Created by septerr on 8/11/13.
// Copyright (c) 2013 MotionMobs. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "ShowConfigurations.h"
#import "config.h"
#import "SettingsManager.h"

static ShowConfigurations *showConfigurations = nil;

@implementation ShowConfigurations

+ (ShowConfigurations *) instance {
    if (nil == showConfigurations) [NSException raise:NSGenericException format:@"Configuration object has not been created."];
    return showConfigurations;
}
+ (void) createInstanceFromJson:(NSDictionary *)json{
    showConfigurations = [[[self class] alloc] init];
    if(showConfigurations){
        showConfigurations.discounts = (BOOL) [json objectForKey:@"discounts"];
        showConfigurations.shipDates = (BOOL) [json objectForKey:@"shipdates"];
        showConfigurations.printing = (BOOL) [json objectForKey:@"printing"];
        showConfigurations.vouchers = (BOOL) [json objectForKey:@"vouchers"];
        showConfigurations.contracts = (BOOL) [json objectForKey:@"contracts"];
        NSString *loginScreenUrl = ((NSString *) [json objectForKey:@"iosLoginScreen"]);
        showConfigurations.loginScreen = [ShowConfigurations imageFromUrl:loginScreenUrl defaultImage:@"loginBG.png"];
        NSString *logoUrl = ((NSString *) [json objectForKey:@"iosLogo"]);
        showConfigurations.logo = [ShowConfigurations imageFromUrl:logoUrl defaultImage:@"ci_green.png"];
        NSString *dateString = ((NSString *) [json objectForKey:@"boothPaymentsDate"]);
        NSDate *date = nil;
        if (![dateString isKindOfClass:[NSNull class]] && [dateString length] > 0) {
            NSString *dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:dateFormat];
            NSError *error = nil;
            [dateFormatter getObjectValue:&date forString:dateString range:nil error:&error];
            if(error != nil){
                NSLog(@"Could not parse Booth Payments Date '%@'. Expected Format: '%@'.", dateString, dateFormat);
            }
        }
        showConfigurations.boothPaymentsDate = date;
    }
}

+ (UIImage *) imageFromUrl: (NSString *)url defaultImage: (NSString *)imageName{
    UIImage *image = nil;
    if(![url isKindOfClass:[NSNull class]] && [url length] > 0){
        @try{
        NSURL *imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", kBASEURL, url]];
        NSData *imageData = [NSData dataWithContentsOfURL:imageURL];
        image = [UIImage imageWithData:imageData];
        }
        @catch (NSException *e){
            NSLog(@"Could Not Load Image: %@. Exception: %@", url, e);

        }
    }
    return image == nil? [UIImage imageNamed:imageName] : image;

}

@end