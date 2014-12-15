//
// Created by David Jafari on 12/14/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MenuLinkMetadataProvider.h"

@interface MenuViewCell : UITableViewCell

@property MenuLink menuLink;

-(void)prepareForDisplay:(MenuLink)menuLink;

@end