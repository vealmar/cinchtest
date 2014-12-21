//
// Created by David Jafari on 12/20/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CITableViewColumns;

@interface CITableViewHeader : UIView

-(id)prepareForDisplay:(CITableViewColumns *)columns;

@end