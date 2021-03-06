//
// Created by septerr on 8/11/13.
// Copyright (c) 2013 MotionMobs. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Underscore.m/Underscore.h>
#import "Configurations.h"
#import "SettingsManager.h"
#import "NilUtil.h"
#import "DateRange.h"
#import "ShowCustomField.h"

static Configurations *showConfigurations = nil;

@interface Configurations ()

@property NSString *pricingStrategy;
@property NSArray *pricingTiers;
@property NSString *pricingTierDefault;

@end

@implementation Configurations

+ (Configurations *)instance {
    if (nil == showConfigurations) [NSException raise:NSGenericException format:@"Configuration object has not been created."];
    return showConfigurations;
}

+ (void)createInstanceFromJson:(NSDictionary *)json {
    showConfigurations = (Configurations *) [[[self class] alloc] init];
    if (showConfigurations) {
        [Configurations overrideWith:json];
    }
}

+ (void) overrideWith:(NSDictionary *)json{
    showConfigurations.pricingTierDefault = json[@"pricingTierDefault"];
    showConfigurations.pricingTiers = json[@"pricingTiers"];
    showConfigurations.pricingStrategy = json[@"pricingStrategy"];
    showConfigurations.enableOrderAuthorizedBy = [json[@"enableOrderAuthorizedBy"] boolValue];
    showConfigurations.enableOrderNotes = [json[@"enableOrderNotes"] boolValue];
    showConfigurations.productEnableManufacturerNo = [json[@"productEnableManufacturerNo"] boolValue];
    showConfigurations.discounts = [json[@"discounts"] boolValue];
    showConfigurations.discountsGuide = [json[@"discountsGuide"] boolValue];
    NSString *shipDatesValue = [NilUtil objectOrEmptyString:json[@"shipDates"]];
    showConfigurations.shipDates = [shipDatesValue isEqualToString:@"required"] || [shipDatesValue isEqualToString:@"optional"];
    showConfigurations.shipDatesRequired = [shipDatesValue isEqualToString:@"required"];
    showConfigurations.vouchers = [json[@"vouchers"] boolValue];
    showConfigurations.contactBeforeShipping = [json[@"contactBeforeShipping"] boolValue];
    showConfigurations.cancelOrder = [json[@"cancelOrder"] boolValue];
    showConfigurations.captureSignature = [json[@"signatureCapture"] boolValue];
    NSString *loginScreenUrl = ((NSString *) json[@"iosLoginScreen"]);
    showConfigurations.loginScreen = [Configurations imageFromUrl:loginScreenUrl defaultImage:@"launch_bg"];
    NSString *logoUrl = ((NSString *) json[@"iosLogo"]);
    showConfigurations.logo = [Configurations imageFromUrl:logoUrl defaultImage:@"cinch-c"];
    showConfigurations.poNumber = [json[@"poNumber"] boolValue];
    showConfigurations.paymentTerms = [json[@"paymentTerms"] boolValue];
    showConfigurations.shipDatesType = [NilUtil objectOrEmptyString:json[@"shipDatesType"]];

    if (![[NSNull null] isEqual:json[@"orderShipDates"]]) {
        showConfigurations.orderShipDates = [DateRange createInstanceFromJson:[NSArray arrayWithArray:[json mutableArrayValueForKey:@"orderShipDates"]]];
    } else {
        showConfigurations.orderShipDates = [DateRange createInstanceFromJson:@[]];
    }

    showConfigurations.customFields = Underscore.array(json[@"customFieldInfos"]).map(^id(NSDictionary *dictionary) {
        return [[ShowCustomField alloc] init:dictionary];
    }).unwrap;
    showConfigurations.vendorMode = [[NilUtil objectOrEmptyString:json[@"customerType"]] isEqualToString:@"vendor"];
}

+ (UIImage *)imageFromUrl:(NSString *)url defaultImage:(NSString *)imageName {
    UIImage *image = nil;
    if (![url isKindOfClass:[NSNull class]] && [url length] > 0) {
        @try {
            NSURL *imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", [[SettingsManager sharedManager] getServerUrl], url]];
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
    if (self.isAtOncePricing) {
        return @"At Once";
    } else if (self.isTieredPricing) {
        return @"Current";
    } else {
        return @"Show";
    }
}

- (NSString *)price2Label {
    if (self.isAtOncePricing) {
        return @"Future";
    } else if (self.isTieredPricing) {
        return @"Base Tier";
    } else {
        return @"Regular";
    }
}

- (BOOL)isShowPricing {
    return [@"Show Pricing" isEqualToString:self.pricingStrategy];
}

- (BOOL)isAtOncePricing {
    return [@"At Once Pricing" isEqualToString:self.pricingStrategy];
}

- (BOOL)isTieredPricing {
    return [@"Tiered Pricing" isEqualToString:self.pricingStrategy];
}

- (int)priceTiersAvailable {
    if ([self isShowPricing]) return 2;
    else if ([self isAtOncePricing]) return 2;
    else if ([self isTieredPricing]) return self.pricingTiers.count;
    else return 0;
}

- (int)defaultPriceTierIndex {
    if ([self isTieredPricing] && self.pricingTierDefault && [self.pricingTiers containsObject:self.pricingTierDefault]) {
        return [self.pricingTiers indexOfObject:self.pricingTierDefault];
    } else {
        return 0;
    }
}

- (NSString *)priceTierLabelAt:(int)index {
    if ([self isShowPricing]) {
        switch(index) {
            case 0: return @"Show";
            case 1: return @"Regular";
            default: return nil;
        }
    } else if ([self isAtOncePricing]) {
        switch(index) {
            case 0: return @"At Once";
            case 1: return @"Future";
            default: return nil;
        }
    } else if ([self isTieredPricing]) {
        return self.pricingTiers[(NSUInteger) index];
    } else {
        return nil;
    }
    return nil;
}

@end