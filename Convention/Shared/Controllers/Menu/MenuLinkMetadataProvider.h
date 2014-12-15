//
// Created by David Jafari on 12/14/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    MenuLinkOrderWriter,
    MenuLinkProducts,
    MenuLinkCustomers,
    MenuLinkReportSalesByBrand,
    MenuLinkReportSalesByProduct,
    MenuLinkReportSalesByCustomer,
    MenuLinkHelp
} MenuLink;


@interface MenuLinkMetadata : NSObject

@property NSAttributedString *viewTitle;
@property NSAttributedString *menuTitle;
@property NSString *iconCharacter;
@property MenuLink menuLink;
@property NSString *relativeUrl;
@property (readonly) NSURL *url;

@end

@interface MenuLinkMetadataProvider : NSObject

+ (MenuLinkMetadataProvider *)instance;
- (MenuLinkMetadata *)metadataFor:(MenuLink)menuLink;

@end