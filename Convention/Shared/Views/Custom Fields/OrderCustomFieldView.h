//
// Created by David Jafari on 6/29/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ShowCustomField;

@protocol OrderCustomFieldView <NSObject>

@required

-(ShowCustomField *)showCustomField;
-(NSString *)value;
-(void)value:(NSString *)value;

@end