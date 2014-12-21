//
// Created by septerr on 8/11/13.
// Copyright (c) 2013 MotionMobs. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Underscore.m/Underscore.h>
#import "ShowConfigurations.h"
#import "config.h"
#import "SettingsManager.h"
#import "NilUtil.h"
#import "DateRange.h"
#import "ShowCustomField.h"

static ShowConfigurations *showConfigurations = nil;

@implementation ShowConfigurations

+ (ShowConfigurations *)instance {
    if (nil == showConfigurations) [NSException raise:NSGenericException format:@"Configuration object has not been created."];
    return showConfigurations;
}

+ (void)createInstanceFromJson:(NSDictionary *)json {
    showConfigurations = [[[self class] alloc] init];
    if (showConfigurations) {
        showConfigurations.productEnableManufacturerNo = [[json objectForKey:@"productEnableManufacturerNo"] boolValue];
        showConfigurations.atOncePricing = [[json objectForKey:@"atOncePricing"] boolValue];
        showConfigurations.discounts = [[json objectForKey:@"discounts"] boolValue];
        NSString *shipDatesValue = [NilUtil objectOrEmptyString:[json objectForKey:@"shipDates"]];
        showConfigurations.shipDates = [shipDatesValue isEqualToString:@"required"] || [shipDatesValue isEqualToString:@"optional"];
        showConfigurations.shipDatesRequired = [shipDatesValue isEqualToString:@"required"];
        showConfigurations.printing = [[json objectForKey:@"printing"] boolValue];
        showConfigurations.vouchers = [[json objectForKey:@"vouchers"] boolValue];
        showConfigurations.contracts = [[json objectForKey:@"contracts"] boolValue];
        showConfigurations.contactBeforeShipping = [[json objectForKey:@"contactBeforeShipping"] boolValue];
        showConfigurations.cancelOrder = [[json objectForKey:@"cancelOrder"] boolValue];
        showConfigurations.captureSignature = [[json objectForKey:@"signatureCapture"] boolValue];
        NSString *loginScreenUrl = ((NSString *) [json objectForKey:@"iosLoginScreen"]);
        showConfigurations.loginScreen = [ShowConfigurations imageFromUrl:loginScreenUrl defaultImage:@"loginBG.png"];
        NSString *logoUrl = ((NSString *) [json objectForKey:@"iosLogo"]);
        showConfigurations.logo = [ShowConfigurations imageFromUrl:logoUrl defaultImage:@"background-brand"];
        NSString *dateString = ((NSString *) [json objectForKey:@"boothPaymentsDate"]);
        NSDate *date = nil;
        if (![dateString isKindOfClass:[NSNull class]] && [dateString length] > 0) {
            NSString *dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:dateFormat];
            NSError *error = nil;
            [dateFormatter getObjectValue:&date forString:dateString range:nil error:&error];
            if (error != nil) {
                NSLog(@"Could not parse Booth Payments Date '%@'. Expected Format: '%@'.", dateString, dateFormat);
            }
        }
        showConfigurations.boothPaymentsDate = date;
        showConfigurations.poNumber = [[json objectForKey:@"poNumber"] boolValue];
        showConfigurations.paymentTerms = [[json objectForKey:@"paymentTerms"] boolValue];
        showConfigurations.shipDatesType = [NilUtil objectOrEmptyString:[json objectForKey:@"shipDatesType"]];

        if (![[NSNull null] isEqual:[json objectForKey:@"orderShipDates"]]) {
            showConfigurations.orderShipDates = [DateRange createInstanceFromJson:[NSArray arrayWithArray:[json mutableArrayValueForKey:@"orderShipDates"]]];
        } else {
            showConfigurations.orderShipDates = [DateRange createInstanceFromJson:@[]];
        }

        showConfigurations.customFields = Underscore.array([json objectForKey:@"customFieldInfos"]).map(^id(NSDictionary *json) {
            return [[ShowCustomField alloc] init:json];
        }).unwrap;
        showConfigurations.vendorMode = [[NilUtil objectOrEmptyString:[json objectForKey:@"customerType"]] isEqualToString:@"vendor"];
    }
}

+ (UIImage *)imageFromUrl:(NSString *)url defaultImage:(NSString *)imageName {
    UIImage *image = nil;
    if (![url isKindOfClass:[NSNull class]] && [url length] > 0) {
        @try {
            NSURL *imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", kBASEURL, url]];
            NSData *imageData = [NSData dataWithContentsOfURL:imageURL];
            image = [UIImage imageWithData:imageData];
        }
        @catch (NSException *e) {
            NSLog(@"Could Not Load Image: %@. Exception: %@", url, e);

        }
    }
    return image == nil? [UIImage imageNamed:imageName] : image;

}

- (bool)isOrderShipDatesType {
    return self.shipDates && [self.shipDatesType isEqualToString:@"order"];
}

- (bool)isLineItemShipDatesType {
    return self.shipDates && [self.shipDatesType isEqualToString:@"lineitem"];
}

- (NSArray *)orderCustomFields {
    return Underscore.array(self.customFields).filter(^BOOL(ShowCustomField *field) {
        return [field.ownerType isEqualToString:@"Order"];
    }).unwrap;
}

- (NSString *)price1Label {
    if (self.atOncePricing) {
        return @"At Once";
    } else {
        return @"Show";
    }
}

- (NSString *)price2Label {
    if (self.atOncePricing) {
        return @"Future";
    } else {
        return @"Regular";
    }
}
@end