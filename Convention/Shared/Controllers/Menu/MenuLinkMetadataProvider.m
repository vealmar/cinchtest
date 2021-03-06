//
// Created by David Jafari on 12/14/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <Underscore.m/Underscore.h>
#import "MenuLinkMetadataProvider.h"
#import "ThemeUtil.h"
#import "SettingsManager.h"
#import "CoreDataManager.h"
#import "NotificationConstants.h"
#import "CurrentSession.h"
#import "Configurations.h"

@implementation MenuLinkMetadata

-(NSURL *)url {
    NSString *baseUrl = [[SettingsManager sharedManager] getServerUrl];
    return [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", baseUrl, self.relativeUrl]];
}

@end

@interface MenuLinkMetadataProvider()

@property NSArray* metadatas;

@end

@implementation MenuLinkMetadataProvider

static MenuLinkMetadataProvider *provider = nil;

- (id)init {
    self = [super init];
    if (self) {
        NSMutableArray *builder = [NSMutableArray array];

        MenuLinkMetadata *m;

        m = [MenuLinkMetadata new];
        m.menuLink = MenuLinkOrderWriter;
        m.iconCharacter = @"\ue145";
        m.menuTitle = [ThemeUtil titleTextWithFontSize:16 format:@"%s", @"Order Writer", nil];
        [builder addObject:m];

        m = [MenuLinkMetadata new];
        m.menuLink = MenuLinkChangeShow;
        m.iconCharacter = @"\ue010"; //todo sg change icon?
        m.menuTitle = [ThemeUtil titleTextWithFontSize:16 format:@"%s", @"Change Sales Period", nil];
        [builder addObject:m];

        m = [MenuLinkMetadata new];
        m.menuLink = MenuLinkChangeVendor;
        m.iconCharacter = @"\ue010";
        m.menuTitle = [ThemeUtil titleTextWithFontSize:16 format:@"%s", @"Change Vendor", nil];
        [builder addObject:m];

        m = [MenuLinkMetadata new];
        m.menuLink = MenuLinkProducts;
        m.iconCharacter = @"\ue203";
        m.menuTitle = [ThemeUtil titleTextWithFontSize:16 format:@"%s %l", self.productCount, @"Products", nil];
        m.viewTitle = [ThemeUtil titleTextWithFontSize:18 format:@"%s", @"Products", nil];
        m.relativeUrl = @"/products";
        [builder addObject:m];

        m = [MenuLinkMetadata new];
        m.menuLink = MenuLinkCustomers;
        m.iconCharacter = @"\ue453";
        m.menuTitle = [ThemeUtil titleTextWithFontSize:16 format:@"%s %l", self.customerCount, @"Customers", nil];
        m.viewTitle = [ThemeUtil titleTextWithFontSize:18 format:@"%s", @"Customers", nil];
        m.relativeUrl = @"/customers";
        [builder addObject:m];

        m = [MenuLinkMetadata new];
        m.menuLink = MenuLinkDiscountGuide;
        m.iconCharacter = @"\ue459";
        m.menuTitle = [ThemeUtil titleTextWithFontSize:16 format:@"%l", @"Discount Guide", nil];
        m.viewTitle = [ThemeUtil titleTextWithFontSize:18 format:@"%s", @"Discount Guide", nil];
        m.relativeUrl = @"/discount_descriptions";
        [builder addObject:m];

        m = [MenuLinkMetadata new];
        m.menuLink = MenuLinkReportSalesByBrand;
        m.iconCharacter = @"\ue063";
        m.menuTitle = [ThemeUtil titleTextWithFontSize:16 format:@"%l %s", @"Sales by", @"Brand", nil];
        m.viewTitle = [ThemeUtil titleTextWithFontSize:18 format:@"%s %b", @"Sales by", @"Brand", nil];
        m.relativeUrl = @"/reports/bulletin_sales";
        [builder addObject:m];

        m = [MenuLinkMetadata new];
        m.menuLink = MenuLinkReportSalesByProduct;
        m.iconCharacter = @"\ue453";
        m.menuTitle = [ThemeUtil titleTextWithFontSize:16 format:@"%l %s", @"Sales by", @"Product", nil];
        m.viewTitle = [ThemeUtil titleTextWithFontSize:18 format:@"%s %b", @"Sales by", @"Product", nil];
        m.relativeUrl = @"/reports/product_sales";
        [builder addObject:m];

        m = [MenuLinkMetadata new];
        m.menuLink = MenuLinkReportSalesByCustomer;
        m.iconCharacter = @"\ue203";
        m.menuTitle = [ThemeUtil titleTextWithFontSize:16 format:@"%l %s", @"Sales by", @"Customer", nil];
        m.viewTitle = [ThemeUtil titleTextWithFontSize:18 format:@"%l %s", @"Sales by", @"Customer", nil];
        m.relativeUrl = @"/reports/customer_sales";
        [builder addObject:m];

        m = [MenuLinkMetadata new];
        m.menuLink = MenuLinkHelp;
        m.viewTitle = [ThemeUtil titleTextWithFontSize:18 format:@"%s %b", @"Order Writer", @"Help", nil];
        m.relativeUrl = [self helpUrl];
        [builder addObject:m];

        self.metadatas = [NSArray arrayWithArray:builder];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSessionDidChange:) name:SessionDidChangeNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (MenuLinkMetadataProvider *)instance {
    if (nil == provider) {
        provider = [MenuLinkMetadataProvider new];
    }
    return provider;
}

- (MenuLinkMetadata *)metadataFor:(MenuLink)menuLink {
    return Underscore.array(self.metadatas).find(^BOOL(MenuLinkMetadata *metadata) {
        return metadata.menuLink == menuLink;
    });
}

- (NSString *)productCount {
    return [self formatInlineNumber:[CoreDataManager getProductCount]];
}

- (NSString *)customerCount {
    return [self formatInlineNumber:[CoreDataManager getCustomerCount]];
}

-(NSString *)formatInlineNumber:(int)number {
    if (number >= 1000) {
        return [NSString stringWithFormat:@"%@.%@k", @((int)(number / 1000)), @((int)((number % 1000) / 100))];
    } else {
        return [@(number) stringValue];
    }
}

- (void)updateCustomerMetadata:(NSNotification *)notification {
    MenuLinkMetadata *m = [self metadataFor:MenuLinkCustomers];
    m.menuTitle = [ThemeUtil titleTextWithFontSize:16 format:@"%s %l", self.customerCount, @"Customers", nil];
}

- (void)updateProductMetadata:(NSNotification *)notification {
    MenuLinkMetadata *m = [self metadataFor:MenuLinkProducts];
    m.menuTitle = [ThemeUtil titleTextWithFontSize:16 format:@"%s %l", self.productCount, @"Products", nil];
}

- (void)handleSessionDidChange:(NSNotification *)notification {
    MenuLinkMetadata *m2 = [self metadataFor:MenuLinkHelp];
    m2.relativeUrl = [self helpUrl];
}

- (NSString *)helpUrl {
    return [Configurations instance].vendorMode ? @"/pages/help/vendor" : @"/pages/help/host";
}

@end